// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Focus & World Clock';

  @override
  String get timerTab => 'Timer';

  @override
  String get worldClockTab => 'World Clock';

  @override
  String get statsTab => 'Statistics';

  @override
  String get settingsTab => 'Settings';

  @override
  String get focusPhase => 'Focus';

  @override
  String get shortBreakPhase => 'Short Break';

  @override
  String get longBreakPhase => 'Long Break';

  @override
  String get start => 'Start';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String get skip => 'Skip';

  @override
  String get reset => 'Reset';

  @override
  String get taskInputHint => 'What are you working on?';

  @override
  String get taskInputLabel => 'Current Task';

  @override
  String roundIndicator(int current, int total) {
    return 'Session $current of $total';
  }

  @override
  String get sessionCompleted => 'Focus session completed!';

  @override
  String get breakCompleted => 'Break completed! Time to focus.';

  @override
  String get worldClockTitle => 'World Clock';

  @override
  String get localTime => 'Your Time';

  @override
  String get searchCityHint => 'Search city or timezone...';

  @override
  String get addCity => 'Add City';

  @override
  String get delete => 'Delete';

  @override
  String get dayTime => 'Day';

  @override
  String get nightTime => 'Night';

  @override
  String aheadOfLocal(int hours) {
    return '${hours}h ahead';
  }

  @override
  String behindLocal(int hours) {
    return '${hours}h behind';
  }

  @override
  String get sameTime => 'Same time';

  @override
  String get statsTitle => 'Focus Statistics';

  @override
  String get todayFocus => 'Today';

  @override
  String get weekFocus => 'This Week';

  @override
  String get completedPomodoros => 'Completed Pomodoros';

  @override
  String get focusMinutes => 'Focus Minutes';

  @override
  String get focusChartTitle => 'Daily Focus';

  @override
  String get sessionHistoryTitle => 'Session History';

  @override
  String get noSessionsYet => 'No focus sessions recorded yet.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get timerSettings => 'Timer Durations';

  @override
  String workDurationMinutes(int minutes) {
    return 'Focus Duration: $minutes min';
  }

  @override
  String shortBreakDurationMinutes(int minutes) {
    return 'Short Break: $minutes min';
  }

  @override
  String longBreakDurationMinutes(int minutes) {
    return 'Long Break: $minutes min';
  }

  @override
  String sessionsBeforeLongBreak(int count) {
    return 'Sessions before long break: $count';
  }

  @override
  String get autoStartBreaks => 'Auto-start breaks';

  @override
  String get autoStartPomodoros => 'Auto-start next pomodoro';

  @override
  String get dndSettings => 'Do Not Disturb';

  @override
  String get enableDndDuringWork => 'Enable DND during focus sessions';

  @override
  String get dndKdeDescription =>
      'Mutes desktop notifications via KDE Plasma D-Bus';

  @override
  String get dndAndroidPermissionNeeded =>
      'Notification Policy Access is required on Android to toggle DND.';

  @override
  String get grantPermission => 'Grant Permission';

  @override
  String get soundAndNotifications => 'Sound & Notifications';

  @override
  String get enableNotifications => 'System notifications';

  @override
  String get enableSound => 'Sound effects';

  @override
  String get appearanceSettings => 'Appearance';

  @override
  String get themeMode => 'Theme';

  @override
  String get themeSystem => 'System default';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeOled => 'OLED Pure Black (#000000)';

  @override
  String get dynamicColor => 'Dynamic system accent color';

  @override
  String get accentColor => 'Accent Color';

  @override
  String get miniTimer => 'Mini Timer';

  @override
  String get returnToFullWindow => 'Expand Window';

  @override
  String get minimizeToTrayOnClose =>
      'Minimize to tray when closing the window';

  @override
  String get minutesShort => 'min';

  @override
  String get statsLoadError => 'Could not load statistics. Please try again.';

  @override
  String get turnOffScreenOnBreak => 'Turn off displays when a break begins';

  @override
  String get turnOffScreenOnBreakDescription =>
      'Displays turn off after a pomodoro and wake automatically when the break ends. No locking; a mouse movement or key can wake them sooner.';

  @override
  String get screenPowerUnavailable =>
      'Requires KDE Plasma, a Wayland session and kscreen-doctor.';

  @override
  String get goalsSettings => 'Focus goals';

  @override
  String get dailyGoal => 'Daily goal';

  @override
  String get weeklyGoal => 'Weekly goal';

  @override
  String get goalHint => 'Completed pomodoros. Set 0 to turn a goal off.';

  @override
  String get goalDisabled => 'Goal is off';

  @override
  String goalRangeError(int max) {
    return 'Enter a whole number from 0 to $max.';
  }

  @override
  String get saveGoal => 'Save';

  @override
  String get cancelAction => 'Cancel';

  @override
  String get fontSize => 'Text size';

  @override
  String get fontSizeHint => 'Text scale across the app';

  @override
  String get earnedToday => 'Earned today';

  @override
  String get pomodorosLabel => 'Pomodoros';

  @override
  String get lastSevenDays => 'Last 7 days';

  @override
  String get minutesLabel => 'Minutes';

  @override
  String get calendarWeek => 'Monday – Sunday';

  @override
  String get goalReached => 'Goal reached';

  @override
  String goalProgress(int completed, int target) {
    return '$completed of $target pomodoros';
  }

  @override
  String goalRemaining(int count) {
    return '$count to go';
  }

  @override
  String goalExtra(int count) {
    return '+$count beyond your goal';
  }

  @override
  String get goalsSetupHint => 'Set a goal in Settings';

  @override
  String focusTimeValue(int minutes) {
    return '$minutes focus minutes';
  }

  @override
  String earnedPomodoros(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pomodoros',
      one: '$count pomodoro',
    );
    return '$_temp0';
  }

  @override
  String get onePomodoroReward => '+1 pomodoro';

  @override
  String get updatesTitle => 'Application updates';

  @override
  String get automaticUpdates => 'Check for updates automatically';

  @override
  String get updatesDescription =>
      'Check GitHub Releases at startup and every 12 hours. Only version requests are sent; no tasks, history or settings. Downloads start only when you choose Update.';

  @override
  String get updatesChecking => 'Checking for updates…';

  @override
  String get updatesCurrent => 'You are up to date.';

  @override
  String updateAvailable(String version) {
    return 'Version $version is available';
  }

  @override
  String updateDownloading(int percent) {
    return 'Downloading: $percent%';
  }

  @override
  String get updateAction => 'Update';

  @override
  String get checkUpdates => 'Check now';

  @override
  String get updateUnsupported =>
      'Automatic .deb updates require Ubuntu/Kubuntu 26.04 or newer on x86_64.';

  @override
  String get updatePackageMissing =>
      'The release has no compatible .deb package yet. Try again later.';

  @override
  String get updateIntegrityError =>
      'The package could not be verified. It was not opened. Try checking again.';

  @override
  String get updateNetworkError =>
      'Could not contact GitHub or download the update. Check your connection and try again.';

  @override
  String get updateNotificationBody =>
      'Open the app to download the update and launch the system installer.';

  @override
  String appVersion(String version) {
    return 'Version $version';
  }

  @override
  String get updateInstalling =>
      'Installing update… Confirm the system authorization prompt if requested.';

  @override
  String get updateRestartWaiting =>
      'Update installed. The app will restart after the current focus session is completed or reset and its history has been saved.';

  @override
  String get updateRestarting => 'Restarting the app…';

  @override
  String get updateInstallationError =>
      'Installation was cancelled or failed. The app has not been restarted. You can retry.';

  @override
  String get updateRestartError =>
      'The update is installed, but the app could not restart. Retry or use Quit and launch the app again.';
}
