import 'package:pomodoro_focus/core/desktop/tray_service.dart';
import 'package:pomodoro_focus/core/dnd/unsupported_focus_mode_controller.dart';
import 'package:pomodoro_focus/features/timer/presentation/timer_provider.dart';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pomodoro_focus/core/updates/update_restart.dart';
import 'package:pomodoro_focus/core/updates/timer_update_handoff.dart';
import 'package:pomodoro_focus/core/clock/app_clock.dart';
import 'package:pomodoro_focus/features/settings/domain/settings_state.dart';
import 'package:pomodoro_focus/features/timer/domain/pomodoro_engine.dart';
import 'package:pomodoro_focus/features/timer/domain/pomodoro_phase.dart';
import 'package:pomodoro_focus/features/timer/domain/pomodoro_timer_state.dart';

class NoTray extends TrayService {
  @override
  bool get isDesktop => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'timer blocks restart during focus, pause, pending and failed history writes',
    (tester) async {
      final clock = TestClock();
      final engine = PomodoroEngine(
        clock: clock,
        settings: const SettingsState(autoStartBreaks: true),
      );
      var pending = false;
      final timer = TimerNotifier(
        engine,
        NoTray(),
        UnsupportedFocusModeController(),
        () => false,
        completionPending: () => pending,
      );
      addTearDown(timer.dispose);
      expect(timer.canRestartForUpdate, isTrue);
      timer.start();
      expect(timer.canRestartForUpdate, isFalse);
      timer.pause();
      expect(timer.canRestartForUpdate, isFalse);
      timer.start();
      pending = true;
      clock.advance(const Duration(minutes: 25));
      await tester.pump(const Duration(milliseconds: 250));
      expect(timer.state.phase.isBreak, isTrue);
      expect(timer.canRestartForUpdate, isFalse);
      pending = false;
      expect(timer.canRestartForUpdate, isTrue);
      final snapshot = timer.freezeForUpdateRestart();
      timer.start();
      expect(snapshot.phase.isBreak, isTrue);
      expect(timer.state.isRunning, isTrue);
      timer.onSettingsUpdated();
      clock.advance(const Duration(minutes: 6));
      await tester.pump(const Duration(milliseconds: 250));
      expect(timer.state.phase.isBreak, isTrue);
      timer.cancelUpdateRestart();
      timer.blockUpdateRestartForHistoryError();
      expect(timer.canRestartForUpdate, isFalse);
    },
  );
  testWidgets(
    'restart waits until safe, runs once and disposal cancels waiting',
    (tester) async {
      var safe = false, restarts = 0, announcements = 0;
      final coordinator = UpdateRestartCoordinator(
        canRestart: () => safe,
        restart: () async {
          restarts++;
        },
      );
      final done = coordinator.request(onRestart: () => announcements++);
      await tester.pump(const Duration(seconds: 2));
      expect(restarts, 0);
      safe = true;
      await tester.pump(const Duration(seconds: 1));
      await done;
      await coordinator.request(onRestart: () => announcements++);
      expect([restarts, announcements], [1, 1]);
      coordinator.dispose();
      final cancelled = UpdateRestartCoordinator(
        canRestart: () => false,
        restart: () async {
          restarts++;
        },
      );
      final waiting = cancelled.request(onRestart: () {});
      cancelled.dispose();
      await waiting;
      await tester.pump(const Duration(seconds: 3));
      expect(restarts, 1);
    },
  );
  test(
    'handoff restores a break with its deadline, task and cycle, exactly once',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final clock = TestClock();
      final now = clock.now();
      final snapshot = PomodoroTimerState(
        phase: PomodoroPhase.shortBreak,
        isRunning: true,
        totalDuration: const Duration(minutes: 5),
        remainingDuration: const Duration(minutes: 2),
        targetEndTime: now.add(const Duration(minutes: 2)),
        sessionStartTime: now.subtract(const Duration(minutes: 3)),
        completedPomodorosInCycle: 2,
        totalCompletedPomodoros: 6,
        currentTaskName: 'Task',
      );
      await TimerUpdateHandoff.save(prefs, snapshot, now);
      clock.advance(const Duration(seconds: 4));
      final restored = TimerUpdateHandoff.take(prefs, clock.now())!;
      expect(TimerUpdateHandoff.take(prefs, clock.now()), isNull);
      final engine = PomodoroEngine(
        clock: clock,
        settings: const SettingsState(autoStartPomodoros: true),
        initialState: restored,
      );
      engine.tick();
      expect(
        engine.state.remainingDuration,
        const Duration(minutes: 1, seconds: 56),
      );
      expect(engine.state.completedPomodorosInCycle, 2);
      expect(engine.state.currentTaskName, 'Task');
      clock.advance(const Duration(minutes: 2));
      engine.tick();
      expect(engine.state.phase, PomodoroPhase.work);
      expect(engine.state.isRunning, isTrue);
    },
  );
  test(
    'unfinished focus, expired and malformed handoffs are rejected',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime(2026, 11, 12);
      await expectLater(
        TimerUpdateHandoff.save(
          prefs,
          const PomodoroTimerState(isRunning: true),
          now,
        ),
        throwsStateError,
      );
      await TimerUpdateHandoff.save(prefs, const PomodoroTimerState(), now);
      expect(
        TimerUpdateHandoff.take(prefs, now.add(const Duration(minutes: 11))),
        isNull,
      );
      await prefs.setString(TimerUpdateHandoff.key, '{invalid');
      expect(TimerUpdateHandoff.take(prefs, now), isNull);
      await prefs.setString(
        TimerUpdateHandoff.key,
        jsonEncode({'savedAt': now.toIso8601String(), 'phase': 100}),
      );
      expect(TimerUpdateHandoff.take(prefs, now), isNull);
    },
  );
}
