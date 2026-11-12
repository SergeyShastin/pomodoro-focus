import 'dart:async';
import 'dart:io';
import 'package:dbus/dbus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro_focus/core/updates/packagekit_installer.dart';
import 'package:pomodoro_focus/core/updates/update_service.dart';

class Manager extends DBusObject {
  Manager() : super(DBusObjectPath('/org/freedesktop/PackageKit'));
  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall call) async =>
      call.name == 'CreateTransaction'
      ? DBusMethodSuccessResponse([DBusObjectPath('/transaction/test')])
      : DBusMethodErrorResponse.unknownMethod();
}

class Transaction extends DBusObject {
  final bool fail, hang;
  final calls = <String>[];
  List<String>? filenames;
  Transaction({this.fail = false, this.hang = false})
    : super(DBusObjectPath('/transaction/test'));
  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall call) async {
    calls.add(call.name);
    if (call.name == 'InstallFiles') {
      expect(call.values.first.asUint64(), 0);
      filenames = call.values.last.asStringArray().toList();
      if (!hang) {
        scheduleMicrotask(() async {
          if (fail) {
            await emitSignal(
              'org.freedesktop.PackageKit.Transaction',
              'ErrorCode',
              [const DBusUint32(2), const DBusString('cancelled')],
            );
          }
          await emitSignal(
            'org.freedesktop.PackageKit.Transaction',
            'Finished',
            [DBusUint32(fail ? 2 : 1), const DBusUint32(1)],
          );
        });
      }
    }
    return DBusMethodSuccessResponse([]);
  }
}

void main() {
  for (final outcome in ['success', 'denied', 'timeout']) {
    test(
      'PackageKit $outcome: isolated bus, exact local file and completed transaction',
      () async {
        final result = await Process.run('dbus-daemon', [
          '--session',
          '--fork',
          '--print-address=1',
          '--print-pid=1',
        ]);
        expect(result.exitCode, 0);
        final lines = result.stdout.toString().trim().split('\n');
        final address = DBusAddress(lines.first);
        final daemonPid = int.parse(lines.last);
        final service = DBusClient(address);
        try {
          await service.requestName('org.freedesktop.PackageKit');
          final transaction = Transaction(
            fail: outcome == 'denied',
            hang: outcome == 'timeout',
          );
          await service.registerObject(Manager());
          await service.registerObject(transaction);
          final installer = PackageKitInstaller(
            createClient: () => DBusClient(address),
            timeout: outcome == 'timeout'
                ? const Duration(milliseconds: 100)
                : const Duration(seconds: 5),
          );
          final action = installer.install(File('/tmp/local package.deb'));
          if (outcome == 'success') {
            await action;
          } else {
            await expectLater(action, throwsA(isA<UpdateException>()));
          }
          expect(transaction.filenames, ['/tmp/local package.deb']);
          expect(transaction.calls.take(2).toList(), [
            'SetHints',
            'InstallFiles',
          ]);
          expect(transaction.calls.contains('Cancel'), outcome == 'timeout');
        } finally {
          await service.close();
          Process.killPid(daemonPid);
        }
      },
    );
  }
}
