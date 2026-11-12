import 'dart:async';
import 'package:dbus/dbus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pomodoro_focus/core/dnd/linux_kde_focus_mode_controller.dart';

class Remote extends Mock implements DBusRemoteObject {}

void main() {
  setUpAll(() => registerFallbackValue(<DBusValue>[]));
  test('pause during pending Inhibit releases the returned cookie exactly once',
      () async {
    final remote = Remote();
    final reply = Completer<DBusMethodSuccessResponse>();
    when(() => remote.callMethod(any(), 'Inhibit', any()))
        .thenAnswer((_) => reply.future);
    when(() => remote.callMethod(any(), 'UnInhibit', any()))
        .thenAnswer((_) async => DBusMethodSuccessResponse([]));
    final controller = LinuxKdeFocusModeController(remoteObject: remote);
    final enable = controller.enable();
    await Future<void>.delayed(Duration.zero);
    final duplicate = controller.enable();
    final disable = controller.disable();
    reply.complete(DBusMethodSuccessResponse([const DBusUint32(42)]));
    await Future.wait([enable, duplicate, disable]);
    await controller.dispose();
    verify(() => remote.callMethod(any(), 'Inhibit', any())).called(1);
    final values =
        verify(() => remote.callMethod(any(), 'UnInhibit', captureAny()))
            .captured
            .single as Iterable<DBusValue>;
    expect(values, [const DBusUint32(42)]);
  });

  test('dispose during pending enable releases inhibitor and prevents reuse',
      () async {
    final remote = Remote();
    final reply = Completer<DBusMethodSuccessResponse>();
    when(() => remote.callMethod(any(), 'Inhibit', any()))
        .thenAnswer((_) => reply.future);
    when(() => remote.callMethod(any(), 'UnInhibit', any()))
        .thenAnswer((_) async => DBusMethodSuccessResponse([]));
    final controller = LinuxKdeFocusModeController(remoteObject: remote);
    final enable = controller.enable();
    await Future<void>.delayed(Duration.zero);
    final dispose = controller.dispose();
    reply.complete(DBusMethodSuccessResponse([const DBusUint32(99)]));
    await Future.wait([enable, dispose]);
    await controller.enable();
    verify(() => remote.callMethod(any(), 'Inhibit', any())).called(1);
    verify(() => remote.callMethod(any(), 'UnInhibit', any())).called(1);
  });
}
