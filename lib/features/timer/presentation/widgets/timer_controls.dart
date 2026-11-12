import 'package:flutter/material.dart';
import 'package:pomodoro_focus/l10n/app_localizations.dart';
import '../../domain/pomodoro_timer_state.dart';

class TimerControls extends StatelessWidget {
  final PomodoroTimerState state;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onSkip;
  final VoidCallback onReset;

  const TimerControls({
    super.key,
    required this.state,
    required this.onStart,
    required this.onPause,
    required this.onSkip,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Reset Button
        IconButton.filledTonal(
          tooltip: l10n.reset,
          iconSize: 24,
          icon: const Icon(Icons.refresh),
          onPressed: state.isInitial ? null : onReset,
        ),
        const SizedBox(width: 20),

        // Primary Play / Pause Button
        FilledButton.icon(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            textStyle:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          icon: Icon(
            state.isRunning ? Icons.pause : Icons.play_arrow,
            size: 28,
          ),
          label: Text(
            state.isRunning
                ? l10n.pause
                : (state.isPaused ? l10n.resume : l10n.start),
          ),
          onPressed: state.isRunning ? onPause : onStart,
        ),
        const SizedBox(width: 20),

        // Skip Button
        IconButton.filledTonal(
          tooltip: l10n.skip,
          iconSize: 24,
          icon: const Icon(Icons.skip_next),
          onPressed: onSkip,
        ),
      ],
    );
  }
}
