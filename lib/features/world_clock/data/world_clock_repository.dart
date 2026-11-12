import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../domain/cities_catalog.dart';
import '../domain/world_clock_city.dart';
import '../../../core/time/linux_timezone.dart';

class WorldClockRepository {
  final SharedPreferences _prefs;
  static const _keyCities = 'world_clock_cities';
  static bool _timezonesInitialized = false;

  WorldClockRepository(this._prefs) {
    ensureInitializedSync();
  }

  static void ensureInitializedSync() {
    if (!_timezonesInitialized) {
      tz.initializeTimeZones();
      _timezonesInitialized = true;
    }
  }

  Future<tz.Location> getLocalLocation() async {
    ensureInitializedSync();
    try {
      if (Platform.isLinux) return await linuxLocalLocation();
      final timezoneName = await FlutterTimezone.getLocalTimezone();
      return tz.getLocation(timezoneName);
    } catch (e) {
      debugPrint('Failed to get device timezone: $e. Falling back to UTC.');
      return tz.getLocation('UTC');
    }
  }

  List<WorldClockCity> loadCities() {
    final raw = _prefs.getString(_keyCities);
    if (raw == null || raw.isEmpty) {
      return defaultWorldCities;
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => WorldClockCity.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error decoding saved cities: $e');
      return defaultWorldCities;
    }
  }

  Future<void> saveCities(List<WorldClockCity> cities) async {
    final encoded = jsonEncode(cities.map((c) => c.toJson()).toList());
    await _prefs.setString(_keyCities, encoded);
  }
}
