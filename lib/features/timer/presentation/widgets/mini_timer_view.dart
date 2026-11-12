import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pomodoro_focus/l10n/app_localizations.dart';
import 'package:window_manager/window_manager.dart';
import '../../domain/pomodoro_phase.dart';
import '../timer_provider.dart';

class MiniTimerView extends ConsumerWidget {
  final VoidCallback onExpand;

  const MiniTimerView({super.key, required this.onExpand});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final timerState = ref.watch(pomodoroNotifierProvider);
    final notifier = ref.read(pomodoroNotifierProvider.notifier);

    final Color phaseColor;
    final String phaseName;

    switch (timerState.phase) {
      case PomodoroPhase.work:
        phaseColor = theme.colorScheme.primary;
        phaseName = l10n.focusPhase;
        break;
      case PomodoroPhase.shortBreak:
        phaseColor = theme.colorScheme.tertiary;
        phaseName = l10n.shortBreakPhase;
        break;
      case PomodoroPhase.longBreak:
        phaseColor = theme.colorScheme.secondary;
        phaseName = l10n.longBreakPhase;
        break;
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          children: [
            Row(children: [
              Expanded(
                  child: DragToMoveArea(
                      child: Row(children: [
                Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                        color: phaseColor, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Expanded(
                    child: Text(phaseName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: phaseColor, fontWeight: FontWeight.bold))),
              ]))),
              IconButton(
                iconSize: 18,
                tooltip: l10n.returnToFullWindow,
                icon: const Icon(Icons.open_in_full),
                onPressed: onExpand,
              ),
            ]),
            const Spacer(),
            Row(children: [
              Expanded(
                  child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(timerState.formattedTime,
                          style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ])))),
              IconButton.filled(
                tooltip: timerState.isRunning
                    ? l10n.pause
                    : (timerState.isPaused ? l10n.resume : l10n.start),
                iconSize: 20,
                icon:
                    Icon(timerState.isRunning ? Icons.pause : Icons.play_arrow),
                onPressed:
                    timerState.isRunning ? notifier.pause : notifier.start,
              ),
              const SizedBox(width: 4),
              IconButton.filledTonal(
                tooltip: l10n.skip,
                iconSize: 18,
                icon: const Icon(Icons.skip_next),
                onPressed: notifier.skip,
              ),
            ]),
            if (timerState.currentTaskName.isNotEmpty) ...[
              const SizedBox(height: 2),
              Align(
                  alignment: Alignment.centerLeft,
                  child: Text(timerState.currentTaskName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant))),
            ],
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
