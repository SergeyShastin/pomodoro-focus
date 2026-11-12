import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../settings/presentation/settings_provider.dart';
import '../data/world_clock_repository.dart';
import '../domain/world_clock_city.dart';

final worldClockRepositoryProvider = Provider<WorldClockRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return WorldClockRepository(prefs);
});

class WorldClockState {
  final List<WorldClockCity> cities;
  final tz.Location localLocation;
  final DateTime currentTimestamp;

  const WorldClockState({
    required this.cities,
    required this.localLocation,
    required this.currentTimestamp,
  });

  WorldClockState copyWith({
    List<WorldClockCity>? cities,
    tz.Location? localLocation,
    DateTime? currentTimestamp,
  }) {
    return WorldClockState(
      cities: cities ?? this.cities,
      localLocation: localLocation ?? this.localLocation,
      currentTimestamp: currentTimestamp ?? this.currentTimestamp,
    );
  }
}

class WorldClockNotifier extends StateNotifier<WorldClockState> {
  final WorldClockRepository _repository;
  Timer? _secondTimer;

  WorldClockNotifier(this._repository)
      : super(WorldClockState(
          cities: _repository.loadCities(),
          localLocation: tz.getLocation('UTC'),
          currentTimestamp: DateTime.now().toUtc(),
        )) {
    _init();
  }

  Future<void> _init() async {
    final location = await _repository.getLocalLocation();
    state = state.copyWith(
      localLocation: location,
      currentTimestamp: DateTime.now().toUtc(),
    );

    _secondTimer?.cancel();
    _secondTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(currentTimestamp: DateTime.now().toUtc());
    });
  }

  Future<void> addCity(WorldClockCity city) async {
    if (state.cities.any((c) => c.id == city.id || c.timezone == city.timezone)) {
      return;
    }
    final updated = [...state.cities, city];
    state = state.copyWith(cities: updated);
    await _repository.saveCities(updated);
  }

  Future<void> removeCity(String id) async {
    final updated = state.cities.where((c) => c.id != id).toList();
    state = state.copyWith(cities: updated);
    await _repository.saveCities(updated);
  }

  Future<void> reorderCities(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final updated = List<WorldClockCity>.from(state.cities);
    final moved = updated.removeAt(oldIndex);
    updated.insert(newIndex, moved);

    state = state.copyWith(cities: updated);
    await _repository.saveCities(updated);
  }

  @override
  void dispose() {
    _secondTimer?.cancel();
    super.dispose();
  }
}

final worldClockProvider =
    StateNotifierProvider<WorldClockNotifier, WorldClockState>((ref) {
  final repo = ref.watch(worldClockRepositoryProvider);
  return WorldClockNotifier(repo);
});
