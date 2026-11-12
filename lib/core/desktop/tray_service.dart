import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import '../../features/timer/domain/pomodoro_phase.dart';
import '../../features/timer/domain/pomodoro_timer_state.dart';

class TrayService with TrayListener {
  bool _initialized = false;
  Future<void>? _initialization;
  bool _isRunning = false;
  String? _lastStatus;
  void Function()? onStart;
  void Function()? onPause;
  void Function()? onSkip;
  void Function()? onReset;
  final Future<void> Function()? onQuit;

  TrayService({
    this.onStart,
    this.onPause,
    this.onSkip,
    this.onReset,
    this.onQuit,
  });

  bool get isDesktop =>
      !kIsWeb && (Platform.isLinux || Platform.isMacOS || Platform.isWindows);

  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    if (!isDesktop || _initialized) return;

    try {
      trayManager.addListener(this);

      final iconPath = Platform.isWindows
          ? 'assets/icons/tray_icon.ico'
          : 'assets/icons/tray_icon.png';

      await trayManager.setIcon(iconPath);
      if (!Platform.isLinux) {
        await trayManager.setToolTip('Pomodoro Focus');
      }

      _initialized = true;
    } catch (e) {
      debugPrint('TrayService init error: $e');
    }
  }

  Future<void> updateTray(PomodoroTimerState state) async {
    if (!isDesktop) return;
    await initialize();
    if (!_initialized) return;
    _isRunning = state.isRunning;

    try {
      final phaseStr = state.phase == PomodoroPhase.work
          ? 'Focus'
          : (state.phase == PomodoroPhase.shortBreak
              ? 'Short Break'
              : 'Long Break');

      final title = '$phaseStr: ${state.formattedTime}';
      // AppIndicator on Linux supports labels, but not setToolTip.
      final status = '$title/${state.isRunning}/${state.isPaused}';
      if (_lastStatus == status) return;
      if (Platform.isLinux) {
        await trayManager.setTitle(title);
      } else {
        await trayManager.setToolTip(title);
      }

      final playPauseLabel =
          state.isRunning ? 'Pause' : (state.isPaused ? 'Resume' : 'Start');

      final menu = Menu(
        items: [
          MenuItem(
            key: 'status',
            label: title,
            disabled: true,
          ),
          MenuItem.separator(),
          MenuItem(
            key: 'toggle_play',
            label: playPauseLabel,
          ),
          MenuItem(
            key: 'skip',
            label: 'Skip',
          ),
          MenuItem(
            key: 'reset',
            label: 'Reset',
          ),
          MenuItem.separator(),
          MenuItem(
            key: 'show_window',
            label: 'Show Window',
          ),
          MenuItem(
            key: 'quit',
            label: 'Quit',
          ),
        ],
      );

      await trayManager.setContextMenu(menu);
      _lastStatus = status;
    } catch (e) {
      debugPrint('Tray update error: $e');
    }
  }

  @override
  void onTrayIconMouseDown() {
    _showOrRestoreWindow();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'toggle_play':
        if (_isRunning) {
          onPause?.call();
        } else {
          onStart?.call();
        }
        break;
      case 'skip':
        onSkip?.call();
        break;
      case 'reset':
        onReset?.call();
        break;
      case 'show_window':
        _showOrRestoreWindow();
        break;
      case 'quit':
        _quit();
    }
  }

  Future<void> _showOrRestoreWindow() async {
    try {
      final isVisible = await windowManager.isVisible();
      if (!isVisible) {
        await windowManager.show();
      }
      await windowManager.focus();
    } catch (e) {
      debugPrint('Failed to show window from tray: $e');
    }
  }

  Future<void> _quit() async {
    if (onQuit != null) {
      await onQuit!();
    } else {
      await destroy();
      await windowManager.destroy();
    }
  }

  Future<void> destroy() async {
    if (!isDesktop || !_initialized) return;
    await trayManager.destroy();
    _initialized = false;
  }

  void dispose() {
    if (isDesktop) {
      trayManager.removeListener(this);
    }
  }
}
