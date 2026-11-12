import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pomodoro_focus/l10n/app_localizations.dart';
import '../../domain/focus_stats.dart';

enum FocusChartMetric { pomodoros, minutes }

class DailyFocusChart extends StatefulWidget {
  final List<DailyFocusItem> last7Days;
  final String localeCode;
  const DailyFocusChart(
      {super.key, required this.last7Days, required this.localeCode});
  @override
  State<DailyFocusChart> createState() => _DailyFocusChartState();
}

class _DailyFocusChartState extends State<DailyFocusChart> {
  FocusChartMetric _metric = FocusChartMetric.pomodoros;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final days = widget.last7Days;
    final counts = _metric == FocusChartMetric.pomodoros;
    double value(DailyFocusItem day) =>
        (counts ? day.pomodorosCount : day.minutes).toDouble();
    final highest =
        days.fold<double>(0, (max, day) => math.max(max, value(day)));
    final interval = counts
        ? math.max(1, (highest / 4).ceil()).toDouble()
        : math.max(15, (highest / 4 / 15).ceil() * 15).toDouble();
    final maxY = math.max(
        interval * 4, (highest / interval).ceil() * interval + interval);
    return Card.filled(
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
          padding: const EdgeInsets.all(24),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 16,
                children: [
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.focusChartTitle,
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(l10n.lastSevenDays,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: colors.onSurfaceVariant)),
                      ]),
                  SegmentedButton<FocusChartMetric>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(
                            value: FocusChartMetric.pomodoros,
                            label: Text(l10n.pomodorosLabel)),
                        ButtonSegment(
                            value: FocusChartMetric.minutes,
                            label: Text(l10n.minutesLabel)),
                      ],
                      selected: {_metric},
                      onSelectionChanged: (selected) =>
                          setState(() => _metric = selected.first)),
                ]),
            const SizedBox(height: 32),
            SizedBox(
                height: 240,
                child: LayoutBuilder(builder: (context, constraints) {
                  final barWidth = ((constraints.maxWidth - 36) / 7 * 0.27)
                      .clamp(12.0, 32.0);
                  return BarChart(
                      BarChartData(
                        maxY: maxY,
                        alignment: BarChartAlignment.spaceAround,
                        gridData: FlGridData(
                            drawVerticalLine: false,
                            horizontalInterval: interval,
                            getDrawingHorizontalLine: (_) => FlLine(
                                color: colors.outlineVariant
                                    .withValues(alpha: 0.5),
                                strokeWidth: 1,
                                dashArray: [4, 5])),
                        borderData: FlBorderData(show: false),
                        barTouchData: BarTouchData(
                            enabled: false,
                            touchTooltipData: BarTouchTooltipData(
                                getTooltipColor: (_) => Colors.transparent,
                                tooltipPadding: EdgeInsets.zero,
                                tooltipMargin: 8,
                                getTooltipItem: (group, groupIndex, rod,
                                        rodIndex) =>
                                    BarTooltipItem(
                                        '${rod.toY.round()}',
                                        theme.textTheme.titleSmall!.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: colors.onSurface)))),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 36,
                                  interval: interval,
                                  getTitlesWidget: (value, meta) => Text(
                                      '${value.round()}',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                              color:
                                                  colors.onSurfaceVariant)))),
                          bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  getTitlesWidget: (position, meta) {
                                    final index = position.toInt();
                                    if (index < 0 || index >= days.length) {
                                      return const SizedBox.shrink();
                                    }
                                    final today = index == days.length - 1;
                                    return Padding(
                                        padding: const EdgeInsets.only(top: 12),
                                        child: Text(
                                            DateFormat.E(widget.localeCode)
                                                .format(days[index].date),
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                    fontWeight: today
                                                        ? FontWeight.w800
                                                        : FontWeight.w500,
                                                    color: today
                                                        ? colors.primary
                                                        : colors
                                                            .onSurfaceVariant)));
                                  })),
                        ),
                        barGroups: List.generate(
                            days.length,
                            (index) => BarChartGroupData(
                                    x: index,
                                    showingTooltipIndicators: const [
                                      0
                                    ],
                                    barRods: [
                                      BarChartRodData(
                                          toY: value(days[index]),
                                          width: barWidth,
                                          color: index == days.length - 1
                                              ? colors.primary
                                              : colors.secondary,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          backDrawRodData:
                                              BackgroundBarChartRodData(
                                                  show: true,
                                                  toY: maxY,
                                                  color: colors
                                                      .surfaceContainerHighest
                                                      .withValues(
                                                          alpha: 0.45))),
                                    ])),
                      ),
                      duration: const Duration(milliseconds: 250));
                })),
          ])),
    );
  }
}
