import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro_focus/app.dart';
import 'package:pomodoro_focus/core/desktop/linux_screen_power_service.dart';
import 'package:pomodoro_focus/features/settings/presentation/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
      'TimerScreen: start, pause, resume, skip and task input interactions',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'automatic_updates': false,
    });
    final prefs = await SharedPreferences.getInstance();

    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          screenPowerAvailableProvider.overrideWith((ref) async => true),
        ],
        child: const PomodoroApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify initial time is 25:00
    expect(find.text('25:00'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);

    // Tap play
    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify button switches to pause
    expect(find.byIcon(Icons.pause), findsOneWidget);

    // Tap pause
    await tester.tap(find.byIcon(Icons.pause));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify button switches back to play_arrow (Resume)
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);

    // Tap skip button
    await tester.tap(find.byIcon(Icons.skip_next));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify time is now 05:00 (Short break)
    expect(find.text('05:00'), findsOneWidget);

    // Enter task name
    await tester.enterText(find.byType(TextField), 'Writing Documentation');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Writing Documentation'), findsOneWidget);
  });
}
