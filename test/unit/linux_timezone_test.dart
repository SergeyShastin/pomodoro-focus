import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro_focus/core/time/linux_timezone.dart';
import 'package:timezone/data/latest_all.dart' as data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  late Directory root;
  setUp(() async {
    data.initializeTimeZones();
    root = await Directory.systemTemp.createTemp('focus_timezone_');
  });
  tearDown(() => root.delete(recursive: true));

  Future<tz.Location> resolve([Map<String, String> environment = const {}]) =>
      linuxLocalLocation(
        environment: environment,
        localtimePath: '${root.path}/localtime',
        timezonePath: '${root.path}/timezone',
      );

  test('TZ overrides system configuration and preserves DST', () async {
    await File('${root.path}/timezone').writeAsString('Asia/Tokyo');
    final location = await resolve({'TZ': ':Europe/Kyiv'});
    expect(location.name, 'Europe/Kyiv');
    expect(tz.TZDateTime(location, 2026, 1).timeZoneOffset,
        const Duration(hours: 2));
    expect(tz.TZDateTime(location, 2026, 7).timeZoneOffset,
        const Duration(hours: 3));
  });

  test('resolves localtime symlink before stale text configuration', () async {
    final target = File('${root.path}/zoneinfo/Europe/Berlin');
    await target.create(recursive: true);
    await Link('${root.path}/localtime').create(target.path);
    await File('${root.path}/timezone').writeAsString('Asia/Tokyo');
    expect((await resolve()).name, 'Europe/Berlin');
  });

  test('invalid TZ and absent symlink fall back to timezone file', () async {
    await File('${root.path}/timezone').writeAsString('Europe/Kyiv\n');
    expect((await resolve({'TZ': 'invalid'})).name, 'Europe/Kyiv');
  });

  test('missing configuration reports failure', () async {
    await expectLater(resolve(), throwsStateError);
  });
}
