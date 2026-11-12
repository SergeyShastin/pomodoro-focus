class DailyFocusItem {
  final DateTime date;
  final int minutes;
  final int pomodorosCount;

  const DailyFocusItem({
    required this.date,
    required this.minutes,
    required this.pomodorosCount,
  });
}

class FocusStatsSummary {
  final int todayPomodoros;
  final int todayMinutes;
  final int weekPomodoros;
  final int weekMinutes;
  final List<DailyFocusItem> last7Days;

  const FocusStatsSummary({
    required this.todayPomodoros,
    required this.todayMinutes,
    required this.weekPomodoros,
    required this.weekMinutes,
    required this.last7Days,
  });

  factory FocusStatsSummary.empty() => const FocusStatsSummary(
        todayPomodoros: 0,
        todayMinutes: 0,
        weekPomodoros: 0,
        weekMinutes: 0,
        last7Days: [],
      );
}
