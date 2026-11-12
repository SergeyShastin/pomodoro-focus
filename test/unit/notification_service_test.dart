import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pomodoro_focus/core/notifications/notification_service.dart';

class Plugin extends Mock implements FlutterLocalNotificationsPlugin {}

void main() {
  setUpAll(() {
    registerFallbackValue(const InitializationSettings());
    registerFallbackValue(const NotificationDetails());
  });
  test(
      'concurrent first notifications await one initialization and never play system sound',
      () async {
    final plugin = Plugin();
    final initialized = Completer<bool>();
    when(() => plugin.initialize(any(),
            onDidReceiveNotificationResponse:
                any(named: 'onDidReceiveNotificationResponse')))
        .thenAnswer((_) => initialized.future);
    when(() => plugin.show(any(), any(), any(), any(),
        payload: any(named: 'payload'))).thenAnswer((_) async {});
    final service = NotificationService(plugin);
    final first = service.showNotification(title: 'First', body: 'One');
    final second = service.showNotification(title: 'Second', body: 'Two');
    verifyNever(() => plugin.show(any(), any(), any(), any(),
        payload: any(named: 'payload')));
    initialized.complete(true);
    await Future.wait([first, second]);
    final initialization = verify(() => plugin.initialize(captureAny(),
            onDidReceiveNotificationResponse:
                any(named: 'onDidReceiveNotificationResponse'))).captured.single
        as InitializationSettings;
    expect((initialization.linux!.defaultIcon as AssetsLinuxIcon).relativePath,
        'assets/icons/app_icon.png');
    final details = verify(() => plugin.show(any(), any(), any(), captureAny(),
        payload: any(named: 'payload'))).captured.cast<NotificationDetails>();
    expect(details.length, 2);
    for (final detail in details) {
      expect(detail.linux!.suppressSound, isTrue);
      expect(detail.android!.playSound, isFalse);
      expect(detail.iOS!.presentSound, isFalse);
    }
  });
}
