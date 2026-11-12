import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/settings/presentation/settings_provider.dart';
import '../../features/timer/presentation/timer_provider.dart';
import '../desktop/desktop_providers.dart';
import 'timer_update_handoff.dart';
import 'update_service.dart';

const updateRestartWaitScript =
    r'n=0; while kill -0 "$1" 2>/dev/null; do n=$((n+1)); [ "$n" -lt 150 ] || exit 1; sleep 0.2; done; exec "$2"';

class UpdateRestartCoordinator {
  final bool Function() canRestart;
  final Future<void> Function() restart;
  Timer? _timer;
  Completer<void>? _pending;
  bool _restarting = false;
  bool _disposed = false;
  UpdateRestartCoordinator({required this.canRestart, required this.restart});

  Future<void> request({required void Function() onRestart}) {
    if (_disposed) return Future.value();
    if (_pending != null) return _pending!.future;
    _pending = Completer<void>();
    Future<void> attempt() async {
      if (_disposed || _restarting || !canRestart()) return;
      _restarting = true;
      _timer?.cancel();
      try {
        onRestart();
        await restart();
        if (!(_pending?.isCompleted ?? true)) _pending!.complete();
      } catch (error, stack) {
        if (!(_pending?.isCompleted ?? true)) {
          _pending!.completeError(error, stack);
        }
        _pending = null;
        _restarting = false;
      }
    }

    // Register the timer first: an immediate restart must cancel it too.
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => attempt());
    final result = _pending!.future;
    attempt();
    return result;
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    if (!(_pending?.isCompleted ?? true)) _pending!.complete();
  }
}

final updateRestartCoordinatorProvider = Provider<UpdateRestartCoordinator>((
  ref,
) {
  final coordinator = UpdateRestartCoordinator(
    canRestart: () =>
        ref.read(pomodoroNotifierProvider.notifier).canRestartForUpdate,
    restart: () async {
      if (!await File('/usr/bin/pomodoro-focus').exists()) {
        throw const UpdateException(UpdateFailure.restart);
      }
      final timer = ref.read(pomodoroNotifierProvider.notifier);
      final prefs = ref.read(sharedPreferencesProvider);
      Process? helper;
      try {
        final snapshot = timer.freezeForUpdateRestart();
        await TimerUpdateHandoff.save(prefs, snapshot, DateTime.now());
        // Wait for the old GApplication instance to exit before launching its replacement.
        helper = await Process.start('/bin/sh', [
          '-c',
          updateRestartWaitScript,
          'pomodoro-restart',
          pid.toString(),
          '/usr/bin/pomodoro-focus',
        ], mode: ProcessStartMode.detached);
        await ref.read(desktopWindowServiceProvider).quit();
      } catch (_) {
        helper?.kill();
        await prefs.remove(TimerUpdateHandoff.key);
        timer.cancelUpdateRestart();
        rethrow;
      }
    },
  );
  ref.onDispose(coordinator.dispose);
  return coordinator;
});
