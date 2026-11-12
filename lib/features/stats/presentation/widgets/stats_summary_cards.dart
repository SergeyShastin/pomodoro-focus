import 'package:flutter/material.dart';
import 'package:pomodoro_focus/l10n/app_localizations.dart';
import '../../domain/focus_goal_progress.dart';
import '../../domain/focus_stats.dart';

class StatsSummaryCards extends StatelessWidget {
  final FocusStatsSummary summary;
  final int dailyGoal;
  final int weeklyGoal;

  const StatsSummaryCards(
      {super.key,
      required this.summary,
      this.dailyGoal = 8,
      this.weeklyGoal = 40});

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final today = _TodayCard(
            count: summary.todayPomodoros,
            minutes: summary.todayMinutes,
            target: dailyGoal);
        final week = _WeekCard(
            count: summary.weekPomodoros,
            minutes: summary.weekMinutes,
            target: weeklyGoal);
        if (constraints.maxWidth < 760) {
          return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [today, const SizedBox(height: 16), week]);
        }
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 3, child: today),
          const SizedBox(width: 16),
          Expanded(flex: 2, child: week),
        ]);
      });
}

class _TodayCard extends StatelessWidget {
  final int count;
  final int minutes;
  final int target;
  const _TodayCard(
      {required this.count, required this.minutes, required this.target});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final goal = FocusGoalProgress(completed: count, target: target);
    final stamps = (goal.enabled ? target : count).clamp(0, 12);
    return Card.filled(
      color: colors.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
          padding: const EdgeInsets.all(24),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Image.asset('assets/icons/app_icon.png',
                  width: 32, height: 32, excludeFromSemantics: true),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(l10n.earnedToday,
                      style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.onPrimaryContainer))),
            ]),
            const SizedBox(height: 20),
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Flexible(
                  child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('$count',
                          style: theme.textTheme.displayLarge?.copyWith(
                              fontSize: 76,
                              height: 1,
                              fontWeight: FontWeight.w800,
                              color: colors.onPrimaryContainer,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ])))),
              const SizedBox(width: 20),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(l10n.completedPomodoros,
                        style: theme.textTheme.titleMedium?.copyWith(
                            color: colors.onPrimaryContainer,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text(l10n.focusTimeValue(minutes),
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(color: colors.onPrimaryContainer)),
                  ])),
            ]),
            if (stamps > 0) ...[
              const SizedBox(height: 20),
              ExcludeSemantics(
                  child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(
                          stamps,
                          (index) => Opacity(
                              opacity: index < count ? 1 : 0.18,
                              child: Image.asset('assets/icons/app_icon.png',
                                  width: 28, height: 28))))),
            ],
            const SizedBox(height: 24),
            _GoalDetails(goal: goal, onContainer: true),
          ])),
    );
  }
}

class _WeekCard extends StatelessWidget {
  final int count;
  final int minutes;
  final int target;
  const _WeekCard(
      {required this.count, required this.minutes, required this.target});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final goal = FocusGoalProgress(completed: count, target: target);
    return Card.filled(
      color: colors.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
          padding: const EdgeInsets.all(24),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l10n.weeklyGoal,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(l10n.calendarWeek,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: colors.onSurfaceVariant)),
            const SizedBox(height: 24),
            Row(children: [
              SizedBox(
                  width: 94,
                  height: 94,
                  child: Stack(alignment: Alignment.center, children: [
                    SizedBox.expand(
                        child: CircularProgressIndicator(
                            value: goal.fraction,
                            strokeWidth: 9,
                            strokeCap: StrokeCap.round,
                            backgroundColor: colors.surfaceContainerHighest,
                            color: colors.tertiary,
                            semanticsLabel: l10n.weeklyGoal,
                            semanticsValue: '${goal.percent}%')),
                    Icon(
                        goal.achieved
                            ? Icons.emoji_events_rounded
                            : Icons.flag_outlined,
                        size: 36,
                        color: colors.tertiary),
                  ])),
              const SizedBox(width: 20),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('$count',
                        style: theme.textTheme.displaySmall
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    Text(l10n.pomodorosLabel,
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(l10n.focusTimeValue(minutes),
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: colors.onSurfaceVariant)),
                  ])),
            ]),
            const SizedBox(height: 24),
            _GoalDetails(goal: goal),
          ])),
    );
  }
}

class _GoalDetails extends StatelessWidget {
  final FocusGoalProgress goal;
  final bool onContainer;
  const _GoalDetails({required this.goal, this.onContainer = false});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final foreground =
        onContainer ? colors.onPrimaryContainer : colors.onSurface;
    if (!goal.enabled) {
      return Text(l10n.goalsSetupHint,
          style: theme.textTheme.bodyMedium?.copyWith(color: foreground));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(
          spacing: 12,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(l10n.goalProgress(goal.completed, goal.target),
                style: theme.textTheme.titleSmall?.copyWith(color: foreground)),
            Text('${goal.percent}%',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800, color: foreground)),
          ]),
      const SizedBox(height: 12),
      ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
              value: goal.fraction,
              minHeight: 10,
              color: onContainer ? colors.primary : colors.tertiary,
              backgroundColor: foreground.withValues(alpha: 0.1),
              semanticsLabel: l10n.goalProgress(goal.completed, goal.target),
              semanticsValue: '${goal.percent}%')),
      const SizedBox(height: 12),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(
            goal.achieved
                ? Icons.check_circle_rounded
                : Icons.trending_up_rounded,
            size: 20,
            color: foreground),
        const SizedBox(width: 8),
        Expanded(
            child: Text(
                goal.achieved
                    ? (goal.extra > 0
                        ? l10n.goalExtra(goal.extra)
                        : l10n.goalReached)
                    : l10n.goalRemaining(goal.remaining),
                style:
                    theme.textTheme.bodyMedium?.copyWith(color: foreground))),
      ]),
    ]);
  }
}
