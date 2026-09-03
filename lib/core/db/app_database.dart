import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:my_pills/core/db/outbox_table.dart';
import 'package:my_pills/features/medications/data/db/medications_dao.dart';
import 'package:my_pills/features/medications/data/db/medications_table.dart';
import 'package:my_pills/features/medications/data/db/taxonomy_groups_dao.dart';
import 'package:my_pills/features/medications/data/db/taxonomy_groups_table.dart';
import 'package:my_pills/features/schedules/data/db/schedules_dao.dart';
import 'package:my_pills/features/schedules/data/db/schedules_table.dart';
import 'package:my_pills/features/tracker/data/db/dose_events_dao.dart';
import 'package:my_pills/features/tracker/data/db/dose_events_table.dart';

part 'app_database.g.dart';

/// Application-wide Drift database.
///
/// .NET analogue: `DbContext` — owns the connection, schema version, and
/// migration strategy. Tables will be added in Phase 3.
///
/// The constructor accepts an optional [QueryExecutor] so tests can inject
/// an in-memory database (`NativeDatabase.memory()`) without touching disk.
@DriftDatabase(
  tables: [
    MedicationsTable,
    SchedulesTable,
    DoseEventsTable,
    TaxonomyGroupsTable,
    // Offline Outbox queue table
    OutboxTable,
  ],
  daos: [MedicationDao, ScheduleDao, DoseEventsDao, TaxonomyGroupsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await into(taxonomyGroupsTable).insert(_defaultCategory);
    },
    onUpgrade: (m, from, to) async {
      if (from < 4) {
        await m.createAll();
      }
      if (from < 5) {
        await m.addColumn(medicationsTable, medicationsTable.serverId);
        await m.addColumn(schedulesTable, schedulesTable.serverId);
        await m.addColumn(doseEventsTable, doseEventsTable.serverId);
      }
      if (from < 6) {
        await m.addColumn(taxonomyGroupsTable, taxonomyGroupsTable.clientId);
        await m.addColumn(taxonomyGroupsTable, taxonomyGroupsTable.serverId);
        await m.addColumn(
          taxonomyGroupsTable,
          taxonomyGroupsTable.serverUpdatedAt,
        );
        await m.addColumn(taxonomyGroupsTable, taxonomyGroupsTable.syncStatus);
        await m.addColumn(taxonomyGroupsTable, taxonomyGroupsTable.isTombstone);
      }
      if (from < 7) {
        await m.addColumn(medicationsTable, medicationsTable.profileId);
        await m.addColumn(schedulesTable, schedulesTable.profileId);
        await m.addColumn(doseEventsTable, doseEventsTable.profileId);
        await m.addColumn(taxonomyGroupsTable, taxonomyGroupsTable.profileId);
      }
      if (from < 8) {
        await m.addColumn(schedulesTable, schedulesTable.doseAmount);
        await m.addColumn(schedulesTable, schedulesTable.doseUnit);
        await m.addColumn(schedulesTable, schedulesTable.doseDisplay);
        await m.addColumn(doseEventsTable, doseEventsTable.doseAmount);
        await m.addColumn(doseEventsTable, doseEventsTable.doseUnit);
        await m.addColumn(doseEventsTable, doseEventsTable.doseDisplay);
      }
    },
  );

  static QueryExecutor _openConnection() {
    // driftDatabase handles path resolution via path_provider internally.
    return driftDatabase(name: 'my_pills_db');
  }
}

const _defaultCategory = TaxonomyGroupsTableCompanion(
  type: Value('category'),
  name: Value('General'),
  description: Value('Categoría por defecto'),
  iconName: Value('medicines'),
  colorValue: Value(0xFF1F108E),
);
