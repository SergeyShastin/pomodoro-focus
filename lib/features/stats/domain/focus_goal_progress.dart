/// A target of zero disables the goal without hiding earned pomodoros.
class FocusGoalProgress {
  final int completed;
  final int target;

  const FocusGoalProgress({required this.completed, required this.target});

  bool get enabled => target > 0;
  bool get achieved => enabled && completed >= target;
  double get fraction => enabled ? (completed / target).clamp(0.0, 1.0) : 0;
  int get percent =>
      enabled ? (completed * 100 / target).round().clamp(0, 100) : 0;
  int get remaining => enabled ? (target - completed).clamp(0, target) : 0;
  int get extra => enabled ? (completed - target).clamp(0, completed) : 0;
}
