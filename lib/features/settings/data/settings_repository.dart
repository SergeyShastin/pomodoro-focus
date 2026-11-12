import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/settings_state.dart';

class SettingsRepository {
  final SharedPreferences _prefs;

  SettingsRepository(this._prefs);

  static const _keyWorkDuration = 'work_duration';
  static const _keyShortBreakDuration = 'short_break_duration';
  static const _keyLongBreakDuration = 'long_break_duration';
  static const _keySessionsBeforeLongBreak = 'sessions_before_long_break';
  static const _keyAutoStartBreaks = 'auto_start_breaks';
  static const _keyAutoStartPomodoros = 'auto_start_pomodoros';
  static const _keyEnableDnd = 'enable_dnd';
  static const _keyEnableNotifications = 'enable_notifications';
  static const _keyEnableSound = 'enable_sound';
  static const _keyTurnOffScreenOnBreak = 'turn_off_screen_on_break';
  static const _keyThemeMode = 'theme_mode';
  static const _keyUseDynamicColor = 'use_dynamic_color';
  static const _keySeedColor = 'seed_color';

  SettingsState loadSettings() {
    final themeIndex = _prefs.getInt(_keyThemeMode);
    final themeMode = themeIndex != null &&
            themeIndex >= 0 &&
            themeIndex < AppThemeMode.values.length
        ? AppThemeMode.values[themeIndex]
        : AppThemeMode.system;

    return SettingsState(
      workDurationMinutes: _prefs.getInt(_keyWorkDuration) ?? 25,
      shortBreakDurationMinutes: _prefs.getInt(_keyShortBreakDuration) ?? 5,
      longBreakDurationMinutes: _prefs.getInt(_keyLongBreakDuration) ?? 15,
      sessionsBeforeLongBreak: _prefs.getInt(_keySessionsBeforeLongBreak) ?? 4,
      autoStartBreaks: _prefs.getBool(_keyAutoStartBreaks) ?? false,
      autoStartPomodoros: _prefs.getBool(_keyAutoStartPomodoros) ?? false,
      enableDndDuringWork: _prefs.getBool(_keyEnableDnd) ?? true,
      enableNotifications: _prefs.getBool(_keyEnableNotifications) ?? true,
      automaticUpdates: _prefs.getBool('automatic_updates') ?? true,
      enableSound: _prefs.getBool(_keyEnableSound) ?? true,
      turnOffScreenOnBreak: _prefs.getBool(_keyTurnOffScreenOnBreak) ?? false,
      minimizeToTrayOnClose: _prefs.getBool('minimize_to_tray') ?? true,
      themeMode: themeMode,
      useDynamicColor: _prefs.getBool(_keyUseDynamicColor) ?? true,
      seedColorValue: _prefs.getInt(_keySeedColor) ?? 0xFFD32F2F,
      dailyGoalPomodoros:
          (_prefs.getInt('daily_goal_pomodoros') ?? 8).clamp(0, 1440),
      weeklyGoalPomodoros:
          (_prefs.getInt('weekly_goal_pomodoros') ?? 40).clamp(0, 10080),
      fontScale: (_prefs.getDouble('font_scale') ?? 1.2).clamp(1.0, 1.5),
    );
  }

  Future<void> saveSettings(SettingsState settings) async {
    await Future.wait([
      _prefs.setBool('automatic_updates', settings.automaticUpdates),
      _prefs.setInt(_keyWorkDuration, settings.workDurationMinutes),
      _prefs.setInt(_keyShortBreakDuration, settings.shortBreakDurationMinutes),
      _prefs.setInt(_keyLongBreakDuration, settings.longBreakDurationMinutes),
      _prefs.setInt(
          _keySessionsBeforeLongBreak, settings.sessionsBeforeLongBreak),
      _prefs.setBool(_keyAutoStartBreaks, settings.autoStartBreaks),
      _prefs.setBool(_keyAutoStartPomodoros, settings.autoStartPomodoros),
      _prefs.setBool(_keyEnableDnd, settings.enableDndDuringWork),
      _prefs.setBool(_keyEnableNotifications, settings.enableNotifications),
      _prefs.setBool(_keyEnableSound, settings.enableSound),
      _prefs.setBool(_keyTurnOffScreenOnBreak, settings.turnOffScreenOnBreak),
      _prefs.setBool('minimize_to_tray', settings.minimizeToTrayOnClose),
      _prefs.setInt(_keyThemeMode, settings.themeMode.index),
      _prefs.setBool(_keyUseDynamicColor, settings.useDynamicColor),
      _prefs.setInt(_keySeedColor, settings.seedColorValue),
      _prefs.setInt('daily_goal_pomodoros', settings.dailyGoalPomodoros),
      _prefs.setInt('weekly_goal_pomodoros', settings.weeklyGoalPomodoros),
      _prefs.setDouble('font_scale', settings.fontScale),
    ]);
  }
}
