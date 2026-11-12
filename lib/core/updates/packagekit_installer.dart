import 'dart:async';
import 'dart:io';
import 'package:dbus/dbus.dart';
import 'update_service.dart';

/// Uses the desktop's authorization agent; never receives a password.
class PackageKitInstaller {
  final DBusClient Function() createClient;
  final Duration timeout;
  PackageKitInstaller({
    DBusClient Function()? createClient,
    this.timeout = const Duration(minutes: 20),
  }) : createClient = createClient ?? DBusClient.system;

  Future<void> install(File file) async {
    final client = createClient();
    final subscriptions = <StreamSubscription<dynamic>>[];
    DBusRemoteObject? transaction;
    var finished = false;
    try {
      final manager = DBusRemoteObject(
        client,
        name: 'org.freedesktop.PackageKit',
        path: DBusObjectPath('/org/freedesktop/PackageKit'),
      );
      final response = await manager
          .callMethod(
            'org.freedesktop.PackageKit',
            'CreateTransaction',
            [],
            replySignature: DBusSignature('o'),
          )
          .timeout(const Duration(seconds: 20));
      transaction = DBusRemoteObject(
        client,
        name: 'org.freedesktop.PackageKit',
        path: response.values.single.asObjectPath(),
      );
      final result = Completer<bool>();
      var failed = false;
      subscriptions.add(
        DBusRemoteObjectSignalStream(
          object: transaction,
          interface: 'org.freedesktop.PackageKit.Transaction',
          name: 'ErrorCode',
          signature: DBusSignature('us'),
        ).listen(
          (_) => failed = true,
          onError: (Object _) {
            if (!result.isCompleted) result.complete(false);
          },
        ),
      );
      subscriptions.add(
        DBusRemoteObjectSignalStream(
          object: transaction,
          interface: 'org.freedesktop.PackageKit.Transaction',
          name: 'Finished',
          signature: DBusSignature('uu'),
        ).listen(
          (signal) {
            finished = true;
            if (!result.isCompleted) {
              result.complete(!failed && signal.values.first.asUint32() == 1);
            }
          },
          onError: (Object _) {
            if (!result.isCompleted) result.complete(false);
          },
        ),
      );
      // This round trip also establishes signal subscriptions before InstallFiles.
      await transaction.callMethod(
        'org.freedesktop.PackageKit.Transaction',
        'SetHints',
        [
          DBusArray.string(['interactive=true', 'background=false']),
        ],
      );
      await transaction
          .callMethod(
            'org.freedesktop.PackageKit.Transaction',
            'InstallFiles',
            [
              const DBusUint64(0),
              DBusArray.string([file.absolute.path]),
            ],
            allowInteractiveAuthorization: true,
          )
          .timeout(timeout);
      if (!await result.future.timeout(timeout)) {
        throw const UpdateException(UpdateFailure.installation);
      }
    } catch (_) {
      throw const UpdateException(UpdateFailure.installation);
    } finally {
      if (!finished && transaction != null) {
        try {
          await transaction
              .callMethod(
                'org.freedesktop.PackageKit.Transaction',
                'Cancel',
                [],
              )
              .timeout(const Duration(seconds: 5));
        } catch (_) {}
      }
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
      await client.close();
    }
  }
}
