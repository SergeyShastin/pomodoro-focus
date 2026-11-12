import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro_focus/features/stats/domain/focus_goal_progress.dart';
import 'package:pomodoro_focus/features/settings/data/settings_repository.dart';
import 'package:pomodoro_focus/features/settings/presentation/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'disabled, partial and exceeded goals keep earned totals and clamp progress',
      () {
    const off = FocusGoalProgress(completed: 5, target: 0);
    expect(off.enabled, isFalse);
    expect(off.fraction, 0);
    expect(off.achieved, isFalse);
    const partial = FocusGoalProgress(completed: 5, target: 8);
    expect(partial.fraction, 0.625);
    expect(partial.remaining, 3);
    expect(const FocusGoalProgress(completed: 23, target: 40).percent, 58);
    const exceeded = FocusGoalProgress(completed: 11, target: 8);
    expect(exceeded.achieved, isTrue);
    expect(exceeded.percent, 100);
    expect(exceeded.extra, 3);
    expect(exceeded.completed, 11);
  });

  test('goals and readable text defaults persist, including disabled goals',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = SettingsRepository(prefs);
    expect(repo.loadSettings().dailyGoalPomodoros, 8);
    expect(repo.loadSettings().weeklyGoalPomodoros, 40);
    expect(repo.loadSettings().fontScale, 1.2);
    final notifier = SettingsNotifier(repo);
    await notifier.setDailyGoal(0);
    await notifier.setWeeklyGoal(55);
    await notifier.setFontScale(1.4);
    final saved = SettingsRepository(prefs).loadSettings();
    expect(saved.dailyGoalPomodoros, 0);
    expect(saved.weeklyGoalPomodoros, 55);
    expect(saved.fontScale, 1.4);
    notifier.dispose();
  });

  test('invalid saved goals and font scale are bounded on load', () async {
    SharedPreferences.setMockInitialValues({
      'daily_goal_pomodoros': -10,
      'weekly_goal_pomodoros': 20000,
      'font_scale': 99.0
    });
    final repo = SettingsRepository(await SharedPreferences.getInstance());
    final settings = repo.loadSettings();
    expect(settings.dailyGoalPomodoros, 0);
    expect(settings.weeklyGoalPomodoros, 10080);
    expect(settings.fontScale, 1.5);
  });
}
