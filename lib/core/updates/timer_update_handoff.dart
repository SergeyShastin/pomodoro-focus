import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/timer/domain/pomodoro_phase.dart';
import '../../features/timer/domain/pomodoro_timer_state.dart';

/// A single-use restart handoff, not general persistence of unfinished work.
class TimerUpdateHandoff {
  static const key = 'update_timer_handoff_v1';
  static bool isSafe(PomodoroTimerState state) =>
      !state.phase.isWork || state.isInitial;

  static Future<void> save(
    SharedPreferences prefs,
    PomodoroTimerState state,
    DateTime now,
  ) async {
    if (!isSafe(state)) throw StateError('Cannot restart unfinished focus');
    await prefs.setString(
      key,
      jsonEncode({
        'savedAt': now.toUtc().toIso8601String(),
        'phase': state.phase.index,
        'running': state.isRunning,
        'paused': state.isPaused,
        'total': state.totalDuration.inMilliseconds,
        'remaining': state.remainingDuration.inMilliseconds,
        'end': state.targetEndTime?.toUtc().toIso8601String(),
        'start': state.sessionStartTime?.toUtc().toIso8601String(),
        'cycle': state.completedPomodorosInCycle,
        'completed': state.totalCompletedPomodoros,
        'task': state.currentTaskName,
      }),
    );
  }

  static PomodoroTimerState? take(SharedPreferences prefs, DateTime now) {
    final raw = prefs.getString(key);
    if (raw == null) return null;
    // Remove immediately so a later normal launch cannot replay this handoff.
    prefs.remove(key);
    try {
      final value = jsonDecode(raw) as Map<String, dynamic>;
      final saved = DateTime.parse(value['savedAt'] as String);
      final age = now.difference(saved);
      if (age.isNegative || age > const Duration(minutes: 10)) return null;
      final phase = PomodoroPhase.values[value['phase'] as int];
      final running = value['running'] as bool,
          paused = value['paused'] as bool;
      final total = value['total'] as int,
          remaining = value['remaining'] as int;
      final cycle = value['cycle'] as int,
          completed = value['completed'] as int;
      final task = value['task'] as String;
      final end = value['end'] == null
          ? null
          : DateTime.parse(value['end'] as String);
      final start = value['start'] == null
          ? null
          : DateTime.parse(value['start'] as String);
      if (total <= 0 ||
          total > const Duration(days: 1).inMilliseconds ||
          remaining < 0 ||
          remaining > total ||
          cycle < 0 ||
          completed < 0 ||
          cycle > completed ||
          task.length > 10000 ||
          (running && (paused || end == null || start == null)) ||
          (end != null &&
              end.difference(saved).abs() > const Duration(days: 1))) {
        return null;
      }
      final state = PomodoroTimerState(
        phase: phase,
        isRunning: running,
        isPaused: paused,
        totalDuration: Duration(milliseconds: total),
        remainingDuration: Duration(milliseconds: remaining),
        targetEndTime: end,
        sessionStartTime: start,
        completedPomodorosInCycle: cycle,
        totalCompletedPomodoros: completed,
        currentTaskName: task,
      );
      return isSafe(state) ? state : null;
    } catch (_) {
      return null;
    }
  }
}
