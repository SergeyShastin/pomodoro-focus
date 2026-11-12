import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pomodoro_focus/core/dnd/focus_mode_provider.dart';
import 'package:pomodoro_focus/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/desktop/linux_screen_power_service.dart';
import 'settings_provider.dart';
import 'goal_setting_tile.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final dndController = ref.watch(focusModeControllerProvider);

    final isAndroid = !kIsWeb && Platform.isAndroid;
    final isLinux = !kIsWeb && Platform.isLinux;
    final screenPowerAvailable = isLinux &&
        (ref.watch(screenPowerAvailableProvider).valueOrNull ?? false);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Appearance Section
          _buildSectionHeader(
              context, l10n.appearanceSettings, Icons.palette_outlined),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: Text(l10n.themeMode),
                  subtitle: Text(_getThemeName(l10n, settings.themeMode)),
                  trailing: SegmentedButton<AppThemeMode>(
                    segments: [
                      const ButtonSegment(
                        value: AppThemeMode.system,
                        icon: Icon(Icons.brightness_auto, size: 18),
                      ),
                      const ButtonSegment(
                        value: AppThemeMode.light,
                        icon: Icon(Icons.light_mode, size: 18),
                      ),
                      const ButtonSegment(
                        value: AppThemeMode.dark,
                        icon: Icon(Icons.dark_mode, size: 18),
                      ),
                      const ButtonSegment(
                        value: AppThemeMode.oled,
                        icon: Icon(Icons.contrast, size: 18),
                      ),
                    ],
                    selected: {settings.themeMode},
                    onSelectionChanged: (modes) {
                      notifier.setThemeMode(modes.first);
                    },
                  ),
                ),
                SwitchListTile(
                  title: Text(l10n.dynamicColor),
                  value: settings.useDynamicColor,
                  onChanged: (val) => notifier.setUseDynamicColor(val),
                ),
                ListTile(
                  title: Text(l10n.fontSize),
                  subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.fontSizeHint),
                        Slider(
                            value: settings.fontScale,
                            min: 1,
                            max: 1.5,
                            divisions: 10,
                            label: '${(settings.fontScale * 100).round()}%',
                            onChanged: notifier.setFontScale),
                      ]),
                  trailing: Text('${(settings.fontScale * 100).round()}%'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _buildSectionHeader(context, l10n.goalsSettings, Icons.flag_outlined),
          Card(
              child: Column(children: [
            GoalSettingTile(
                title: l10n.dailyGoal,
                value: settings.dailyGoalPomodoros,
                maximum: 1440,
                onChanged: notifier.setDailyGoal),
            const Divider(height: 1),
            GoalSettingTile(
                title: l10n.weeklyGoal,
                value: settings.weeklyGoalPomodoros,
                maximum: 10080,
                onChanged: notifier.setWeeklyGoal),
            Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(l10n.calendarWeek,
                    style: Theme.of(context).textTheme.bodyMedium)),
          ])),
          const SizedBox(height: 16),

          // Timer Durations Section
          _buildSectionHeader(
              context, l10n.timerSettings, Icons.timer_outlined),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: Text(
                      l10n.workDurationMinutes(settings.workDurationMinutes)),
                  subtitle: Slider(
                    value: settings.workDurationMinutes.toDouble(),
                    min: 5,
                    max: 60,
                    divisions: 11,
                    label: '${settings.workDurationMinutes} m',
                    onChanged: (val) => notifier.setWorkDuration(val.round()),
                  ),
                ),
                ListTile(
                  title: Text(l10n.shortBreakDurationMinutes(
                      settings.shortBreakDurationMinutes)),
                  subtitle: Slider(
                    value: settings.shortBreakDurationMinutes.toDouble(),
                    min: 1,
                    max: 15,
                    divisions: 14,
                    label: '${settings.shortBreakDurationMinutes} m',
                    onChanged: (val) =>
                        notifier.setShortBreakDuration(val.round()),
                  ),
                ),
                ListTile(
                  title: Text(l10n.longBreakDurationMinutes(
                      settings.longBreakDurationMinutes)),
                  subtitle: Slider(
                    value: settings.longBreakDurationMinutes.toDouble(),
                    min: 5,
                    max: 45,
                    divisions: 8,
                    label: '${settings.longBreakDurationMinutes} m',
                    onChanged: (val) =>
                        notifier.setLongBreakDuration(val.round()),
                  ),
                ),
                ListTile(
                  title: Text(l10n.sessionsBeforeLongBreak(
                      settings.sessionsBeforeLongBreak)),
                  subtitle: Slider(
                    value: settings.sessionsBeforeLongBreak.toDouble(),
                    min: 2,
                    max: 8,
                    divisions: 6,
                    label: '${settings.sessionsBeforeLongBreak}',
                    onChanged: (val) =>
                        notifier.setSessionsBeforeLongBreak(val.round()),
                  ),
                ),
                SwitchListTile(
                  title: Text(l10n.autoStartBreaks),
                  value: settings.autoStartBreaks,
                  onChanged: (val) => notifier.setAutoStartBreaks(val),
                ),
                SwitchListTile(
                  title: Text(l10n.autoStartPomodoros),
                  value: settings.autoStartPomodoros,
                  onChanged: (val) => notifier.setAutoStartPomodoros(val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Focus / DND Section
          _buildSectionHeader(
              context, l10n.dndSettings, Icons.do_not_disturb_on_outlined),
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  title: Text(l10n.enableDndDuringWork),
                  subtitle: Text(
                    isAndroid
                        ? l10n.dndAndroidPermissionNeeded
                        : (isLinux ? l10n.dndKdeDescription : ''),
                  ),
                  value: settings.enableDndDuringWork,
                  onChanged: (val) => notifier.setEnableDnd(val),
                ),
                if (isLinux)
                  SwitchListTile(
                    title: Text(l10n.turnOffScreenOnBreak),
                    subtitle: Text(screenPowerAvailable
                        ? l10n.turnOffScreenOnBreakDescription
                        : l10n.screenPowerUnavailable),
                    value: settings.turnOffScreenOnBreak,
                    onChanged: screenPowerAvailable
                        ? notifier.setTurnOffScreenOnBreak
                        : null,
                  ),
                if (isAndroid)
                  Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 12),
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.admin_panel_settings_outlined,
                          size: 18),
                      label: Text(l10n.grantPermission),
                      onPressed: () => dndController.requestPermission(),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Notifications & Audio Section
          _buildSectionHeader(context, l10n.soundAndNotifications,
              Icons.notifications_active_outlined),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(l10n.enableNotifications),
                  value: settings.enableNotifications,
                  onChanged: (val) => notifier.setEnableNotifications(val),
                ),
                SwitchListTile(
                  title: Text(l10n.enableSound),
                  value: settings.enableSound,
                  onChanged: (val) => notifier.setEnableSound(val),
                ),
              ],
            ),
          ),
          if (!kIsWeb &&
              (Platform.isLinux || Platform.isWindows || Platform.isMacOS))
            SwitchListTile(
              title: Text(l10n.minimizeToTrayOnClose),
              value: settings.minimizeToTrayOnClose,
              onChanged: notifier.setMinimizeToTrayOnClose,
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
              child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          )),
        ],
      ),
    );
  }

  String _getThemeName(AppLocalizations l10n, AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system:
        return l10n.themeSystem;
      case AppThemeMode.light:
        return l10n.themeLight;
      case AppThemeMode.dark:
        return l10n.themeDark;
      case AppThemeMode.oled:
        return l10n.themeOled;
    }
  }
}
