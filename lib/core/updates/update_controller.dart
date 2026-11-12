import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/settings/presentation/settings_provider.dart';
import 'update_service.dart';
import 'packagekit_installer.dart';
import 'update_restart.dart';

enum UpdatePhase {
  idle,
  checking,
  available,
  current,
  downloading,
  installing,
  waitingRestart,
  restarting,
  failed,
}

class UpdateState {
  final UpdatePhase phase;
  final ReleaseUpdate? release;
  final double progress;
  final UpdateFailure? failure;
  final String? installedVersion;
  const UpdateState({
    this.phase = UpdatePhase.idle,
    this.release,
    this.progress = 0,
    this.failure,
    this.installedVersion,
  });
}

class UpdateController extends StateNotifier<UpdateState> {
  final UpdateBackend backend;
  final SharedPreferences prefs;
  final Future<void> Function(void Function() onRestart) afterInstalled;
  Timer? _timer;
  bool _automatic = false;
  File? _downloaded;
  UpdateController(
    this.backend,
    this.prefs, {
    Future<void> Function(void Function())? afterInstalled,
  }) : afterInstalled =
           afterInstalled ??
           ((onRestart) async {
             onRestart();
           }),
       super(const UpdateState());
  bool get busy =>
      state.phase == UpdatePhase.checking ||
      state.phase == UpdatePhase.downloading ||
      state.phase == UpdatePhase.installing ||
      state.phase == UpdatePhase.waitingRestart ||
      state.phase == UpdatePhase.restarting;

  void configure(bool automatic) {
    _automatic = automatic;
    _timer?.cancel();
    if (!automatic) return;
    final last = prefs.getInt('update_last_attempt') ?? 0;
    final remaining = DateTime.fromMillisecondsSinceEpoch(
      last,
    ).add(const Duration(hours: 12)).difference(DateTime.now());
    final delay = remaining > Duration.zero
        ? remaining
        : const Duration(seconds: 10);
    _timer = Timer(
      delay > const Duration(hours: 12) ? const Duration(hours: 12) : delay,
      () async {
        if (_automatic) await check(automatic: true);
        if (mounted && _automatic) configure(true);
      },
    );
  }

  Future<void> check({bool automatic = false}) async {
    if (busy || (automatic && !_automatic)) return;
    if (automatic) {
      final last = prefs.getInt('update_last_attempt');
      if (last != null) {
        final elapsed = DateTime.now().difference(
          DateTime.fromMillisecondsSinceEpoch(last),
        );
        if (elapsed >= Duration.zero && elapsed < const Duration(hours: 12)) {
          return;
        }
      }
    }
    final previous = state;
    state = UpdateState(
      phase: UpdatePhase.checking,
      release: previous.release,
      installedVersion: previous.installedVersion,
    );
    try {
      await prefs.setInt(
        'update_last_attempt',
        DateTime.now().millisecondsSinceEpoch,
      );
      final version = await backend.currentVersion();
      final release = await backend.check(version);
      if (!mounted) return;
      if (automatic && !_automatic) {
        state = previous;
        return;
      }
      _downloaded = null;
      state = UpdateState(
        phase: release == null ? UpdatePhase.current : UpdatePhase.available,
        release: release,
        installedVersion: version,
      );
    } catch (error) {
      if (!mounted) return;
      if (automatic) {
        state = previous;
        return;
      }
      state = UpdateState(
        phase: UpdatePhase.failed,
        release: previous.release,
        installedVersion: previous.installedVersion,
        failure: error is UpdateException
            ? error.failure
            : UpdateFailure.network,
      );
    }
  }

  Future<void> install() async {
    final release = state.release;
    if (release == null || busy) return;
    final version = state.installedVersion;
    state = UpdateState(
      phase: UpdatePhase.downloading,
      release: release,
      installedVersion: version,
    );
    var opening = false;
    try {
      if (!await backend.isInstalled(release.version)) {
        _downloaded ??= await backend.download(release, (value) {
          if (mounted) {
            state = UpdateState(
              phase: UpdatePhase.downloading,
              release: release,
              progress: value,
              installedVersion: version,
            );
          }
        });
        if (!mounted) return;
        opening = true;
        state = UpdateState(
          phase: UpdatePhase.installing,
          release: release,
          installedVersion: version,
        );
        await backend.installPackage(_downloaded!);
        if (!await backend.isInstalled(release.version)) {
          throw const UpdateException(UpdateFailure.installation);
        }
      }
      if (!mounted) return;
      state = UpdateState(
        phase: UpdatePhase.waitingRestart,
        release: release,
        installedVersion: version,
      );
      try {
        await afterInstalled(() {
          if (mounted) {
            state = UpdateState(
              phase: UpdatePhase.restarting,
              release: release,
              installedVersion: version,
            );
          }
        });
      } catch (_) {
        throw const UpdateException(UpdateFailure.restart);
      }
    } catch (error) {
      if (mounted) {
        state = UpdateState(
          phase: UpdatePhase.failed,
          release: release,
          installedVersion: version,
          failure: error is UpdateException
              ? error.failure
              : (opening ? UpdateFailure.installation : UpdateFailure.network),
        );
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final updateBackendProvider = Provider<UpdateBackend>(
  (ref) => GithubUpdateService(
    version: () async => (await PackageInfo.fromPlatform()).version,
    supported: GithubUpdateService.supportsDebUpdates,
    install: (file) => PackageKitInstaller().install(file),
  ),
);

final runningVersionProvider = FutureProvider<String>(
  (ref) => ref.watch(updateBackendProvider).currentVersion(),
);

final updateControllerProvider =
    StateNotifierProvider<UpdateController, UpdateState>((ref) {
      final controller = UpdateController(
        ref.watch(updateBackendProvider),
        ref.watch(sharedPreferencesProvider),
        afterInstalled: (onRestart) => ref
            .read(updateRestartCoordinatorProvider)
            .request(onRestart: onRestart),
      );
      controller.configure(ref.read(settingsProvider).automaticUpdates);
      ref.listen(settingsProvider, (old, next) {
        if (old?.automaticUpdates != next.automaticUpdates) {
          controller.configure(next.automaticUpdates);
        }
      });
      return controller;
    });
