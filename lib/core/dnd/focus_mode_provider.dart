import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'android_focus_mode_controller.dart';
import 'focus_mode_controller.dart';
import 'linux_kde_focus_mode_controller.dart';
import 'unsupported_focus_mode_controller.dart';

final focusModeControllerProvider = Provider<FocusModeController>((ref) {
  final FocusModeController controller;

  if (!kIsWeb && Platform.isLinux) {
    controller = LinuxKdeFocusModeController();
  } else if (!kIsWeb && Platform.isAndroid) {
    controller = AndroidFocusModeController();
  } else {
    controller = UnsupportedFocusModeController();
  }

  ref.onDispose(() => controller.dispose());
  return controller;
});

