import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro_focus/core/updates/update_restart.dart';

void main() {
  test(
    'restart helper waits for old process to exit before launching replacement',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'pomodoro-restart-test-',
      );
      try {
        final marker = File('${directory.path}/started');
        final replacement = File('${directory.path}/replacement.sh');
        await replacement.writeAsString(
          '#!/bin/sh\nprintf ready > "\$OUTPUT_MARKER"\n',
        );
        await Process.run('chmod', ['700', replacement.path]);
        final old = await Process.start('sleep', ['0.5']);
        final helper = await Process.start(
          '/bin/sh',
          [
            '-c',
            updateRestartWaitScript,
            'test-restart',
            old.pid.toString(),
            replacement.path,
          ],
          environment: {'OUTPUT_MARKER': marker.path},
        );
        expect(await marker.exists(), isFalse);
        await old.exitCode;
        expect(await helper.exitCode.timeout(const Duration(seconds: 5)), 0);
        expect(await marker.readAsString(), 'ready');
      } finally {
        await directory.delete(recursive: true);
      }
    },
  );
}
