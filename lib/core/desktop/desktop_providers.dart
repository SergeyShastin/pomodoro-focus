import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/settings/presentation/settings_provider.dart';
import 'tray_service.dart';
import 'window_service.dart';
import '../dnd/focus_mode_provider.dart';

final Provider<DesktopWindowService> desktopWindowServiceProvider =
    Provider<DesktopWindowService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final service = DesktopWindowService(prefs, beforeExit: () async {
    await ref.read(focusModeControllerProvider).dispose();
    await ref.read(trayServiceProvider).destroy();
  });
  service.initialize(
    minimizeToTrayOnClose: ref.read(settingsProvider).minimizeToTrayOnClose,
  );
  ref.listen(settingsProvider, (_, settings) {
    service.setMinimizeToTrayOnClose(settings.minimizeToTrayOnClose);
  });
  ref.onDispose(() => service.dispose());
  return service;
});

final isMiniModeProvider = StateProvider<bool>((ref) => false);

final Provider<TrayService> trayServiceProvider = Provider<TrayService>((ref) {
  final service = TrayService(
    onQuit: () => ref.read(desktopWindowServiceProvider).quit(),
  );
  service.initialize();
  ref.onDispose(() => service.dispose());
  return service;
});
