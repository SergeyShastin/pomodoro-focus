import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Focus & World Clock'**
  String get appTitle;

  /// No description provided for @timerTab.
  ///
  /// In en, this message translates to:
  /// **'Timer'**
  String get timerTab;

  /// No description provided for @worldClockTab.
  ///
  /// In en, this message translates to:
  /// **'World Clock'**
  String get worldClockTab;

  /// No description provided for @statsTab.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statsTab;

  /// No description provided for @settingsTab.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTab;

  /// No description provided for @focusPhase.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get focusPhase;

  /// No description provided for @shortBreakPhase.
  ///
  /// In en, this message translates to:
  /// **'Short Break'**
  String get shortBreakPhase;

  /// No description provided for @longBreakPhase.
  ///
  /// In en, this message translates to:
  /// **'Long Break'**
  String get longBreakPhase;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @taskInputHint.
  ///
  /// In en, this message translates to:
  /// **'What are you working on?'**
  String get taskInputHint;

  /// No description provided for @taskInputLabel.
  ///
  /// In en, this message translates to:
  /// **'Current Task'**
  String get taskInputLabel;

  /// No description provided for @roundIndicator.
  ///
  /// In en, this message translates to:
  /// **'Session {current} of {total}'**
  String roundIndicator(int current, int total);

  /// No description provided for @sessionCompleted.
  ///
  /// In en, this message translates to:
  /// **'Focus session completed!'**
  String get sessionCompleted;

  /// No description provided for @breakCompleted.
  ///
  /// In en, this message translates to:
  /// **'Break completed! Time to focus.'**
  String get breakCompleted;

  /// No description provided for @worldClockTitle.
  ///
  /// In en, this message translates to:
  /// **'World Clock'**
  String get worldClockTitle;

  /// No description provided for @localTime.
  ///
  /// In en, this message translates to:
  /// **'Your Time'**
  String get localTime;

  /// No description provided for @searchCityHint.
  ///
  /// In en, this message translates to:
  /// **'Search city or timezone...'**
  String get searchCityHint;

  /// No description provided for @addCity.
  ///
  /// In en, this message translates to:
  /// **'Add City'**
  String get addCity;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @dayTime.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get dayTime;

  /// No description provided for @nightTime.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get nightTime;

  /// No description provided for @aheadOfLocal.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ahead'**
  String aheadOfLocal(int hours);

  /// No description provided for @behindLocal.
  ///
  /// In en, this message translates to:
  /// **'{hours}h behind'**
  String behindLocal(int hours);

  /// No description provided for @sameTime.
  ///
  /// In en, this message translates to:
  /// **'Same time'**
  String get sameTime;

  /// No description provided for @statsTitle.
  ///
  /// In en, this message translates to:
  /// **'Focus Statistics'**
  String get statsTitle;

  /// No description provided for @todayFocus.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayFocus;

  /// No description provided for @weekFocus.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get weekFocus;

  /// No description provided for @completedPomodoros.
  ///
  /// In en, this message translates to:
  /// **'Completed Pomodoros'**
  String get completedPomodoros;

  /// No description provided for @focusMinutes.
  ///
  /// In en, this message translates to:
  /// **'Focus Minutes'**
  String get focusMinutes;

  /// No description provided for @focusChartTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Focus'**
  String get focusChartTitle;

  /// No description provided for @sessionHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Session History'**
  String get sessionHistoryTitle;

  /// No description provided for @noSessionsYet.
  ///
  /// In en, this message translates to:
  /// **'No focus sessions recorded yet.'**
  String get noSessionsYet;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @timerSettings.
  ///
  /// In en, this message translates to:
  /// **'Timer Durations'**
  String get timerSettings;

  /// No description provided for @workDurationMinutes.
  ///
  /// In en, this message translates to:
  /// **'Focus Duration: {minutes} min'**
  String workDurationMinutes(int minutes);

  /// No description provided for @shortBreakDurationMinutes.
  ///
  /// In en, this message translates to:
  /// **'Short Break: {minutes} min'**
  String shortBreakDurationMinutes(int minutes);

  /// No description provided for @longBreakDurationMinutes.
  ///
  /// In en, this message translates to:
  /// **'Long Break: {minutes} min'**
  String longBreakDurationMinutes(int minutes);

  /// No description provided for @sessionsBeforeLongBreak.
  ///
  /// In en, this message translates to:
  /// **'Sessions before long break: {count}'**
  String sessionsBeforeLongBreak(int count);

  /// No description provided for @autoStartBreaks.
  ///
  /// In en, this message translates to:
  /// **'Auto-start breaks'**
  String get autoStartBreaks;

  /// No description provided for @autoStartPomodoros.
  ///
  /// In en, this message translates to:
  /// **'Auto-start next pomodoro'**
  String get autoStartPomodoros;

  /// No description provided for @dndSettings.
  ///
  /// In en, this message translates to:
  /// **'Do Not Disturb'**
  String get dndSettings;

  /// No description provided for @enableDndDuringWork.
  ///
  /// In en, this message translates to:
  /// **'Enable DND during focus sessions'**
  String get enableDndDuringWork;

  /// No description provided for @dndKdeDescription.
  ///
  /// In en, this message translates to:
  /// **'Mutes desktop notifications via KDE Plasma D-Bus'**
  String get dndKdeDescription;

  /// No description provided for @dndAndroidPermissionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Notification Policy Access is required on Android to toggle DND.'**
  String get dndAndroidPermissionNeeded;

  /// No description provided for @grantPermission.
  ///
  /// In en, this message translates to:
  /// **'Grant Permission'**
  String get grantPermission;

  /// No description provided for @soundAndNotifications.
  ///
  /// In en, this message translates to:
  /// **'Sound & Notifications'**
  String get soundAndNotifications;

  /// No description provided for @enableNotifications.
  ///
  /// In en, this message translates to:
  /// **'System notifications'**
  String get enableNotifications;

  /// No description provided for @enableSound.
  ///
  /// In en, this message translates to:
  /// **'Sound effects'**
  String get enableSound;

  /// No description provided for @appearanceSettings.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceSettings;

  /// No description provided for @themeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeMode;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeOled.
  ///
  /// In en, this message translates to:
  /// **'OLED Pure Black (#000000)'**
  String get themeOled;

  /// No description provided for @dynamicColor.
  ///
  /// In en, this message translates to:
  /// **'Dynamic system accent color'**
  String get dynamicColor;

  /// No description provided for @accentColor.
  ///
  /// In en, this message translates to:
  /// **'Accent Color'**
  String get accentColor;

  /// No description provided for @miniTimer.
  ///
  /// In en, this message translates to:
  /// **'Mini Timer'**
  String get miniTimer;

  /// No description provided for @returnToFullWindow.
  ///
  /// In en, this message translates to:
  /// **'Expand Window'**
  String get returnToFullWindow;

  /// No description provided for @minimizeToTrayOnClose.
  ///
  /// In en, this message translates to:
  /// **'Minimize to tray when closing the window'**
  String get minimizeToTrayOnClose;

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get minutesShort;

  /// No description provided for @statsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load statistics. Please try again.'**
  String get statsLoadError;

  /// No description provided for @turnOffScreenOnBreak.
  ///
  /// In en, this message translates to:
  /// **'Turn off displays when a break begins'**
  String get turnOffScreenOnBreak;

  /// No description provided for @turnOffScreenOnBreakDescription.
  ///
  /// In en, this message translates to:
  /// **'Displays turn off after a pomodoro and wake automatically when the break ends. No locking; a mouse movement or key can wake them sooner.'**
  String get turnOffScreenOnBreakDescription;

  /// No description provided for @screenPowerUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Requires KDE Plasma, a Wayland session and kscreen-doctor.'**
  String get screenPowerUnavailable;

  /// No description provided for @goalsSettings.
  ///
  /// In en, this message translates to:
  /// **'Focus goals'**
  String get goalsSettings;

  /// No description provided for @dailyGoal.
  ///
  /// In en, this message translates to:
  /// **'Daily goal'**
  String get dailyGoal;

  /// No description provided for @weeklyGoal.
  ///
  /// In en, this message translates to:
  /// **'Weekly goal'**
  String get weeklyGoal;

  /// No description provided for @goalHint.
  ///
  /// In en, this message translates to:
  /// **'Completed pomodoros. Set 0 to turn a goal off.'**
  String get goalHint;

  /// No description provided for @goalDisabled.
  ///
  /// In en, this message translates to:
  /// **'Goal is off'**
  String get goalDisabled;

  /// No description provided for @goalRangeError.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number from 0 to {max}.'**
  String goalRangeError(int max);

  /// No description provided for @saveGoal.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveGoal;

  /// No description provided for @cancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelAction;

  /// No description provided for @fontSize.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get fontSize;

  /// No description provided for @fontSizeHint.
  ///
  /// In en, this message translates to:
  /// **'Text scale across the app'**
  String get fontSizeHint;

  /// No description provided for @earnedToday.
  ///
  /// In en, this message translates to:
  /// **'Earned today'**
  String get earnedToday;

  /// No description provided for @pomodorosLabel.
  ///
  /// In en, this message translates to:
  /// **'Pomodoros'**
  String get pomodorosLabel;

  /// No description provided for @lastSevenDays.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get lastSevenDays;

  /// No description provided for @minutesLabel.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get minutesLabel;

  /// No description provided for @calendarWeek.
  ///
  /// In en, this message translates to:
  /// **'Monday – Sunday'**
  String get calendarWeek;

  /// No description provided for @goalReached.
  ///
  /// In en, this message translates to:
  /// **'Goal reached'**
  String get goalReached;

  /// No description provided for @goalProgress.
  ///
  /// In en, this message translates to:
  /// **'{completed} of {target} pomodoros'**
  String goalProgress(int completed, int target);

  /// No description provided for @goalRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count} to go'**
  String goalRemaining(int count);

  /// No description provided for @goalExtra.
  ///
  /// In en, this message translates to:
  /// **'+{count} beyond your goal'**
  String goalExtra(int count);

  /// No description provided for @goalsSetupHint.
  ///
  /// In en, this message translates to:
  /// **'Set a goal in Settings'**
  String get goalsSetupHint;

  /// No description provided for @focusTimeValue.
  ///
  /// In en, this message translates to:
  /// **'{minutes} focus minutes'**
  String focusTimeValue(int minutes);

  /// No description provided for @earnedPomodoros.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} pomodoro} other{{count} pomodoros}}'**
  String earnedPomodoros(int count);

  /// No description provided for @onePomodoroReward.
  ///
  /// In en, this message translates to:
  /// **'+1 pomodoro'**
  String get onePomodoroReward;

  /// No description provided for @updatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Application updates'**
  String get updatesTitle;

  /// No description provided for @automaticUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for updates automatically'**
  String get automaticUpdates;

  /// No description provided for @updatesDescription.
  ///
  /// In en, this message translates to:
  /// **'Check GitHub Releases at startup and every 12 hours. Only version requests are sent; no tasks, history or settings. Downloads start only when you choose Update.'**
  String get updatesDescription;

  /// No description provided for @updatesChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking for updates…'**
  String get updatesChecking;

  /// No description provided for @updatesCurrent.
  ///
  /// In en, this message translates to:
  /// **'You are up to date.'**
  String get updatesCurrent;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Version {version} is available'**
  String updateAvailable(String version);

  /// No description provided for @updateDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading: {percent}%'**
  String updateDownloading(int percent);

  /// No description provided for @updateAction.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateAction;

  /// No description provided for @checkUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check now'**
  String get checkUpdates;

  /// No description provided for @updateUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Automatic .deb updates require Ubuntu/Kubuntu 26.04 or newer on x86_64.'**
  String get updateUnsupported;

  /// No description provided for @updatePackageMissing.
  ///
  /// In en, this message translates to:
  /// **'The release has no compatible .deb package yet. Try again later.'**
  String get updatePackageMissing;

  /// No description provided for @updateIntegrityError.
  ///
  /// In en, this message translates to:
  /// **'The package could not be verified. It was not opened. Try checking again.'**
  String get updateIntegrityError;

  /// No description provided for @updateNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Could not contact GitHub or download the update. Check your connection and try again.'**
  String get updateNetworkError;

  /// No description provided for @updateNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'Open the app to download the update and launch the system installer.'**
  String get updateNotificationBody;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String appVersion(String version);

  /// No description provided for @updateInstalling.
  ///
  /// In en, this message translates to:
  /// **'Installing update… Confirm the system authorization prompt if requested.'**
  String get updateInstalling;

  /// No description provided for @updateRestartWaiting.
  ///
  /// In en, this message translates to:
  /// **'Update installed. The app will restart after the current focus session is completed or reset and its history has been saved.'**
  String get updateRestartWaiting;

  /// No description provided for @updateRestarting.
  ///
  /// In en, this message translates to:
  /// **'Restarting the app…'**
  String get updateRestarting;

  /// No description provided for @updateInstallationError.
  ///
  /// In en, this message translates to:
  /// **'Installation was cancelled or failed. The app has not been restarted. You can retry.'**
  String get updateInstallationError;

  /// No description provided for @updateRestartError.
  ///
  /// In en, this message translates to:
  /// **'The update is installed, but the app could not restart. Retry or use Quit and launch the app again.'**
  String get updateRestartError;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
