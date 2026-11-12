import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro_focus/features/world_clock/domain/world_clock_city.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(() {
    tz.initializeTimeZones();
  });

  test('WorldClockCity calculates accurate time and day/night state', () {
    const tokyo = WorldClockCity(
      id: 'tokyo',
      name: 'Tokyo',
      timezone: 'Asia/Tokyo',
    );

    // 03:00 UTC is 12:00 in Tokyo (UTC+9) -> Day time
    final utcMiddayInTokyo = DateTime.utc(2026, 6, 1, 3, 0, 0);
    expect(tokyo.formattedTime(utcMiddayInTokyo), '12:00:00');
    expect(tokyo.isDay(utcMiddayInTokyo), true);

    // 14:00 UTC is 23:00 in Tokyo (UTC+9) -> Night time
    final utcNightInTokyo = DateTime.utc(2026, 6, 1, 14, 0, 0);
    expect(tokyo.formattedTime(utcNightInTokyo), '23:00:00');
    expect(tokyo.isDay(utcNightInTokyo), false);
  });

  test('WorldClockCity offset calculation relative to local location', () {
    const newYork = WorldClockCity(
      id: 'ny',
      name: 'New York',
      timezone: 'America/New_York',
    );

    final londonLocation = tz.getLocation('Europe/London');

    // In January: London is UTC+0, New York is UTC-5 (diff = -5)
    final winterUtc = DateTime.utc(2026, 1, 15, 12, 0, 0);
    final diffWinter = newYork.getOffsetHoursDifferenceFrom(londonLocation, winterUtc);
    expect(diffWinter, -5);
  });

  test('Daylight Saving Time (DST) transition handling in London and New York', () {
    const london = WorldClockCity(
      id: 'london',
      name: 'London',
      timezone: 'Europe/London',
    );

    // Winter in London (GMT, UTC+0)
    final winterTime = DateTime.utc(2026, 1, 15, 12, 0, 0);
    final winterLondonDt = london.getDateTime(winterTime);
    expect(winterLondonDt.timeZoneOffset, Duration.zero);

    // Summer in London (BST, UTC+1 due to DST!)
    final summerTime = DateTime.utc(2026, 7, 15, 12, 0, 0);
    final summerLondonDt = london.getDateTime(summerTime);
    expect(summerLondonDt.timeZoneOffset, const Duration(hours: 1));
  });

  test('WorldClockCity JSON serialization and deserialization', () {
    const city = WorldClockCity(
      id: 'berlin',
      name: 'Berlin',
      timezone: 'Europe/Berlin',
      country: 'Germany',
    );

    final json = city.toJson();
    final reconstructed = WorldClockCity.fromJson(json);

    expect(reconstructed.id, city.id);
    expect(reconstructed.name, city.name);
    expect(reconstructed.timezone, city.timezone);
    expect(reconstructed.country, city.country);
  });
}

