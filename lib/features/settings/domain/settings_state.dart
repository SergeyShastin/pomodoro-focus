import '../../../core/theme/app_theme_mode.dart';

class SettingsState {
  final int workDurationMinutes;
  final int shortBreakDurationMinutes;
  final int longBreakDurationMinutes;
  final int sessionsBeforeLongBreak;
  final bool autoStartBreaks;
  final bool autoStartPomodoros;
  final bool enableDndDuringWork;
  final bool enableNotifications;
  final bool enableSound;
  final bool automaticUpdates;
  final bool turnOffScreenOnBreak;
  final bool minimizeToTrayOnClose;
  final AppThemeMode themeMode;
  final bool useDynamicColor;
  final int seedColorValue;
  final int dailyGoalPomodoros;
  final int weeklyGoalPomodoros;
  final double fontScale;

  const SettingsState({
    this.workDurationMinutes = 25,
    this.shortBreakDurationMinutes = 5,
    this.longBreakDurationMinutes = 15,
    this.sessionsBeforeLongBreak = 4,
    this.autoStartBreaks = false,
    this.autoStartPomodoros = false,
    this.enableDndDuringWork = true,
    this.enableNotifications = true,
    this.enableSound = true,
    this.automaticUpdates = true,
    this.turnOffScreenOnBreak = false,
    this.minimizeToTrayOnClose = true,
    this.themeMode = AppThemeMode.system,
    this.useDynamicColor = true,
    this.seedColorValue = 0xFFD32F2F,
    this.dailyGoalPomodoros = 8,
    this.weeklyGoalPomodoros = 40,
    this.fontScale = 1.2,
  });

  SettingsState copyWith({
    int? workDurationMinutes,
    int? shortBreakDurationMinutes,
    int? longBreakDurationMinutes,
    int? sessionsBeforeLongBreak,
    bool? autoStartBreaks,
    bool? autoStartPomodoros,
    bool? enableDndDuringWork,
    bool? enableNotifications,
    bool? enableSound,
    bool? automaticUpdates,
    bool? turnOffScreenOnBreak,
    bool? minimizeToTrayOnClose,
    AppThemeMode? themeMode,
    bool? useDynamicColor,
    int? seedColorValue,
    int? dailyGoalPomodoros,
    int? weeklyGoalPomodoros,
    double? fontScale,
  }) {
    return SettingsState(
      workDurationMinutes: workDurationMinutes ?? this.workDurationMinutes,
      shortBreakDurationMinutes:
          shortBreakDurationMinutes ?? this.shortBreakDurationMinutes,
      longBreakDurationMinutes:
          longBreakDurationMinutes ?? this.longBreakDurationMinutes,
      sessionsBeforeLongBreak:
          sessionsBeforeLongBreak ?? this.sessionsBeforeLongBreak,
      autoStartBreaks: autoStartBreaks ?? this.autoStartBreaks,
      autoStartPomodoros: autoStartPomodoros ?? this.autoStartPomodoros,
      enableDndDuringWork: enableDndDuringWork ?? this.enableDndDuringWork,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      enableSound: enableSound ?? this.enableSound,
      automaticUpdates: automaticUpdates ?? this.automaticUpdates,
      turnOffScreenOnBreak: turnOffScreenOnBreak ?? this.turnOffScreenOnBreak,
      minimizeToTrayOnClose:
          minimizeToTrayOnClose ?? this.minimizeToTrayOnClose,
      themeMode: themeMode ?? this.themeMode,
      useDynamicColor: useDynamicColor ?? this.useDynamicColor,
      seedColorValue: seedColorValue ?? this.seedColorValue,
      dailyGoalPomodoros: dailyGoalPomodoros ?? this.dailyGoalPomodoros,
      weeklyGoalPomodoros: weeklyGoalPomodoros ?? this.weeklyGoalPomodoros,
      fontScale: fontScale ?? this.fontScale,
    );
  }
}
