import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pomodoro_focus/core/desktop/desktop_providers.dart';
import 'package:pomodoro_focus/l10n/app_localizations.dart';
import '../../settings/presentation/settings_provider.dart';
import 'timer_provider.dart';
import 'widgets/circular_timer_display.dart';
import 'widgets/task_input_card.dart';
import 'widgets/timer_controls.dart';
import 'widgets/timer_daily_goal_card.dart';

class TimerScreen extends ConsumerWidget {
  const TimerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final timerState = ref.watch(pomodoroNotifierProvider);
    final notifier = ref.read(pomodoroNotifierProvider.notifier);
    final settings = ref.watch(settingsProvider);

    final isDesktop =
        !kIsWeb && (Platform.isLinux || Platform.isMacOS || Platform.isWindows);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.timerTab),
        actions: [
          if (isDesktop)
            IconButton(
              icon: const Icon(Icons.picture_in_picture_alt_outlined),
              tooltip: l10n.miniTimer,
              onPressed: () async {
                final changed = await ref
                    .read(desktopWindowServiceProvider)
                    .toggleMiniMode(true);
                if (changed) ref.read(isMiniModeProvider.notifier).state = true;
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: LayoutBuilder(builder: (context, constraints) {
            final compact = constraints.maxHeight < 720;
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Task Input Card
                  TaskInputCard(
                    currentTaskName: timerState.currentTaskName,
                    onTaskNameChanged: (name) => notifier.setTaskName(name),
                  ),
                  const SizedBox(height: 16),
                  const TimerDailyGoalCard(),
                  const SizedBox(height: 20),

                  // Circular countdown timer display
                  CircularTimerDisplay(
                    state: timerState,
                    size: compact ? 240 : 280,
                    sessionsBeforeLongBreak: settings.sessionsBeforeLongBreak,
                  ),
                  const SizedBox(height: 24),

                  // Play / Pause / Skip / Reset Controls
                  TimerControls(
                    state: timerState,
                    onStart: () => notifier.start(),
                    onPause: () => notifier.pause(),
                    onSkip: () => notifier.skip(),
                    onReset: () => notifier.reset(),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
