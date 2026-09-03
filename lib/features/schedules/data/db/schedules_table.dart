import 'package:drift/drift.dart';

import 'package:my_pills/features/medications/data/db/medications_table.dart';

class SchedulesTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get serverId => text().nullable()();

  IntColumn get medicationId => integer().references(
    MedicationsTable,
    #id,
    onDelete: KeyAction.cascade,
  )();

  TextColumn get ruleType => text().withLength(min: 1, max: 32)();

  TextColumn get ruleJson => text()();

  RealColumn get doseAmount => real().nullable()();

  TextColumn get doseUnit => text().nullable()();

  TextColumn get doseDisplay => text().nullable()();

  DateTimeColumn get startDateUtc => dateTime()();

  DateTimeColumn get endDateUtc => dateTime().nullable()();

  TextColumn get clientId => text().nullable()();

  TextColumn get profileId => text().withDefault(const Constant('default'))();

  DateTimeColumn get serverUpdatedAt => dateTime().nullable()();

  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();

  BoolColumn get isTombstone => boolean().withDefault(const Constant(false))();
}
