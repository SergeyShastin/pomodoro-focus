import 'package:flutter/material.dart';
import 'package:pomodoro_focus/l10n/app_localizations.dart';
import '../../domain/pomodoro_phase.dart';
import '../../domain/pomodoro_timer_state.dart';

class CircularTimerDisplay extends StatelessWidget {
  final PomodoroTimerState state;
  final int sessionsBeforeLongBreak;
  final double size;

  const CircularTimerDisplay({
    super.key,
    required this.state,
    required this.sessionsBeforeLongBreak,
    this.size = 280.0,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final Color progressColor;
    final String phaseLabel;
    final IconData phaseIcon;

    switch (state.phase) {
      case PomodoroPhase.work:
        progressColor = theme.colorScheme.primary;
        phaseLabel = l10n.focusPhase;
        phaseIcon = Icons.laptop_chromebook;
        break;
      case PomodoroPhase.shortBreak:
        progressColor = theme.colorScheme.tertiary;
        phaseLabel = l10n.shortBreakPhase;
        phaseIcon = Icons.coffee_outlined;
        break;
      case PomodoroPhase.longBreak:
        progressColor = theme.colorScheme.secondary;
        phaseLabel = l10n.longBreakPhase;
        phaseIcon = Icons.self_improvement_outlined;
        break;
    }

    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background Track
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: 1.0,
                strokeWidth: 14.0,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.surfaceContainerHighest,
                ),
              ),
            ),
            // Dynamic Animated Progress
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: state.progress),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return SizedBox(
                  width: size,
                  height: size,
                  child: CircularProgressIndicator(
                    value: value,
                    strokeWidth: 14.0,
                    strokeCap: StrokeCap.round,
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  ),
                );
              },
            ),
            // Center Content
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Phase Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: progressColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: progressColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(phaseIcon, size: 16, color: progressColor),
                      const SizedBox(width: 6),
                      Flexible(
                          child: Text(
                        phaseLabel,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: progressColor,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Large Digital Countdown
                Text(
                  state.formattedTime,
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    letterSpacing: -1.0,
                  ),
                ),
                const SizedBox(height: 12),
                // Cycle indicator dots
                _buildCycleDots(context, theme, progressColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCycleDots(
    BuildContext context,
    ThemeData theme,
    Color activeColor,
  ) {
    final total = sessionsBeforeLongBreak;
    final current = state.completedPomodorosInCycle;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (index) {
        final isCompleted = index < current;
        final isCurrent = index == current && state.phase == PomodoroPhase.work;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isCurrent ? 20 : 10,
          height: 10,
          decoration: BoxDecoration(
            color: isCompleted
                ? activeColor
                : (isCurrent
                    ? activeColor.withValues(alpha: 0.5)
                    : theme.colorScheme.surfaceContainerHighest),
            borderRadius: BorderRadius.circular(5),
          ),
        );
      }),
    );
  }
}
