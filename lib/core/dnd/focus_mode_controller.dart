abstract class FocusModeController {
  bool get isSupported;
  Future<bool> hasPermission();
  Future<bool> requestPermission();
  Future<void> enable();
  Future<void> disable();
  Future<void> dispose();
}

