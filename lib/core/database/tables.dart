import 'package:drift/drift.dart';

class FocusSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get taskName => text().withDefault(const Constant(''))();
  TextColumn get phase => text()(); // 'work', 'shortBreak', 'longBreak'
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime()();
  IntColumn get durationMinutes => integer()();
  BoolColumn get completed => boolean().withDefault(const Constant(true))();
}

