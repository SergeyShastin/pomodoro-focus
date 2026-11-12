import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

class DesktopWindowService with WindowListener {
  final SharedPreferences _prefs;
  final Future<void> Function()? beforeExit;
  bool _changingBounds = false;
  bool _isMiniMode = false;
  Rect? _lastNormalBounds;
  bool _minimizeToTrayOnClose = true;

  DesktopWindowService(this._prefs, {this.beforeExit});

  static const _keyWindowX = 'window_pos_x';
  static const _keyWindowY = 'window_pos_y';
  static const _keyWindowWidth = 'window_width';
  static const _keyWindowHeight = 'window_height';

  bool get isMiniMode => _isMiniMode;
  bool get isDesktop =>
      !kIsWeb && (Platform.isLinux || Platform.isMacOS || Platform.isWindows);

  Future<void> initialize({bool minimizeToTrayOnClose = true}) async {
    if (!isDesktop) return;

    _minimizeToTrayOnClose = minimizeToTrayOnClose;
    windowManager.addListener(this);

    try {
      await windowManager.setPreventClose(true);

      // Restore saved bounds if available
      final w = _prefs.getDouble(_keyWindowWidth);
      final h = _prefs.getDouble(_keyWindowHeight);
      final x = _prefs.getDouble(_keyWindowX);
      final y = _prefs.getDouble(_keyWindowY);

      if (w != null && h != null) {
        await windowManager.setSize(Size(w, h));
      }
      if (x != null && y != null) {
        await windowManager.setPosition(Offset(x, y));
      }
    } catch (e) {
      debugPrint('DesktopWindowService init error: $e');
    }
  }

  Future<bool> toggleMiniMode(bool enable) async {
    if (!isDesktop) return false;
    if (_isMiniMode == enable) return true;
    _changingBounds = true;

    try {
      if (enable) {
        _lastNormalBounds = await windowManager.getBounds();
        await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
        await windowManager.setMinimumSize(const Size(280, 160));
        await windowManager.setSize(const Size(320, 180));
        await windowManager.setAlwaysOnTop(true);
      } else {
        await windowManager.setAlwaysOnTop(false);
        await windowManager.setTitleBarStyle(TitleBarStyle.normal);
        await windowManager.setMinimumSize(const Size(380, 500));
        if (_lastNormalBounds != null) {
          await windowManager.setBounds(_lastNormalBounds!);
        } else {
          await windowManager.setSize(const Size(920, 700));
        }
      }
      _isMiniMode = enable;
      return true;
    } catch (e) {
      debugPrint('Failed to toggle mini mode: $e');
      return false;
    } finally {
      _changingBounds = false;
    }
  }

  Future<void> saveCurrentBounds() async {
    if (!isDesktop || _isMiniMode || _changingBounds) return;

    try {
      final bounds = await windowManager.getBounds();
      await Future.wait([
        _prefs.setDouble(_keyWindowWidth, bounds.width),
        _prefs.setDouble(_keyWindowHeight, bounds.height),
        _prefs.setDouble(_keyWindowX, bounds.left),
        _prefs.setDouble(_keyWindowY, bounds.top),
      ]);
    } catch (e) {
      debugPrint('Failed to save window bounds: $e');
    }
  }

  @override
  void onWindowMoved() {
    saveCurrentBounds();
  }

  @override
  void onWindowResized() {
    saveCurrentBounds();
  }

  void setMinimizeToTrayOnClose(bool value) {
    _minimizeToTrayOnClose = value;
  }

  Future<void> quit() async {
    await beforeExit?.call();
    await saveCurrentBounds();
    await windowManager.destroy();
  }

  @override
  Future<void> onWindowClose() async {
    if (_minimizeToTrayOnClose) {
      await windowManager.hide();
    } else {
      await quit();
    }
  }

  void dispose() {
    if (isDesktop) {
      windowManager.removeListener(this);
    }
  }
}
