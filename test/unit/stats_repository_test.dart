import 'dart:ffi';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro_focus/core/database/app_database.dart';
import 'package:pomodoro_focus/features/stats/data/stats_repository.dart';
import 'package:pomodoro_focus/features/timer/domain/pomodoro_phase.dart';
import 'package:sqlite3/open.dart';

void main() {
  late AppDatabase db;
  late StatsRepository repo;

  setUpAll(() {
    open.overrideFor(
      OperatingSystem.linux,
      () => DynamicLibrary.open('libsqlite3.so.0'),
    );
  });

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = StatsRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('StatsRepository records sessions and retrieves them accurately',
      () async {
    final now = DateTime(2026, 6, 10, 14, 0);

    // Record 2 focus sessions today
    await repo.recordSession(
      phase: PomodoroPhase.work,
      startTime: now.subtract(const Duration(minutes: 25)),
      endTime: now,
      duration: const Duration(minutes: 25),
      taskName: 'Coding Feature',
    );

    await repo.recordSession(
      phase: PomodoroPhase.work,
      startTime: now.add(const Duration(minutes: 5)),
      endTime: now.add(const Duration(minutes: 30)),
      duration: const Duration(minutes: 25),
      taskName: 'Reviewing PR',
    );

    // Verify recent sessions stream
    final recent = await repo.watchRecentSessions().first;
    expect(recent.length, 2);
    expect(recent.first.taskName, 'Reviewing PR');
    expect(recent.last.taskName, 'Coding Feature');

    // Verify stats summary
    final summary = await repo.getStatsSummary(now);
    expect(summary.todayPomodoros, 2);
    expect(summary.todayMinutes, 50);
    expect(summary.weekPomodoros, 2);
    expect(summary.weekMinutes, 50);
    expect(summary.last7Days.length, 7);

    // Today's slot (the last item) should have 50 minutes and 2 pomodoros
    final todayItem = summary.last7Days.last;
    expect(todayItem.minutes, 50);
    expect(todayItem.pomodorosCount, 2);
  });

  test(
      'midnight belongs to today and tomorrow is excluded; unfinished work ignored',
      () async {
    final today = DateTime(2026, 11, 12);
    for (final end in [today, DateTime(2026, 11, 13)]) {
      await repo.recordSession(
          phase: PomodoroPhase.work,
          startTime: end.subtract(const Duration(minutes: 25)),
          endTime: end,
          duration: const Duration(minutes: 25),
          taskName: 'Boundary');
    }
    await db.insertSession(FocusSessionsCompanion.insert(
        phase: 'work',
        startTime: today,
        endTime: today.add(const Duration(hours: 1)),
        durationMinutes: 25,
        completed: const Value(false)));
    final summary =
        await repo.getStatsSummary(today.add(const Duration(hours: 12)));
    expect(summary.todayPomodoros, 1);
    expect(summary.weekMinutes, 25);
    expect(summary.last7Days.last.minutes, 25);
    expect((await repo.watchRecentSessions().first).length, 2);
  });

  test('calendar buckets remain correct across DST week', () async {
    // Run also with TZ=Europe/Kyiv to cross the October clock change.
    for (var day = 22; day <= 28; day++) {
      final end = DateTime(2026, 10, day, 12);
      await repo.recordSession(
          phase: PomodoroPhase.work,
          startTime: end.subtract(const Duration(minutes: 25)),
          endTime: end,
          duration: const Duration(minutes: 25),
          taskName: 'Day $day');
    }
    final summary = await repo.getStatsSummary(DateTime(2026, 10, 28, 18));
    expect(summary.weekMinutes, 75);
    expect(summary.last7Days.map((d) => d.minutes), everyElement(25));
    expect(
        summary.last7Days.map((d) => d.date.day), [22, 23, 24, 25, 26, 27, 28]);
  });

  test('weekly goal resets on Monday while the 7-day chart retains Sunday',
      () async {
    for (final day in [DateTime(2026, 11, 8, 12), DateTime(2026, 11, 9, 12)]) {
      await repo.recordSession(
          phase: PomodoroPhase.work,
          startTime: day.subtract(const Duration(minutes: 25)),
          endTime: day,
          duration: const Duration(minutes: 25),
          taskName: 'Calendar boundary');
    }
    final monday = await repo.getStatsSummary(DateTime(2026, 11, 9, 18));
    expect(monday.weekPomodoros, 1);
    expect(monday.weekMinutes, 25);
    expect(
        monday.last7Days.fold<int>(0, (sum, item) => sum + item.pomodorosCount),
        2);
    final sunday = await repo.getStatsSummary(DateTime(2026, 11, 8, 18));
    expect(sunday.weekPomodoros, 1);
  });
}
