import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pomodoro_focus/core/database/app_database.dart';
import '../data/stats_repository.dart';
import '../domain/focus_stats.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return StatsRepository(db);
});

final statsSummaryProvider = FutureProvider<FocusStatsSummary>((ref) async {
  final repo = ref.watch(statsRepositoryProvider);
  // Recompute after committed database changes, including inserts from elsewhere.
  ref.watch(recentSessionsStreamProvider);
  final now = DateTime.now();
  final midnight = DateTime(now.year, now.month, now.day + 1);
  final refresh = Timer(midnight.difference(now), ref.invalidateSelf);
  ref.onDispose(refresh.cancel);
  return repo.getStatsSummary();
});

final recentSessionsStreamProvider = StreamProvider<List<FocusSession>>((ref) {
  final repo = ref.watch(statsRepositoryProvider);
  return repo.watchRecentSessions();
});
