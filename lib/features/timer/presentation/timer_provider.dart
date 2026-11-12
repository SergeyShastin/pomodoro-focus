import '../../../core/updates/timer_update_handoff.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/clock/app_clock.dart';
import '../../../core/desktop/desktop_providers.dart';
import '../../../core/desktop/tray_service.dart';
import '../../../core/desktop/linux_screen_power_service.dart';
import '../../../core/dnd/focus_mode_controller.dart';
import '../../../core/dnd/focus_mode_provider.dart';
import '../../../core/notifications/notification_service.dart';
import '../../settings/presentation/settings_provider.dart';
import '../../stats/presentation/stats_provider.dart';
import '../domain/pomodoro_engine.dart';
import '../domain/pomodoro_timer_state.dart';

final clockProvider = Provider<AppClock>((ref) => const SystemClock());

class TimerNotifier extends StateNotifier<PomodoroTimerState> {
  final PomodoroEngine _engine;
  final TrayService _trayService;
  final FocusModeController _dndController;
  final bool Function() _isDndEnabled;
  final bool Function()? _completionPending;
  bool? _focusActive;
  bool _restartFrozen = false;
  bool _historyWriteFailed = false;
  Timer? _ticker;

  TimerNotifier(
    this._engine,
    this._trayService,
    this._dndController,
    this._isDndEnabled, {
    bool Function()? completionPending,
  }) : _completionPending = completionPending,
       super(_engine.state) {
    _trayService
      ..onStart = start
      ..onPause = pause
      ..onSkip = skip
      ..onReset = reset;
    _syncTicker();
    _trayService.updateTray(state);
    synchronizeFocus();
  }

  void _syncTicker() {
    _ticker?.cancel();
    if (_restartFrozen) return;
    if (state.isRunning) {
      _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
        final previousPhase = state.phase;
        _engine.tick();
        state = _engine.state;
        _trayService.updateTray(state);
        if (!state.isRunning) {
          _ticker?.cancel();
        }
        if (!state.isRunning || state.phase != previousPhase) {
          synchronizeFocus();
        }
      });
    }
  }

  void start() {
    if (_restartFrozen) return;
    _engine.start();
    state = _engine.state;
    _syncTicker();
    _trayService.updateTray(state);

    synchronizeFocus();
  }

  void pause() {
    if (_restartFrozen) return;
    _engine.pause();
    state = _engine.state;
    _syncTicker();
    _trayService.updateTray(state);
    synchronizeFocus();
  }

  void skip() {
    if (_restartFrozen) return;
    _engine.skip();
    state = _engine.state;
    _syncTicker();
    _trayService.updateTray(state);
    synchronizeFocus();
  }

  void reset() {
    if (_restartFrozen) return;
    _engine.reset();
    state = _engine.state;
    _syncTicker();
    _trayService.updateTray(state);
    synchronizeFocus();
  }

  void setTaskName(String name) {
    if (_restartFrozen) return;
    _engine.setTaskName(name);
    state = _engine.state;
  }

  void onSettingsUpdated() {
    state = _engine.state;
    _syncTicker();
    _trayService.updateTray(state);
    synchronizeFocus();
  }

  void synchronizeFocus() {
    if (!mounted || (_completionPending?.call() ?? false)) return;
    final desired = state.isRunning && state.phase.isWork && _isDndEnabled();
    if (_focusActive == desired) return;
    _focusActive = desired;
    if (desired) {
      _dndController.enable();
    } else {
      _dndController.disable();
    }
  }

  bool get canRestartForUpdate =>
      mounted &&
      !_restartFrozen &&
      !_historyWriteFailed &&
      !(_completionPending?.call() ?? false) &&
      TimerUpdateHandoff.isSafe(state);

  PomodoroTimerState freezeForUpdateRestart() {
    if (!canRestartForUpdate) {
      throw StateError('Focus or history write in progress');
    }
    _restartFrozen = true;
    _ticker?.cancel();
    return state;
  }

  void cancelUpdateRestart() {
    _restartFrozen = false;
    _syncTicker();
    synchronizeFocus();
  }

  void blockUpdateRestartForHistoryError() {
    _historyWriteFailed = true;
  }

  bool get isOnBreak => mounted && state.phase.isBreak;
  bool get isInWorkPhase => mounted && state.phase.isWork;

  void completionFinished() {
    // Completion explicitly releases the inhibitor before notifying the user.
    _focusActive = false;
    synchronizeFocus();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _trayService
      ..onStart = null
      ..onPause = null
      ..onSkip = null
      ..onReset = null;
    _dndController.disable();
    super.dispose();
  }
}

final pomodoroNotifierProvider = StateNotifierProvider<TimerNotifier, PomodoroTimerState>((
  ref,
) {
  final clock = ref.watch(clockProvider);
  final settings = ref.read(settingsProvider);
  final audioService = ref.watch(audioServiceProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  final statsRepo = ref.watch(statsRepositoryProvider);
  final trayService = ref.watch(trayServiceProvider);
  final dndController = ref.watch(focusModeControllerProvider);
  final screenPower = ref.watch(linuxScreenPowerServiceProvider);

  var pendingCompletions = 0;
  var screenTurnedOffForBreak = false;
  Future<void> completionEffects = Future.value();
  late final TimerNotifier notifier;

  final engine = PomodoroEngine(
    clock: clock,
    settings: settings,
    initialState: TimerUpdateHandoff.take(
      ref.read(sharedPreferencesProvider),
      clock.now(),
    ),
    onSessionCompleted:
        ({
          required phase,
          required startTime,
          required endTime,
          required duration,
          required taskName,
        }) {
          pendingCompletions++;
          final settings = ref.read(settingsProvider);

          completionEffects = completionEffects.then((_) async {
            try {
              await dndController.disable();

              // Wake before the completion alert, including when the next work
              // session waits for a manual start. Do not replay old wake requests.
              if (phase.isBreak &&
                  pendingCompletions == 1 &&
                  notifier.isInWorkPhase &&
                  (screenTurnedOffForBreak || settings.turnOffScreenOnBreak)) {
                try {
                  await screenPower.turnOn();
                  screenTurnedOffForBreak = false;
                } catch (error) {
                  debugPrint('Display wake request failed: $error');
                }
              }

              if (phase.isWork) {
                try {
                  await statsRepo.recordSession(
                    phase: phase,
                    startTime: startTime,
                    endTime: endTime,
                    duration: duration,
                    taskName: taskName,
                  );
                } catch (_) {
                  notifier.blockUpdateRestartForHistoryError();
                  rethrow;
                }
              }

              if (settings.enableSound) {
                await audioService.playCompletionSound();
              }
              if (settings.enableNotifications) {
                final title = phase.isWork
                    ? 'Focus session completed!'
                    : 'Break completed!';
                final body = phase.isWork
                    ? (taskName.isNotEmpty
                          ? 'Task: $taskName. Great job!'
                          : 'Great job! Time for a break.')
                    : 'Time to get back to focus.';

                await notificationService.showNotification(
                  title: title,
                  body: body,
                );
              }
            } catch (error, stack) {
              debugPrint('Session completion failed: $error\n$stack');
            } finally {
              try {
                // Ignore old completions replayed after sleep, or a break already skipped.
                // This is one request per completed pomodoro, never a repeating blackout.
                if (phase.isWork &&
                    pendingCompletions == 1 &&
                    notifier.isOnBreak &&
                    ref.read(settingsProvider).turnOffScreenOnBreak) {
                  await screenPower.turnOff();
                  screenTurnedOffForBreak = true;
                }
              } catch (error) {
                debugPrint('Display power request failed: $error');
              }
              pendingCompletions--;
              notifier.completionFinished();
            }
          });
        },
  );

  notifier = TimerNotifier(
    engine,
    trayService,
    dndController,
    () => ref.read(settingsProvider).enableDndDuringWork,
    completionPending: () => pendingCompletions > 0,
  );

  ref.listen(settingsProvider, (_, newSettings) {
    engine.updateSettings(newSettings);
    notifier.onSettingsUpdated();
  });

  return notifier;
});
