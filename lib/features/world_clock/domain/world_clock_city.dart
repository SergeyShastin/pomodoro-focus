import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

class WorldClockCity {
  final String id;
  final String name;
  final String timezone;
  final String country;

  const WorldClockCity({
    required this.id,
    required this.name,
    required this.timezone,
    this.country = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'timezone': timezone,
        'country': country,
      };

  factory WorldClockCity.fromJson(Map<String, dynamic> json) => WorldClockCity(
        id: json['id'] as String,
        name: json['name'] as String,
        timezone: json['timezone'] as String,
        country: json['country'] as String? ?? '',
      );

  tz.TZDateTime getDateTime([DateTime? utcNow]) {
    final now = utcNow ?? DateTime.now().toUtc();
    final location = tz.getLocation(timezone);
    return tz.TZDateTime.from(now, location);
  }

  bool isDay([DateTime? utcNow]) {
    final dt = getDateTime(utcNow);
    return dt.hour >= 6 && dt.hour < 20;
  }

  int getOffsetHoursDifferenceFrom(tz.Location localLocation, [DateTime? utcNow]) {
    final now = utcNow ?? DateTime.now().toUtc();
    final targetTime = getDateTime(now);
    final localTime = tz.TZDateTime.from(now, localLocation);

    final diffMilliseconds =
        targetTime.timeZoneOffset.inMilliseconds -
        localTime.timeZoneOffset.inMilliseconds;

    return (diffMilliseconds / (1000 * 60 * 60)).round();
  }

  String formattedTime(DateTime? utcNow) {
    final dt = getDateTime(utcNow);
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String formattedDate(DateTime? utcNow, String localeCode) {
    final dt = getDateTime(utcNow);
    return DateFormat.MMMEd(localeCode).format(dt);
  }
}

