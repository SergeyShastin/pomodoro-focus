import 'package:flutter/services.dart';
import 'focus_mode_controller.dart';

class AndroidFocusModeController implements FocusModeController {
  static const MethodChannel _channel = MethodChannel('com.focus.pomodoro/dnd');

  @override
  bool get isSupported => true;

  @override
  Future<bool> hasPermission() async {
    try {
      final granted = await _channel.invokeMethod<bool>('hasPermission');
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      final res = await _channel.invokeMethod<bool>('requestPermission');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> enable() async {
    try {
      await _channel.invokeMethod('enable');
    } catch (_) {}
  }

  @override
  Future<void> disable() async {
    try {
      await _channel.invokeMethod('disable');
    } catch (_) {}
  }

  @override
  Future<void> dispose() async {
    await disable();
  }
}

