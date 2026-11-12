import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro_focus/core/clock/app_clock.dart';
import 'package:pomodoro_focus/core/theme/app_theme.dart';
import 'package:pomodoro_focus/core/desktop/tray_service.dart';
import 'package:pomodoro_focus/core/dnd/unsupported_focus_mode_controller.dart';
import 'package:pomodoro_focus/features/settings/domain/settings_state.dart';
import 'package:pomodoro_focus/features/timer/domain/pomodoro_engine.dart';
import 'package:pomodoro_focus/features/timer/presentation/timer_provider.dart';
import 'package:pomodoro_focus/features/timer/presentation/widgets/mini_timer_view.dart';
import 'package:pomodoro_focus/l10n/app_localizations.dart';

class NoTray extends TrayService {
  @override
  bool get isDesktop => false;
}

void main() {
  testWidgets('English long break and task fit minimum mini size; expand works',
      (tester) async {
    tester.view.physicalSize = const Size(280, 160);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final clock = TestClock();
    final engine = PomodoroEngine(
        clock: clock,
        settings: const SettingsState(sessionsBeforeLongBreak: 1));
    engine.setTaskName('A very long name for the current task');
    engine.start();
    clock.advance(const Duration(minutes: 25));
    engine.tick();
    var expanded = false;
    await tester.pumpWidget(ProviderScope(
        overrides: [
          pomodoroNotifierProvider.overrideWith((ref) => TimerNotifier(
              engine, NoTray(), UnsupportedFocusModeController(), () => false)),
        ],
        child: MaterialApp(
          theme:
              AppTheme.light(null, AppTheme.defaultSeedColor, fontScale: 1.5),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MiniTimerView(onExpand: () => expanded = true),
        )));
    await tester.pumpAndSettle();
    expect(find.text('15:00'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byIcon(Icons.open_in_full));
    expect(expanded, isTrue);
  });
}
