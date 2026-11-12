import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro_focus/core/desktop/window_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('window_manager');
  final calls = <MethodCall>[];
  setUp(() {
    calls.clear();
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'getBounds') {
        return {'x': 100.0, 'y': 120.0, 'width': 920.0, 'height': 700.0};
      }
      return null;
    });
  });
  tearDown(() => TestDefaultBinaryMessengerBinding
      .instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, null));

  test(
      'mini mode preserves normal bounds, hides frame and restores on expansion',
      () async {
    final prefs = await SharedPreferences.getInstance();
    final service = DesktopWindowService(prefs);
    expect(await service.toggleMiniMode(true), isTrue);
    await service.saveCurrentBounds();
    expect(prefs.getDouble('window_width'), isNull);
    expect(
        calls.any((c) =>
            c.method == 'setAlwaysOnTop' &&
            c.arguments['isAlwaysOnTop'] == true),
        isTrue);
    expect(await service.toggleMiniMode(false), isTrue);
    final bounds = calls.lastWhere((c) => c.method == 'setBounds').arguments;
    expect([bounds['x'], bounds['y'], bounds['width'], bounds['height']],
        [100.0, 120.0, 920.0, 700.0]);
    expect(service.isMiniMode, isFalse);
    await service.saveCurrentBounds();
    expect(prefs.getDouble('window_width'), 920);
  });

  test('close hides window by default; real exit awaits DND cleanup', () async {
    final prefs = await SharedPreferences.getInstance();
    final service = DesktopWindowService(prefs, beforeExit: () async {
      expect(calls.any((c) => c.method == 'destroy'), isFalse);
      calls.add(const MethodCall('cleanup'));
    });
    await service.onWindowClose();
    expect(calls.single.method, 'hide');
    service.setMinimizeToTrayOnClose(false);
    await service.onWindowClose();
    expect(calls.map((c) => c.method),
        ['hide', 'cleanup', 'getBounds', 'destroy']);
  });
}
