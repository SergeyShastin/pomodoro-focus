import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [FocusSessions])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'pomodoro_focus_db'));

  @override
  int get schemaVersion => 1;

  Future<int> insertSession(FocusSessionsCompanion session) =>
      into(focusSessions).insert(session);

  Stream<List<FocusSession>> watchRecentSessions({int limit = 50}) =>
      (select(focusSessions)
            ..where(
                (tbl) => tbl.phase.equals('work') & tbl.completed.equals(true))
            ..orderBy([(t) => OrderingTerm.desc(t.endTime)])
            ..limit(limit))
          .watch();

  Future<List<FocusSession>> getSessionsBetween(DateTime from, DateTime to) =>
      (select(focusSessions)
            ..where((tbl) =>
                tbl.phase.equals('work') &
                tbl.completed.equals(true) &
                tbl.endTime.isBiggerOrEqualValue(from) &
                tbl.endTime.isSmallerThanValue(to))
            ..orderBy([(t) => OrderingTerm.asc(t.endTime)]))
          .get();
}
