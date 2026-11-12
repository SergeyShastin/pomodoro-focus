import 'dart:io';

import 'package:timezone/timezone.dart' as tz;

/// Resolves an IANA zone rather than a UTC offset, preserving DST rules.
Future<tz.Location> linuxLocalLocation({
  Map<String, String>? environment,
  String localtimePath = '/etc/localtime',
  String timezonePath = '/etc/timezone',
}) async {
  tz.Location? lookup(String name) {
    name = name.trim();
    if (name.startsWith(':')) name = name.substring(1);
    const marker = '/zoneinfo/';
    final index = name.indexOf(marker);
    if (index >= 0) name = name.substring(index + marker.length);
    for (final prefix in ['posix/', 'right/']) {
      if (name.startsWith(prefix)) name = name.substring(prefix.length);
    }
    try {
      return tz.getLocation(name);
    } on tz.LocationNotFoundException {
      return null;
    }
  }

  final fromEnvironment =
      lookup((environment ?? Platform.environment)['TZ'] ?? '');
  if (fromEnvironment != null) return fromEnvironment;

  try {
    final location = lookup(await File(localtimePath).resolveSymbolicLinks());
    if (location != null) return location;
  } on FileSystemException {
    // Some distributions use a text configuration instead of a symlink.
  }
  try {
    final location = lookup(await File(timezonePath).readAsString());
    if (location != null) return location;
  } on FileSystemException {
    // Report failure to the caller so its fallback remains explicit.
  }
  throw StateError('Cannot determine the Linux IANA timezone');
}
