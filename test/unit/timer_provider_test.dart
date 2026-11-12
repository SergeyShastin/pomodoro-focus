import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pomodoro_focus/core/audio/audio_service.dart';
import 'package:pomodoro_focus/core/clock/app_clock.dart';
import 'package:pomodoro_focus/core/desktop/desktop_providers.dart';
import 'package:pomodoro_focus/core/desktop/tray_service.dart';
import 'package:pomodoro_focus/core/desktop/linux_screen_power_service.dart';
import 'package:pomodoro_focus/core/dnd/focus_mode_controller.dart';
import 'package:pomodoro_focus/core/dnd/focus_mode_provider.dart';
import 'package:pomodoro_focus/core/notifications/notification_service.dart';
import 'package:pomodoro_focus/features/settings/presentation/settings_provider.dart';
import 'package:pomodoro_focus/features/stats/data/stats_repository.dart';
import 'package:pomodoro_focus/features/stats/presentation/stats_provider.dart';
import 'package:pomodoro_focus/features/timer/domain/pomodoro_phase.dart';
import 'package:pomodoro_focus/features/timer/domain/pomodoro_timer_state.dart';
import 'package:pomodoro_focus/features/timer/presentation/timer_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Tray extends Mock implements TrayService {}

class Focus extends Mock implements FocusModeController {}

class Audio extends Mock implements AudioService {}

class Notifications extends Mock implements NotificationService {}

class Stats extends Mock implements StatsRepository {}

class ScreenPower extends Mock implements LinuxScreenPowerService {}

void main() {
  setUpAll(() {
    registerFallbackValue(const PomodoroTimerState());
    registerFallbackValue(PomodoroPhase.work);
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(Duration.zero);
  });
  testWidgets(
      'settings preserve running deadline, task and pause; DND follows switch',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final tray = Tray();
    final focus = Focus();
    final clock = TestClock();
    when(() => tray.updateTray(any())).thenAnswer((_) async {});
    when(focus.enable).thenAnswer((_) async {});
    when(focus.disable).thenAnswer((_) async {});
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(clock),
      trayServiceProvider.overrideWithValue(tray),
      focusModeControllerProvider.overrideWithValue(focus),
      audioServiceProvider.overrideWithValue(Audio()),
      notificationServiceProvider.overrideWithValue(Notifications()),
      statsRepositoryProvider.overrideWithValue(Stats()),
    ]);
    addTearDown(container.dispose);
    final notifier = container.read(pomodoroNotifierProvider.notifier);
    notifier.setTaskName('Keep me');
    notifier.start();
    final deadline = container.read(pomodoroNotifierProvider).targetEndTime;
    final settings = container.read(settingsProvider.notifier);
    await settings.setWorkDuration(30);
    await settings.setEnableDnd(false);
    expect(container.read(pomodoroNotifierProvider.notifier), same(notifier));
    expect(container.read(pomodoroNotifierProvider).targetEndTime, deadline);
    expect(container.read(pomodoroNotifierProvider).currentTaskName, 'Keep me');
    verify(focus.enable).called(1);
    // Initial stopped state plus disabling during work.
    verify(focus.disable).called(2);
    clock.advance(const Duration(minutes: 5));
    await tester.pump(const Duration(milliseconds: 250));
    notifier.pause();
    await settings.setEnableSound(false);
    expect(container.read(pomodoroNotifierProvider).isPaused, isTrue);
    expect(container.read(pomodoroNotifierProvider).remainingDuration,
        const Duration(minutes: 20));
  });

  testWidgets(
      'completion releases DND, records once, respects muted alerts, and auto-starts work with DND',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'work_duration': 1,
      'short_break_duration': 1,
      'auto_start_breaks': true,
      'auto_start_pomodoros': true,
      'enable_sound': false,
      'enable_notifications': false,
    });
    final prefs = await SharedPreferences.getInstance();
    final tray = Tray();
    final focus = Focus();
    final audio = Audio();
    final notifications = Notifications();
    final stats = Stats();
    final screen = ScreenPower();
    final clock = TestClock();
    when(() => tray.updateTray(any())).thenAnswer((_) async {});
    when(focus.enable).thenAnswer((_) async {});
    when(focus.disable).thenAnswer((_) async {});
    when(() => stats.recordSession(
        phase: any(named: 'phase'),
        startTime: any(named: 'startTime'),
        endTime: any(named: 'endTime'),
        duration: any(named: 'duration'),
        taskName: any(named: 'taskName'))).thenAnswer((_) async {});
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(clock),
      trayServiceProvider.overrideWithValue(tray),
      focusModeControllerProvider.overrideWithValue(focus),
      audioServiceProvider.overrideWithValue(audio),
      notificationServiceProvider.overrideWithValue(notifications),
      statsRepositoryProvider.overrideWithValue(stats),
      linuxScreenPowerServiceProvider.overrideWithValue(screen),
    ]);
    addTearDown(container.dispose);
    container.read(pomodoroNotifierProvider.notifier).start();
    clock.advance(const Duration(minutes: 1));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump();
    expect(container.read(pomodoroNotifierProvider).phase,
        PomodoroPhase.shortBreak);
    verify(() => stats.recordSession(
        phase: PomodoroPhase.work,
        startTime: any(named: 'startTime'),
        endTime: any(named: 'endTime'),
        duration: const Duration(minutes: 1),
        taskName: '')).called(1);
    clock.advance(const Duration(minutes: 1));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump();
    expect(container.read(pomodoroNotifierProvider).phase, PomodoroPhase.work);
    expect(container.read(pomodoroNotifierProvider).isRunning, isTrue);
    verify(focus.enable).called(2);
    verifyNever(screen.turnOff);
    verifyNever(screen.turnOn);
    verifyNever(audio.playCompletionSound);
    verifyNever(() => notifications.showNotification(
        title: any(named: 'title'), body: any(named: 'body')));
    container.read(pomodoroNotifierProvider.notifier).reset();
  });

  for (final longBreak in [false, true]) {
    testWidgets(
        'screen turns off once on ${longBreak ? "long" : "short"} break, not on skip or later ticks',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'work_duration': 1,
        'sessions_before_long_break': longBreak ? 1 : 4,
        'turn_off_screen_on_break': true,
        'enable_sound': false,
        'enable_notifications': false,
      });
      final prefs = await SharedPreferences.getInstance();
      final tray = Tray();
      final focus = Focus();
      final stats = Stats();
      final screen = ScreenPower();
      final clock = TestClock();
      final events = <String>[];
      when(() => tray.updateTray(any())).thenAnswer((_) async {});
      when(focus.enable).thenAnswer((_) async {});
      when(focus.disable).thenAnswer((_) async {
        events.add('uninhibit');
      });
      when(screen.turnOff).thenAnswer((_) async {
        events.add('off');
      });
      when(screen.turnOn).thenAnswer((_) async {
        events.add('on');
      });
      when(() => stats.recordSession(
          phase: any(named: 'phase'),
          startTime: any(named: 'startTime'),
          endTime: any(named: 'endTime'),
          duration: any(named: 'duration'),
          taskName: any(named: 'taskName'))).thenAnswer((_) async {});
      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(clock),
        trayServiceProvider.overrideWithValue(tray),
        focusModeControllerProvider.overrideWithValue(focus),
        audioServiceProvider.overrideWithValue(Audio()),
        notificationServiceProvider.overrideWithValue(Notifications()),
        statsRepositoryProvider.overrideWithValue(stats),
        linuxScreenPowerServiceProvider.overrideWithValue(screen),
      ]);
      addTearDown(container.dispose);
      final notifier = container.read(pomodoroNotifierProvider.notifier);
      notifier.skip(); // Explicit skip is not a completed focus session.
      await tester.pump();
      verifyNever(screen.turnOff);
      notifier.skip();
      notifier.start();
      clock.advance(const Duration(minutes: 1));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();
      expect(container.read(pomodoroNotifierProvider).phase,
          longBreak ? PomodoroPhase.longBreak : PomodoroPhase.shortBreak);
      verify(screen.turnOff).called(1);
      expect(events.last, 'off');
      expect(events.indexOf('uninhibit'), lessThan(events.indexOf('off')));
      notifier.start(); // Starting the waiting break must not blank again.
      await tester.pump(const Duration(seconds: 2));
      verifyNever(screen.turnOff);
      // Wake even when focus waits for manual start, and the option was disabled
      // during a break that the app had already blanked.
      await container
          .read(settingsProvider.notifier)
          .setTurnOffScreenOnBreak(false);
      clock.advance(Duration(minutes: longBreak ? 15 : 5));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();
      expect(
          container.read(pomodoroNotifierProvider).phase, PomodoroPhase.work);
      verify(screen.turnOn).called(1);
      expect(events.last, 'on');
      await tester.pump(const Duration(seconds: 1));
      verifyNever(screen.turnOn);
      notifier.reset();
    });
  }

  testWidgets(
      'expired breaks replayed after sleep do not turn off screen during work',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'work_duration': 1,
      'short_break_duration': 1,
      'auto_start_breaks': true,
      'auto_start_pomodoros': true,
      'turn_off_screen_on_break': true,
      'enable_sound': false,
      'enable_notifications': false,
    });
    final prefs = await SharedPreferences.getInstance();
    final tray = Tray();
    final focus = Focus();
    final stats = Stats();
    final screen = ScreenPower();
    when(screen.turnOn).thenAnswer((_) async {});
    final clock = TestClock();
    when(() => tray.updateTray(any())).thenAnswer((_) async {});
    when(focus.enable).thenAnswer((_) async {});
    when(focus.disable).thenAnswer((_) async {});
    when(() => stats.recordSession(
        phase: any(named: 'phase'),
        startTime: any(named: 'startTime'),
        endTime: any(named: 'endTime'),
        duration: any(named: 'duration'),
        taskName: any(named: 'taskName'))).thenAnswer((_) async {});
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(clock),
      trayServiceProvider.overrideWithValue(tray),
      focusModeControllerProvider.overrideWithValue(focus),
      audioServiceProvider.overrideWithValue(Audio()),
      notificationServiceProvider.overrideWithValue(Notifications()),
      statsRepositoryProvider.overrideWithValue(stats),
      linuxScreenPowerServiceProvider.overrideWithValue(screen),
    ]);
    addTearDown(container.dispose);
    final notifier = container.read(pomodoroNotifierProvider.notifier);
    notifier.start();
    clock.advance(const Duration(minutes: 2, seconds: 1));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump();
    expect(container.read(pomodoroNotifierProvider).phase, PomodoroPhase.work);
    verifyNever(screen.turnOff);
    verify(screen.turnOn).called(1);
    notifier.reset();
  });
}
