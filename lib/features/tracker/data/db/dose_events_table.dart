import 'package:drift/drift.dart';

import 'package:my_pills/features/medications/data/db/medications_table.dart';
import 'package:my_pills/features/schedules/data/db/schedules_table.dart';

class DoseEventsTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get serverId => text().nullable()();

  IntColumn get medicationId => integer().references(
    MedicationsTable,
    #id,
    onDelete: KeyAction.cascade,
  )();

  IntColumn get scheduleId =>
      integer().references(SchedulesTable, #id, onDelete: KeyAction.cascade)();

  DateTimeColumn get scheduledAtUtc => dateTime()();

  TextColumn get status => text().withLength(min: 1, max: 16)();

  DateTimeColumn get takenAtUtc => dateTime().nullable()();

  RealColumn get doseAmount => real().nullable()();

  TextColumn get doseUnit => text().nullable()();

  TextColumn get doseDisplay => text().nullable()();

  TextColumn get clientId => text().nullable()();

  TextColumn get profileId => text().withDefault(const Constant('default'))();

  DateTimeColumn get serverUpdatedAt => dateTime().nullable()();

  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();

  BoolColumn get isTombstone => boolean().withDefault(const Constant(false))();

  List<Index> get indexes => [
    Index(
      'dose_events_scheduled_at_idx',
      'CREATE INDEX dose_events_scheduled_at_idx '
          'ON dose_events_table (scheduled_at_utc)',
    ),
    Index(
      'dose_events_schedule_time_idx',
      'CREATE INDEX dose_events_schedule_time_idx '
          'ON dose_events_table (schedule_id, scheduled_at_utc)',
    ),
    Index(
      'dose_events_profile_time_idx',
      'CREATE INDEX dose_events_profile_time_idx '
          'ON dose_events_table (profile_id, scheduled_at_utc)',
    ),
  ];
}
