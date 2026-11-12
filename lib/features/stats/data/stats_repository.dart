import 'package:drift/drift.dart';
import 'package:pomodoro_focus/core/database/app_database.dart';
import '../../timer/domain/pomodoro_phase.dart';
import '../domain/focus_stats.dart';

class StatsRepository {
  final AppDatabase _db;

  StatsRepository(this._db);

  Future<void> recordSession({
    required PomodoroPhase phase,
    required DateTime startTime,
    required DateTime endTime,
    required Duration duration,
    required String taskName,
  }) async {
    await _db.insertSession(
      FocusSessionsCompanion.insert(
        taskName: Value(taskName),
        phase: phase.name,
        startTime: startTime,
        endTime: endTime,
        durationMinutes: duration.inMinutes,
        completed: const Value(true),
      ),
    );
  }

  Stream<List<FocusSession>> watchRecentSessions({int limit = 50}) =>
      _db.watchRecentSessions(limit: limit);

  Future<FocusStatsSummary> getStatsSummary([DateTime? referenceTime]) async {
    final now = (referenceTime ?? DateTime.now()).toLocal();

    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day + 1);

    // Calendar goals reset on Monday; chart remains a rolling 7-day view.
    final weekStart = DateTime(now.year, now.month, now.day - 6);
    final calendarWeekStart =
        DateTime(now.year, now.month, now.day - now.weekday + 1);
    final sessions = await _db.getSessionsBetween(weekStart, todayEnd);

    int todayPomodoros = 0;
    int todayMinutes = 0;
    int weekPomodoros = 0;
    int weekMinutes = 0;

    final Map<int, List<FocusSession>> sessionsByDayOffset = {};
    for (int i = 0; i < 7; i++) {
      sessionsByDayOffset[i] = [];
    }

    for (final s in sessions) {
      final endTime = s.endTime.toLocal();
      if (!endTime.isBefore(calendarWeekStart)) {
        weekPomodoros++;
        weekMinutes += s.durationMinutes;
      }
      if (!endTime.isBefore(todayStart) && endTime.isBefore(todayEnd)) {
        todayPomodoros++;
        todayMinutes += s.durationMinutes;
      }

      // Group by day offset (0 = 6 days ago, 6 = today)
      final sessionDay = DateTime.utc(endTime.year, endTime.month, endTime.day);
      final dayDiff = sessionDay
          .difference(
            DateTime.utc(weekStart.year, weekStart.month, weekStart.day),
          )
          .inDays;
      if (dayDiff >= 0 && dayDiff < 7) {
        sessionsByDayOffset[dayDiff]?.add(s);
      }
    }

    final List<DailyFocusItem> last7Days = [];
    for (int i = 0; i < 7; i++) {
      final dayDate =
          DateTime(weekStart.year, weekStart.month, weekStart.day + i);
      final daySessions = sessionsByDayOffset[i] ?? [];
      final mins =
          daySessions.fold<int>(0, (sum, item) => sum + item.durationMinutes);
      last7Days.add(DailyFocusItem(
        date: dayDate,
        minutes: mins,
        pomodorosCount: daySessions.length,
      ));
    }

    return FocusStatsSummary(
      todayPomodoros: todayPomodoros,
      todayMinutes: todayMinutes,
      weekPomodoros: weekPomodoros,
      weekMinutes: weekMinutes,
      last7Days: last7Days,
    );
  }
}
