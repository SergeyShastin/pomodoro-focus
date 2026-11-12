import 'core/updates/update_widgets.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pomodoro_focus/l10n/app_localizations.dart';
import 'core/desktop/desktop_providers.dart';
import 'core/presentation/adaptive_scaffold.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/presentation/settings_provider.dart';
import 'features/settings/presentation/settings_screen.dart';
import 'features/stats/presentation/stats_screen.dart';
import 'features/timer/presentation/timer_screen.dart';
import 'features/timer/presentation/widgets/mini_timer_view.dart';
import 'features/world_clock/presentation/world_clock_screen.dart';

class PomodoroApp extends ConsumerWidget {
  const PomodoroApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final isMiniMode = ref.watch(isMiniModeProvider);
    final windowService = ref.watch(desktopWindowServiceProvider);

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final useDynamic = settings.useDynamicColor;
        final lightScheme = useDynamic ? lightDynamic : null;
        final darkScheme = useDynamic ? darkDynamic : null;
        final seedColor = Color(settings.seedColorValue);

        final lightTheme = AppTheme.light(lightScheme, seedColor,
            fontScale: settings.fontScale);
        final darkTheme = settings.themeMode == AppThemeMode.oled
            ? AppTheme.oled(darkScheme, seedColor,
                fontScale: settings.fontScale)
            : AppTheme.dark(darkScheme, seedColor,
                fontScale: settings.fontScale);

        final ThemeMode materialThemeMode;
        switch (settings.themeMode) {
          case AppThemeMode.system:
            materialThemeMode = ThemeMode.system;
            break;
          case AppThemeMode.light:
            materialThemeMode = ThemeMode.light;
            break;
          case AppThemeMode.dark:
          case AppThemeMode.oled:
            materialThemeMode = ThemeMode.dark;
            break;
        }

        return MaterialApp(
          title: 'Pomodoro Focus',
          builder: (context, child) =>
              UpdateHost(compact: isMiniMode, child: child!),
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: materialThemeMode,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: isMiniMode
              ? MiniTimerView(
                  onExpand: () async {
                    final changed = await windowService.toggleMiniMode(false);
                    if (changed) {
                      ref.read(isMiniModeProvider.notifier).state = false;
                    }
                  },
                )
              : const MainNavigationShell(),
        );
      },
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    TimerScreen(),
    WorldClockScreen(),
    StatsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      selectedIndex: _currentIndex,
      onDestinationSelected: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      destinations: [
        AdaptiveDestination(
          icon: Icons.timer_outlined,
          selectedIcon: Icons.timer,
          labelBuilder: (l10n) => l10n.timerTab,
        ),
        AdaptiveDestination(
          icon: Icons.public_outlined,
          selectedIcon: Icons.public,
          labelBuilder: (l10n) => l10n.worldClockTab,
        ),
        AdaptiveDestination(
          icon: Icons.bar_chart_outlined,
          selectedIcon: Icons.bar_chart,
          labelBuilder: (l10n) => l10n.statsTab,
        ),
        AdaptiveDestination(
          icon: Icons.settings_outlined,
          selectedIcon: Icons.settings,
          labelBuilder: (l10n) => l10n.settingsTab,
        ),
      ],
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
    );
  }
}
