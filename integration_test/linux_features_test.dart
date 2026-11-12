import 'dart:async';
import 'dart:convert';
import 'dart:ffi' show DynamicLibrary;
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:dbus/dbus.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pomodoro_focus/app.dart';
import 'package:pomodoro_focus/core/audio/audio_service.dart';
import 'package:pomodoro_focus/core/clock/app_clock.dart';
import 'package:pomodoro_focus/core/database/app_database.dart';
import 'package:pomodoro_focus/core/desktop/desktop_providers.dart';
import 'package:pomodoro_focus/core/dnd/focus_mode_provider.dart';
import 'package:pomodoro_focus/core/notifications/notification_service.dart';
import 'package:pomodoro_focus/features/settings/presentation/settings_provider.dart';
import 'package:pomodoro_focus/features/stats/presentation/stats_provider.dart';
import 'package:pomodoro_focus/features/timer/domain/pomodoro_phase.dart';
import 'package:pomodoro_focus/features/timer/presentation/timer_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/open.dart';
import 'package:window_manager/window_manager.dart';

// Check the compositor state, not just window_manager's cached boolean.
Future<bool> compositorKeepsAbove() async {
  final root = await Process.run('xprop', ['-root', '_NET_CLIENT_LIST']);
  for (final id
      in RegExp(r'0x[0-9a-fA-F]+').allMatches(root.stdout as String)) {
    final properties = await Process.run('xprop', [
      '-id',
      id.group(0)!,
      '_NET_WM_PID',
      '_NET_WM_STATE',
    ]);
    final text = properties.stdout as String;
    if (text.split('\n').contains('_NET_WM_PID(CARDINAL) = $pid')) {
      return text.contains('_NET_WM_STATE_ABOVE');
    }
  }
  throw StateError('Application XWayland window was not found');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized().framePolicy =
      LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets(
      'Linux timer, KDE DND, native mini window, bell, notification and SQLite',
      (tester) async {
    open.overrideFor(
        OperatingSystem.linux, () => DynamicLibrary.open('libsqlite3.so.0'));
    await windowManager.ensureInitialized();
    await windowManager.waitUntilReadyToShow(
        const WindowOptions(
          size: Size(920, 700),
          minimumSize: Size(380, 500),
        ), () async {
      await windowManager.show();
    });
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final clock = TestClock(DateTime.now());
    final database = AppDatabase(NativeDatabase.memory());
    final player = AudioPlayer();
    final audio = AudioService(player);
    final finishedSound = Completer<void>();
    final subscription = player.onPlayerComplete.listen((_) {
      if (!finishedSound.isCompleted) finishedSound.complete();
    });
    final bus = DBusClient.session();
    final notifications = DBusRemoteObject(bus,
        name: 'org.freedesktop.Notifications',
        path: DBusObjectPath('/org/freedesktop/Notifications'));
    Future<bool> inhibited() async => (await notifications.getProperty(
            'org.freedesktop.Notifications', 'Inhibited') as DBusBoolean)
        .value;
    final baseline = await inhibited();
    final monitor = await Process.start('dbus-monitor', [
      '--session',
      "type='method_call',interface='org.freedesktop.Notifications',member='Notify'"
    ]);
    final notificationLog = StringBuffer();
    final monitorOut =
        monitor.stdout.transform(utf8.decoder).listen(notificationLog.write);
    final monitorErr = monitor.stderr.drain<void>();
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(clock),
      appDatabaseProvider.overrideWithValue(database),
      audioServiceProvider.overrideWithValue(audio),
    ]);
    addTearDown(() async {
      await container.read(focusModeControllerProvider).disable();
      await container.read(notificationServiceProvider).cancelAll();
      await container.read(trayServiceProvider).destroy();
      container.dispose();
      await subscription.cancel();
      await audio.dispose();
      await database.close();
      await bus.close();
      monitor.kill();
      await monitor.exitCode;
      await monitorOut.cancel();
      await monitorErr;
    });
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container, child: const PomodoroApp()));
    await tester.pumpAndSettle();
    // Observe real backend completion rather than relying on swallowed plugin errors.
    await container.read(notificationServiceProvider).initialize();
    final notifier = container.read(pomodoroNotifierProvider.notifier);
    notifier.setTaskName('Linux verification');
    notifier.start();
    await tester.pump(const Duration(milliseconds: 500));
    await container.read(focusModeControllerProvider).enable();
    expect(await inhibited(), isTrue);
    notifier.pause();
    await container.read(focusModeControllerProvider).disable();
    expect(await inhibited(), baseline);

    // Settings changes must keep the paused timer and task.
    await container.read(settingsProvider.notifier).setEnableSound(false);
    expect(container.read(pomodoroNotifierProvider).isPaused, isTrue);
    await container.read(settingsProvider.notifier).setEnableSound(true);
    final bounds = await windowManager.getBounds();
    await tester.tap(find.byIcon(Icons.picture_in_picture_alt_outlined));
    for (var i = 0; i < 100 && !container.read(isMiniModeProvider); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(container.read(isMiniModeProvider), isTrue);
    // Native configure events are asynchronous and independent of Flutter frames.
    await Future<void>.delayed(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    final miniBounds = await windowManager.getBounds();
    expect(miniBounds.width, lessThan(bounds.width));
    expect(miniBounds.height, lessThan(bounds.height));
    expect(await windowManager.isAlwaysOnTop(), isTrue);
    expect(await compositorKeepsAbove(), isTrue);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byIcon(Icons.open_in_full));
    for (var i = 0; i < 100 && container.read(isMiniModeProvider); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(container.read(isMiniModeProvider), isFalse);
    expect(await windowManager.isAlwaysOnTop(), isFalse);
    expect(await compositorKeepsAbove(), isFalse);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    final restored = await windowManager.getBounds();
    expect(restored.width, closeTo(bounds.width, 2));
    expect(restored.height, closeTo(bounds.height, 2));

    // Resume and emulate waking just after the deadline, without waiting 25 min.
    notifier.start();
    final deadline = container.read(pomodoroNotifierProvider).targetEndTime!;
    await windowManager.close();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(await windowManager.isVisible(), isFalse);
    expect(container.read(pomodoroNotifierProvider).isRunning, isTrue);
    await windowManager.show();
    await windowManager.focus();
    clock.advance(const Duration(minutes: 26));
    await tester.pump(const Duration(seconds: 1));
    await finishedSound.future.timeout(const Duration(seconds: 15));
    await tester.pumpAndSettle();
    expect(container.read(pomodoroNotifierProvider).phase,
        PomodoroPhase.shortBreak);
    expect(await inhibited(), baseline);
    final sessions = await container
        .read(statsRepositoryProvider)
        .watchRecentSessions()
        .first;
    expect(sessions.single.taskName, 'Linux verification');
    expect(sessions.single.durationMinutes, 25);
    // SQLite timestamps have second precision.
    expect(sessions.single.endTime.difference(deadline).inSeconds.abs(),
        lessThanOrEqualTo(1));
    final summary = await container.read(statsSummaryProvider.future);
    expect(summary.todayPomodoros, 1);
    expect(summary.todayMinutes, 25);
    expect(notificationLog.toString(), contains('Focus session completed!'));
    expect(notificationLog.toString(), contains('suppress-sound'));
    expect(notificationLog.toString(), contains('assets/icons/app_icon.png'));
    // Removing the artificial session is unnecessary: its DB is in memory.
    await tester.pumpWidget(const SizedBox.shrink());
  }, skip: !Platform.isLinux);
}
