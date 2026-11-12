import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro_focus/core/clock/app_clock.dart';
import 'package:pomodoro_focus/features/settings/domain/settings_state.dart';
import 'package:pomodoro_focus/features/timer/domain/pomodoro_engine.dart';
import 'package:pomodoro_focus/features/timer/domain/pomodoro_phase.dart';

void main() {
  late TestClock clock;
  late SettingsState defaultSettings;

  setUp(() {
    clock = TestClock(DateTime(2026, 1, 1, 10, 0, 0));
    defaultSettings = const SettingsState(
      workDurationMinutes: 25,
      shortBreakDurationMinutes: 5,
      longBreakDurationMinutes: 15,
      sessionsBeforeLongBreak: 4,
      autoStartBreaks: false,
      autoStartPomodoros: false,
    );
  });

  test('Initial state is work phase with 25 minutes duration', () {
    final engine = PomodoroEngine(clock: clock, settings: defaultSettings);
    expect(engine.state.phase, PomodoroPhase.work);
    expect(engine.state.isRunning, false);
    expect(engine.state.isPaused, false);
    expect(engine.state.remainingDuration, const Duration(minutes: 25));
    expect(engine.state.formattedTime, '25:00');
  });

  test('Start runs timer and tick decrements remaining time', () {
    final engine = PomodoroEngine(clock: clock, settings: defaultSettings);
    engine.start();

    expect(engine.state.isRunning, true);
    expect(engine.state.isPaused, false);

    // Advance clock by 1 minute
    clock.advance(const Duration(minutes: 1));
    engine.tick();

    expect(engine.state.remainingDuration, const Duration(minutes: 24));
    expect(engine.state.formattedTime, '24:00');
    expect(engine.state.progress, closeTo(1 / 25, 0.001));
  });

  test('Pause freezes remaining time and sleep does not affect paused timer',
      () {
    final engine = PomodoroEngine(clock: clock, settings: defaultSettings);
    engine.start();

    // Advance 5 minutes
    clock.advance(const Duration(minutes: 5));
    engine.tick();
    expect(engine.state.remainingDuration, const Duration(minutes: 20));

    // Pause
    engine.pause();
    expect(engine.state.isRunning, false);
    expect(engine.state.isPaused, true);

    // Simulate system sleeping or sitting idle for 1 hour
    clock.advance(const Duration(hours: 1));
    engine.tick();

    // Still exactly 20 minutes remaining!
    expect(engine.state.remainingDuration, const Duration(minutes: 20));

    // Resume
    engine.start();
    expect(engine.state.isRunning, true);

    // Advance 1 more minute
    clock.advance(const Duration(minutes: 1));
    engine.tick();
    expect(engine.state.remainingDuration, const Duration(minutes: 19));
  });

  test('Laptop sleep during active session: finishes accurately upon wake-up',
      () {
    bool sessionCallbackFired = false;
    final engine = PomodoroEngine(
      clock: clock,
      settings: defaultSettings,
      onSessionCompleted: ({
        required phase,
        required startTime,
        required endTime,
        required duration,
        required taskName,
      }) {
        sessionCallbackFired = true;
        expect(phase, PomodoroPhase.work);
      },
    );

    engine.start();
    // Laptop closed / suspended for 30 minutes (session was 25 minutes)
    clock.advance(const Duration(minutes: 30));
    engine.tick();

    expect(sessionCallbackFired, true);
    expect(engine.state.phase, PomodoroPhase.shortBreak);
    expect(engine.state.completedPomodorosInCycle, 1);
    expect(engine.state.totalCompletedPomodoros, 1);
    expect(engine.state.remainingDuration, const Duration(minutes: 5));
    expect(engine.state.isRunning, false); // autoStartBreaks was false
  });

  test('Completes 4 work sessions and triggers long break after 4th', () {
    final engine = PomodoroEngine(clock: clock, settings: defaultSettings);

    for (int i = 1; i <= 3; i++) {
      // Work session
      expect(engine.state.phase, PomodoroPhase.work);
      engine.start();
      clock.advance(const Duration(minutes: 25));
      engine.tick();

      expect(engine.state.phase, PomodoroPhase.shortBreak);
      expect(engine.state.completedPomodorosInCycle, i);

      // Short break
      engine.start();
      clock.advance(const Duration(minutes: 5));
      engine.tick();
    }

    // 4th Work session
    expect(engine.state.phase, PomodoroPhase.work);
    engine.start();
    clock.advance(const Duration(minutes: 25));
    engine.tick();

    // After 4th pomodoro, must transition to LONG break (15 min) and reset cycle count
    expect(engine.state.phase, PomodoroPhase.longBreak);
    expect(engine.state.totalCompletedPomodoros, 4);
    expect(engine.state.completedPomodorosInCycle, 0);
    expect(engine.state.remainingDuration, const Duration(minutes: 15));
  });

  test('Auto-start break immediately starts countdown when enabled', () {
    final autoSettings = defaultSettings.copyWith(autoStartBreaks: true);
    final engine = PomodoroEngine(clock: clock, settings: autoSettings);

    engine.start();
    clock.advance(const Duration(minutes: 25));
    engine.tick();

    expect(engine.state.phase, PomodoroPhase.shortBreak);
    expect(engine.state.isRunning, true); // automatically running!
  });

  test('Skip phase transitions immediately without marking pomodoro completed',
      () {
    final engine = PomodoroEngine(clock: clock, settings: defaultSettings);
    engine.start();
    clock.advance(const Duration(minutes: 10));

    engine.skip();

    expect(engine.state.phase, PomodoroPhase.shortBreak);
    expect(engine.state.totalCompletedPomodoros, 0);
    expect(engine.state.remainingDuration, const Duration(minutes: 5));
  });

  test('Reset restores current phase duration', () {
    final engine = PomodoroEngine(clock: clock, settings: defaultSettings);
    engine.start();
    clock.advance(const Duration(minutes: 10));
    engine.tick();
    expect(engine.state.remainingDuration, const Duration(minutes: 15));

    engine.reset();
    expect(engine.state.isRunning, false);
    expect(engine.state.isPaused, false);
    expect(engine.state.remainingDuration, const Duration(minutes: 25));
  });

  test('Task name is retained across state updates', () {
    final engine = PomodoroEngine(clock: clock, settings: defaultSettings);
    engine.setTaskName('Refactor code');
    expect(engine.state.currentTaskName, 'Refactor code');

    engine.start();
    clock.advance(const Duration(minutes: 25));
    engine.tick();

    expect(engine.state.currentTaskName, 'Refactor code');
  });

  test('completion after sleep is recorded at the deadline, not wake time', () {
    DateTime? recordedEnd;
    final engine = PomodoroEngine(
        clock: clock,
        settings: defaultSettings,
        onSessionCompleted: (
            {required phase,
            required startTime,
            required endTime,
            required duration,
            required taskName}) {
          recordedEnd = endTime;
        });
    engine.start();
    final deadline = engine.state.targetEndTime;
    clock.advance(const Duration(days: 1));
    engine.tick();
    expect(recordedEnd, deadline);
  });

  test('pause after expired deadline completes instead of freezing at zero',
      () {
    final engine = PomodoroEngine(clock: clock, settings: defaultSettings);
    engine.start();
    clock.advance(const Duration(minutes: 26));
    engine.pause();
    expect(engine.state.totalCompletedPomodoros, 1);
    expect(engine.state.phase, PomodoroPhase.shortBreak);
    expect(engine.state.isPaused, isFalse);
    expect(engine.state.remainingDuration, const Duration(minutes: 5));
  });

  test('display rounds remaining seconds up and never shows zero early', () {
    final engine = PomodoroEngine(clock: clock, settings: defaultSettings);
    engine.start();
    clock.advance(const Duration(milliseconds: 250));
    engine.tick();
    expect(engine.state.formattedTime, '25:00');
    clock.advance(const Duration(minutes: 24, seconds: 59, milliseconds: 500));
    engine.tick();
    expect(engine.state.formattedTime, '00:01');
  });

  test('auto-start phases retain deadlines across sleep without drift', () {
    final engine = PomodoroEngine(
        clock: clock,
        settings: defaultSettings.copyWith(
            autoStartBreaks: true, autoStartPomodoros: true));
    engine.start();
    final start = clock.now();
    clock.advance(const Duration(minutes: 31));
    engine.tick();
    expect(engine.state.phase, PomodoroPhase.work);
    expect(engine.state.totalCompletedPomodoros, 1);
    expect(engine.state.remainingDuration, const Duration(minutes: 24));
    expect(engine.state.targetEndTime, start.add(const Duration(minutes: 55)));
  });
}
