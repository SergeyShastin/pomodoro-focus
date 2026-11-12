import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro_focus/core/desktop/tray_service.dart';
import 'package:pomodoro_focus/features/timer/domain/pomodoro_timer_state.dart';
import 'package:tray_manager/tray_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('tray_manager');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'setToolTip') throw MissingPluginException();
      return true;
    });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('Linux startup race still installs menu and uses supported label',
      () async {
    var starts = 0;
    var pauses = 0;
    var skips = 0;
    var resets = 0;
    final service = TrayService(
      onStart: () => starts++,
      onPause: () => pauses++,
      onSkip: () => skips++,
      onReset: () => resets++,
    );
    addTearDown(service.dispose);
    final initialization = service.initialize();
    await service.updateTray(const PomodoroTimerState());
    await initialization;
    expect(calls.map((call) => call.method),
        ['setIcon', 'setTitle', 'setContextMenu']);
    expect(calls[1].arguments['title'], 'Focus: 25:00');
    final items = calls.last.arguments['menu']['items'] as List;
    expect(items.any((dynamic item) => item['key'] == 'show_window'), isTrue);
    service.onTrayMenuItemClick(MenuItem(key: 'toggle_play'));
    expect(starts, 1);
    await service.updateTray(const PomodoroTimerState(isRunning: true));
    service.onTrayMenuItemClick(MenuItem(key: 'toggle_play'));
    service.onTrayMenuItemClick(MenuItem(key: 'skip'));
    service.onTrayMenuItemClick(MenuItem(key: 'reset'));
    expect([pauses, skips, resets], [1, 1, 1]);
  });
}
