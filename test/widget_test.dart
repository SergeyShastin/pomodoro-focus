import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro_focus/app.dart';
import 'package:pomodoro_focus/l10n/app_localizations.dart';
import 'package:pomodoro_focus/core/desktop/linux_screen_power_service.dart';
import 'package:pomodoro_focus/features/settings/presentation/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App skeleton smoke test: verifies navigation bar and tabs',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'locale_code': 'ru'});
    tester.platformDispatcher.localeTestValue = const Locale('ru');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    final prefs = await SharedPreferences.getInstance();

    tester.view.physicalSize = const Size(400, 800);
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

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.locale, const Locale('en'));
    expect(AppLocalizations.supportedLocales, [const Locale('en')]);

    // Verify initial tab is Timer
    expect(find.byIcon(Icons.timer), findsOneWidget);
    expect(find.byIcon(Icons.public_outlined), findsOneWidget);
    expect(find.byIcon(Icons.bar_chart_outlined), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

    // Switch to Settings tab
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Check that settings screen is visible
    expect(find.byType(Card), findsWidgets);
    expect(find.text('Settings'), findsWidgets);
    expect(find.text('Language'), findsNothing);
    expect(find.byType(DropdownButton<String>), findsNothing);
  });
}
