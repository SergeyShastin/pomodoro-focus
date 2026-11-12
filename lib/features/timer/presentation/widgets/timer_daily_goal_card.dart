import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pomodoro_focus/l10n/app_localizations.dart';
import '../../../settings/presentation/settings_provider.dart';
import '../../../stats/domain/focus_goal_progress.dart';
import '../../../stats/presentation/stats_provider.dart';

/// Uses committed history, so today's progress survives app restarts.
class TimerDailyGoalCard extends ConsumerWidget {
  const TimerDailyGoalCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(statsSummaryProvider);
    final target =
        ref.watch(settingsProvider.select((s) => s.dailyGoalPomodoros));
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: Card.filled(
        color: colors.secondaryContainer,
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  Image.asset('assets/icons/app_icon.png',
                      width: 24, height: 24, excludeFromSemantics: true),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(l10n.dailyGoal,
                          style: theme.textTheme.titleMedium?.copyWith(
                              color: colors.onSecondaryContainer,
                              fontWeight: FontWeight.w700))),
                ]),
                const SizedBox(height: 8),
                summary.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => Text(l10n.statsLoadError,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: colors.onSecondaryContainer)),
                  data: (stats) {
                    final goal = FocusGoalProgress(
                        completed: stats.todayPomodoros, target: target);
                    return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Wrap(
                              spacing: 16,
                              runSpacing: 4,
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                    goal.enabled
                                        ? l10n.goalProgress(
                                            goal.completed, goal.target)
                                        : l10n.earnedPomodoros(goal.completed),
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                        color: colors.onSecondaryContainer,
                                        fontWeight: FontWeight.w700)),
                                Text(
                                    !goal.enabled
                                        ? l10n.goalDisabled
                                        : goal.achieved
                                            ? (goal.extra > 0
                                                ? l10n.goalExtra(goal.extra)
                                                : l10n.goalReached)
                                            : l10n
                                                .goalRemaining(goal.remaining),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                        color: colors.onSecondaryContainer)),
                              ]),
                          if (goal.enabled) ...[
                            const SizedBox(height: 10),
                            ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                    value: goal.fraction,
                                    minHeight: 6,
                                    color: colors.primary,
                                    backgroundColor: colors.onSecondaryContainer
                                        .withValues(alpha: 0.12),
                                    semanticsLabel: l10n.goalProgress(
                                        goal.completed, goal.target),
                                    semanticsValue: '${goal.percent}%')),
                          ],
                        ]);
                  },
                ),
              ],
            )),
      ),
    );
  }
}
