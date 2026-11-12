import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro_focus/core/dnd/linux_kde_focus_mode_controller.dart';
import 'package:pomodoro_focus/core/dnd/unsupported_focus_mode_controller.dart';

void main() {
  test('UnsupportedFocusModeController reports isSupported false', () async {
    final controller = UnsupportedFocusModeController();
    expect(controller.isSupported, false);
    expect(await controller.hasPermission(), false);
    expect(await controller.requestPermission(), false);

    // Calling enable/disable/dispose does not throw
    await controller.enable();
    await controller.disable();
    await controller.dispose();
  });

  test('LinuxKdeFocusModeController reports isSupported and hasPermission true', () async {
    final controller = LinuxKdeFocusModeController();
    expect(controller.isSupported, true);
    expect(await controller.hasPermission(), true);
    expect(await controller.requestPermission(), true);

    // Dispose cleans up safely
    await controller.dispose();
  });
}

