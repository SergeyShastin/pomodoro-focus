import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro_focus/core/desktop/linux_screen_power_service.dart';
import 'package:pomodoro_focus/features/settings/data/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('availability checks DPMS without changing display power', () async {
    final calls = <List<String>>[];
    final service = LinuxScreenPowerService(
        supported: true,
        runCommand: (args) async {
          calls.add(args);
          return ProcessResult(0, 0, 'dpms mode for screen eDP-1: on\n', '');
        });
    expect(await service.isAvailable(), isTrue);
    expect(calls, [
      ['--dpms', 'show']
    ]);
    await service.turnOff();
    expect(calls.last, ['--dpms', 'off']);
    await service.turnOn();
    expect(calls.last, ['--dpms', 'on']);
  });

  test('unsupported session makes no system calls', () async {
    final service = LinuxScreenPowerService(
        supported: false,
        runCommand: (_) async {
          fail('Must not invoke a command outside a supported session');
        });
    expect(await service.isAvailable(), isFalse);
    await service.turnOff();
    await service.turnOn();
  });

  test('missing command is unavailable, failure is reported to caller',
      () async {
    final service = LinuxScreenPowerService(
        supported: true,
        runCommand: (_) async {
          throw const ProcessException('kscreen-doctor', [], 'not installed');
        });
    expect(await service.isAvailable(), isFalse);
    await expectLater(service.turnOff(), throwsA(isA<ProcessException>()));
  });

  test('feature defaults off and preference survives saving', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repository = SettingsRepository(prefs);
    expect(repository.loadSettings().turnOffScreenOnBreak, isFalse);
    await repository.saveSettings(
        repository.loadSettings().copyWith(turnOffScreenOnBreak: true));
    expect(
        SettingsRepository(prefs).loadSettings().turnOffScreenOnBreak, isTrue);
  });
}
