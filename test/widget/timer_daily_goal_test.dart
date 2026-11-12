import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro_focus/core/theme/app_theme.dart';
import 'package:pomodoro_focus/features/settings/presentation/settings_provider.dart';
import 'package:pomodoro_focus/features/stats/domain/focus_stats.dart';
import 'package:pomodoro_focus/features/stats/presentation/stats_provider.dart';
import 'package:pomodoro_focus/features/timer/presentation/widgets/timer_daily_goal_card.dart';
import 'package:pomodoro_focus/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

FocusStatsSummary summary(int count) => FocusStatsSummary(
    todayPomodoros: count,
    todayMinutes: count * 25,
    weekPomodoros: count,
    weekMinutes: count * 25,
    last7Days: const []);

void main() {
  testWidgets(
      'timer daily goal shows committed earnings and updates remaining, completed and disabled states',
      (tester) async {
    tester.view.physicalSize = const Size(380, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final earned = StateProvider<int>((ref) => 5);
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      statsSummaryProvider
          .overrideWith((ref) async => summary(ref.watch(earned))),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme:
              AppTheme.light(null, AppTheme.defaultSeedColor, fontScale: 1.5),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: Center(child: TimerDailyGoalCard())),
        )));
    await tester.pumpAndSettle();
    expect(find.text('5 of 8 pomodoros'), findsOneWidget);
    expect(find.text('3 to go'), findsOneWidget);
    expect(
        tester
            .widget<LinearProgressIndicator>(
                find.byType(LinearProgressIndicator))
            .value,
        0.625);
    container.read(earned.notifier).state = 6;
    await tester.pumpAndSettle();
    expect(find.text('6 of 8 pomodoros'), findsOneWidget);
    expect(find.text('2 to go'), findsOneWidget);
    await container.read(settingsProvider.notifier).setDailyGoal(6);
    await tester.pumpAndSettle();
    expect(find.text('Goal reached'), findsOneWidget);
    await container.read(settingsProvider.notifier).setDailyGoal(4);
    await tester.pumpAndSettle();
    expect(find.text('+2 beyond your goal'), findsOneWidget);
    expect(
        tester
            .widget<LinearProgressIndicator>(
                find.byType(LinearProgressIndicator))
            .value,
        1);
    await container.read(settingsProvider.notifier).setDailyGoal(0);
    await tester.pumpAndSettle();
    expect(find.text('6 pomodoros'), findsOneWidget);
    expect(find.text('Goal is off'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
