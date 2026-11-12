import 'package:dbus/dbus.dart';
import 'package:flutter/foundation.dart';
import 'focus_mode_controller.dart';

class LinuxKdeFocusModeController implements FocusModeController {
  DBusClient? _client;
  int? _inhibitCookie;
  final DBusRemoteObject? _remoteObject;
  Future<void> _pending = Future.value();
  bool _disposed = false;

  LinuxKdeFocusModeController({DBusRemoteObject? remoteObject})
      : _remoteObject = remoteObject;

  Future<void> _serialize(Future<void> Function() action) {
    _pending = _pending.then((_) => action());
    return _pending;
  }

  DBusRemoteObject _getObject() =>
      _remoteObject ??
      DBusRemoteObject(
        _getClient(),
        name: 'org.freedesktop.Notifications',
        path: DBusObjectPath('/org/freedesktop/Notifications'),
      );

  @override
  bool get isSupported => true;

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<bool> requestPermission() async => true;

  DBusClient _getClient() {
    _client ??= DBusClient.session();
    return _client!;
  }

  @override
  Future<void> enable() => _serialize(_enable);

  Future<void> _enable() async {
    if (_disposed || _inhibitCookie != null) return;

    try {
      final object = _getObject();

      // Freedesktop Notifications Inhibit signature: (s desktop_entry, s reason, a{sv} hints) -> u
      final response = await object.callMethod(
        'org.freedesktop.Notifications',
        'Inhibit',
        [
          const DBusString('pomodoro_focus'),
          const DBusString('Focus session in progress'),
          DBusDict.stringVariant(const {}),
        ],
      );

      if (response.values.isNotEmpty && response.values.first is DBusUint32) {
        _inhibitCookie = (response.values.first as DBusUint32).value;
        debugPrint('KDE Notifications Inhibit active, cookie: $_inhibitCookie');
      }
    } catch (e) {
      debugPrint('KDE D-Bus Notifications Inhibit failed: $e');
    }
  }

  @override
  Future<void> disable() => _serialize(_disable);

  Future<void> _disable() async {
    final cookie = _inhibitCookie;
    if (cookie == null) return;

    try {
      final object = _getObject();

      await object.callMethod(
        'org.freedesktop.Notifications',
        'UnInhibit',
        [DBusUint32(cookie)],
      );
      _inhibitCookie = null;
      debugPrint('KDE Notifications UnInhibit released, cookie: $cookie');
    } catch (e) {
      debugPrint('KDE D-Bus Notifications UnInhibit failed: $e');
    }
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    await disable();
    try {
      await _client?.close();
    } catch (_) {}
    _client = null;
  }
}
