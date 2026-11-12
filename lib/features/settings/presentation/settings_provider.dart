import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../data/settings_repository.dart';
import '../domain/settings_state.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsRepository(prefs);
});

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SettingsRepository _repository;

  SettingsNotifier(this._repository) : super(_repository.loadSettings());

  Future<void> updateSettings(
      SettingsState Function(SettingsState) update) async {
    final newState = update(state);
    state = newState;
    await _repository.saveSettings(newState);
  }

  Future<void> setThemeMode(AppThemeMode mode) =>
      updateSettings((s) => s.copyWith(themeMode: mode));

  Future<void> setUseDynamicColor(bool value) =>
      updateSettings((s) => s.copyWith(useDynamicColor: value));

  Future<void> setSeedColor(int colorValue) =>
      updateSettings((s) => s.copyWith(seedColorValue: colorValue));

  Future<void> setWorkDuration(int minutes) =>
      updateSettings((s) => s.copyWith(workDurationMinutes: minutes));

  Future<void> setShortBreakDuration(int minutes) =>
      updateSettings((s) => s.copyWith(shortBreakDurationMinutes: minutes));

  Future<void> setLongBreakDuration(int minutes) =>
      updateSettings((s) => s.copyWith(longBreakDurationMinutes: minutes));

  Future<void> setSessionsBeforeLongBreak(int count) =>
      updateSettings((s) => s.copyWith(sessionsBeforeLongBreak: count));

  Future<void> setAutoStartBreaks(bool value) =>
      updateSettings((s) => s.copyWith(autoStartBreaks: value));

  Future<void> setAutoStartPomodoros(bool value) =>
      updateSettings((s) => s.copyWith(autoStartPomodoros: value));

  Future<void> setEnableDnd(bool value) =>
      updateSettings((s) => s.copyWith(enableDndDuringWork: value));

  Future<void> setEnableNotifications(bool value) =>
      updateSettings((s) => s.copyWith(enableNotifications: value));

  Future<void> setMinimizeToTrayOnClose(bool value) =>
      updateSettings((s) => s.copyWith(minimizeToTrayOnClose: value));

  Future<void> setTurnOffScreenOnBreak(bool value) =>
      updateSettings((s) => s.copyWith(turnOffScreenOnBreak: value));

  Future<void> setDailyGoal(int value) => updateSettings(
      (s) => s.copyWith(dailyGoalPomodoros: value.clamp(0, 1440)));

  Future<void> setWeeklyGoal(int value) => updateSettings(
      (s) => s.copyWith(weeklyGoalPomodoros: value.clamp(0, 10080)));

  Future<void> setFontScale(double value) =>
      updateSettings((s) => s.copyWith(fontScale: value.clamp(1.0, 1.5)));

  Future<void> setAutomaticUpdates(bool value) =>
      updateSettings((s) => s.copyWith(automaticUpdates: value));

  Future<void> setEnableSound(bool value) =>
      updateSettings((s) => s.copyWith(enableSound: value));
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return SettingsNotifier(repo);
});
