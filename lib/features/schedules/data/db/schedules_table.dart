import 'package:drift/drift.dart';

import 'package:my_pills/features/medications/data/db/medications_table.dart';

class SchedulesTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get medicationId => integer().references(
    MedicationsTable,
    #id,
    onDelete: KeyAction.cascade,
  )();

  TextColumn get ruleType => text().withLength(min: 1, max: 32)();

  TextColumn get ruleJson => text()();

  DateTimeColumn get startDateUtc => dateTime()();

  DateTimeColumn get endDateUtc => dateTime().nullable()();
}
