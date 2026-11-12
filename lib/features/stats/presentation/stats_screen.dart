import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pomodoro_focus/l10n/app_localizations.dart';
import '../../settings/presentation/settings_provider.dart';
import '../domain/focus_stats.dart';
import 'stats_provider.dart';
import 'widgets/daily_focus_chart.dart';
import 'widgets/session_history_list.dart';
import 'widgets/stats_summary_cards.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final summaryAsync = ref.watch(statsSummaryProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.statsTitle),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(statsSummaryProvider);
          await ref.read(statsSummaryProvider.future);
        },
        child: Center(
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1240),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  children: [
                    // KPI Summary Cards
                    summaryAsync.when(
                      data: (summary) => StatsSummaryCards(
                          summary: summary,
                          dailyGoal: settings.dailyGoalPomodoros,
                          weeklyGoal: settings.weeklyGoalPomodoros),
                      loading: () => StatsSummaryCards(
                          summary: FocusStatsSummary.empty(),
                          dailyGoal: settings.dailyGoalPomodoros,
                          weeklyGoal: settings.weeklyGoalPomodoros),
                      error: (_, __) => StatsSummaryCards(
                          summary: FocusStatsSummary.empty(),
                          dailyGoal: settings.dailyGoalPomodoros,
                          weeklyGoal: settings.weeklyGoalPomodoros),
                    ),
                    const SizedBox(height: 16),

                    // Daily Chart
                    summaryAsync.when(
                      data: (summary) => DailyFocusChart(
                        last7Days: summary.last7Days,
                        localeCode: 'en',
                      ),
                      loading: () => const SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, __) => SizedBox(
                        height: 100,
                        child: Center(child: Text(l10n.statsLoadError)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Session History List
                    SessionHistoryList(localeCode: 'en'),
                    const SizedBox(height: 24),
                  ],
                ))),
      ),
    );
  }
}
