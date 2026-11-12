import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/open.dart';
import 'package:window_manager/window_manager.dart';
import 'app.dart';
import 'features/settings/presentation/settings_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Linux SQLite dynamic library fallback
  if (!kIsWeb && Platform.isLinux) {
    try {
      open.overrideFor(
        OperatingSystem.linux,
        () => ffi.DynamicLibrary.open('libsqlite3.so.0'),
      );
    } catch (_) {}
  }

  // Desktop window manager initialization
  if (!kIsWeb && (Platform.isLinux || Platform.isMacOS || Platform.isWindows)) {
    try {
      await windowManager.ensureInitialized();
      final windowOptions = const WindowOptions(
        size: Size(920, 700),
        minimumSize: Size(380, 500),
        center: true,
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.normal,
        title: 'Pomodoro Focus',
      );
      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });
    } catch (e) {
      debugPrint('Window manager initialization failed: $e');
    }
  }

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const PomodoroApp(),
    ),
  );
}
