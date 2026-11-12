import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Uses Plasma's Wayland DPMS command, without locking or suspending the session.
class LinuxScreenPowerService {
  final Future<ProcessResult> Function(List<String>) _runCommand;
  final bool isSupported;

  LinuxScreenPowerService({
    Future<ProcessResult> Function(List<String>)? runCommand,
    bool? supported,
  })  : _runCommand = runCommand ?? _run,
        isSupported = supported ??
            (Platform.isLinux &&
                Platform.environment.containsKey('WAYLAND_DISPLAY') &&
                (Platform.environment['XDG_CURRENT_DESKTOP'] ?? '')
                    .toUpperCase()
                    .contains('KDE'));

  static Future<ProcessResult> _run(List<String> arguments) => Process.run(
        'kscreen-doctor', arguments,
        // The Flutter window can use XWayland, but DPMS needs native Wayland.
        environment: const {'QT_QPA_PLATFORM': 'wayland'},
      ).timeout(const Duration(seconds: 5));

  Future<bool> isAvailable() async {
    if (!isSupported) return false;
    try {
      final result = await _runCommand(const ['--dpms', 'show']);
      return result.exitCode == 0 &&
          result.stdout.toString().contains('dpms mode for screen');
    } on Object {
      return false;
    }
  }

  Future<void> turnOff() => _setMode('off');

  Future<void> turnOn() => _setMode('on');

  Future<void> _setMode(String mode) async {
    if (!isSupported) return;
    final result = await _runCommand(['--dpms', mode]);
    if (result.exitCode != 0) {
      throw ProcessException('kscreen-doctor', ['--dpms', mode],
          result.stderr.toString(), result.exitCode);
    }
  }
}

final linuxScreenPowerServiceProvider = Provider<LinuxScreenPowerService>(
  (ref) => LinuxScreenPowerService(),
);

final screenPowerAvailableProvider = FutureProvider<bool>(
  (ref) => ref.watch(linuxScreenPowerServiceProvider).isAvailable(),
);
