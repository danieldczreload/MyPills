import 'package:drift/drift.dart';
import 'package:my_pills/core/db/app_database.dart';
import 'package:my_pills/features/tracker/data/db/dose_events_table.dart';

part 'dose_events_dao.g.dart';

@DriftAccessor(tables: [DoseEventsTable])
class DoseEventsDao extends DatabaseAccessor<AppDatabase>
    with _$DoseEventsDaoMixin {
  DoseEventsDao(super.attachedDatabase);

  Future<List<DoseEventsTableData>> getInUtcRange(
    DateTime startInclusiveUtc,
    DateTime endExclusiveUtc,
  ) {
    final query = _rangeQuery(startInclusiveUtc, endExclusiveUtc);
    return query.get();
  }

  Stream<List<DoseEventsTableData>> watchInUtcRange(
    DateTime startInclusiveUtc,
    DateTime endExclusiveUtc,
  ) {
    final query = _rangeQuery(startInclusiveUtc, endExclusiveUtc);
    return query.watch();
  }

  Future<DoseEventsTableData?> getById(int id) {
    final query = select(doseEventsTable)..where((t) => t.id.equals(id));
    return query.getSingleOrNull();
  }

  Future<int> insertDoseEvent(DoseEventsTableCompanion companion) {
    return into(doseEventsTable).insert(companion);
  }

  Future<List<DoseEventsTableData>> getPendingForScheduleInUtcRange({
    required int scheduleId,
    required DateTime startInclusiveUtc,
    required DateTime endExclusiveUtc,
  }) {
    final query = select(doseEventsTable)
      ..where(
        (t) =>
            t.scheduleId.equals(scheduleId) &
            t.status.equals('pending') &
            t.scheduledAtUtc.isBiggerOrEqualValue(startInclusiveUtc) &
            t.scheduledAtUtc.isSmallerThanValue(endExclusiveUtc),
      );
    return query.get();
  }

  Future<List<DoseEventsTableData>> getForScheduleInUtcRange({
    required int scheduleId,
    required DateTime startInclusiveUtc,
    required DateTime endExclusiveUtc,
  }) {
    final query = select(doseEventsTable)
      ..where(
        (t) =>
            t.scheduleId.equals(scheduleId) &
            t.scheduledAtUtc.isBiggerOrEqualValue(startInclusiveUtc) &
            t.scheduledAtUtc.isSmallerThanValue(endExclusiveUtc),
      );
    return query.get();
  }

  Future<void> replacePendingForScheduleInUtcRange({
    required int medicationId,
    required int scheduleId,
    required DateTime startInclusiveUtc,
    required DateTime endExclusiveUtc,
    required List<DateTime> expectedScheduledAtUtc,
  }) {
    return transaction(() async {
      final existing = await getPendingForScheduleInUtcRange(
        scheduleId: scheduleId,
        startInclusiveUtc: startInclusiveUtc,
        endExclusiveUtc: endExclusiveUtc,
      );
      final allExisting = await getForScheduleInUtcRange(
        scheduleId: scheduleId,
        startInclusiveUtc: startInclusiveUtc,
        endExclusiveUtc: endExclusiveUtc,
      );

      // Drift reads DateTime from SQLite as local (isUtc=false) even when the
      // stored value is a UTC epoch millis. The incoming expected timestamps have
      // isUtc=true. Dart's DateTime.== checks the isUtc flag, so a UTC and a
      // local DateTime with the same millisecondsSinceEpoch are NOT equal.
      // Normalise everything to epoch-millis integers to avoid false mismatches
      // that would cause already-existing records to be re-inserted as duplicates.
      final existingByMs = <int, DoseEventsTableData>{
        for (final row in existing)
          row.scheduledAtUtc.millisecondsSinceEpoch: row,
      };
      final allExistingMs = allExisting
          .map((row) => row.scheduledAtUtc.millisecondsSinceEpoch)
          .toSet();
      final expectedMs = {
        for (final dt in expectedScheduledAtUtc) dt.millisecondsSinceEpoch,
      };

      final toDeleteIds = existing
          .where(
            (row) =>
                !expectedMs.contains(row.scheduledAtUtc.millisecondsSinceEpoch),
          )
          .map((row) => row.id)
          .toList(growable: false);
      if (toDeleteIds.isNotEmpty) {
        await (delete(
          doseEventsTable,
        )..where((t) => t.id.isIn(toDeleteIds))).go();
      }

      final missing = expectedScheduledAtUtc
          .where(
            (scheduledAtUtc) =>
                !existingByMs.containsKey(
                  scheduledAtUtc.millisecondsSinceEpoch,
                ) &&
                !allExistingMs.contains(scheduledAtUtc.millisecondsSinceEpoch),
          )
          .toList(growable: false);
      if (missing.isNotEmpty) {
        await batch((b) {
          b.insertAll(
            doseEventsTable,
            missing
                .map(
                  (scheduledAtUtc) => DoseEventsTableCompanion.insert(
                    medicationId: medicationId,
                    scheduleId: scheduleId,
                    scheduledAtUtc: scheduledAtUtc,
                    status: 'pending',
                  ),
                )
                .toList(growable: false),
          );
        });
      }
    });
  }

  Future<int> markTaken({required int id, required DateTime takenAtUtc}) {
    final query = update(doseEventsTable)
      ..where(
        (t) =>
            t.id.equals(id) &
            (t.status.equals('pending') | t.status.equals('missed')),
      );
    return query.write(
      DoseEventsTableCompanion(
        status: const Value('taken'),
        takenAtUtc: Value(takenAtUtc),
      ),
    );
  }

  Future<int> markMissed(int id) {
    final query = update(doseEventsTable)
      ..where((t) => t.id.equals(id) & t.status.equals('pending'));
    return query.write(
      const DoseEventsTableCompanion(
        status: Value('missed'),
      ),
    );
  }

  SimpleSelectStatement<$DoseEventsTableTable, DoseEventsTableData> _rangeQuery(
    DateTime startInclusiveUtc,
    DateTime endExclusiveUtc,
  ) {
    final query = select(doseEventsTable)
      ..where(
        (t) =>
            t.scheduledAtUtc.isBiggerOrEqualValue(startInclusiveUtc) &
            t.scheduledAtUtc.isSmallerThanValue(endExclusiveUtc),
      )
      ..orderBy([
        (t) => OrderingTerm.asc(t.scheduledAtUtc),
        (t) => OrderingTerm.asc(t.id),
      ]);
    return query;
  }

  Future<List<DoseEventsTableData>> getAllInUtcRange({
    required DateTime startInclusiveUtc,
    required DateTime endExclusiveUtc,
  }) {
    return (select(doseEventsTable)
          ..where(
            (t) =>
                t.scheduledAtUtc.isBiggerOrEqualValue(startInclusiveUtc) &
                t.scheduledAtUtc.isSmallerThanValue(endExclusiveUtc),
          )
          ..orderBy([
            (t) => OrderingTerm.asc(t.scheduledAtUtc),
          ]))
        .get();
  }

  Future<int> countTakenInUtcRange({
    required DateTime startInclusiveUtc,
    required DateTime endExclusiveUtc,
  }) async {
    final query = selectOnly(doseEventsTable)
      ..where(
        doseEventsTable.scheduledAtUtc.isBiggerOrEqualValue(startInclusiveUtc) &
            doseEventsTable.scheduledAtUtc.isSmallerThanValue(endExclusiveUtc) &
            doseEventsTable.status.equals('taken'),
      )
      ..addColumns([doseEventsTable.id.count()]);
    final result = await query.getSingle();
    return result.read(doseEventsTable.id.count()) ?? 0;
  }

  Future<int> countTotalInUtcRange({
    required DateTime startInclusiveUtc,
    required DateTime endExclusiveUtc,
  }) async {
    final query = selectOnly(doseEventsTable)
      ..where(
        doseEventsTable.scheduledAtUtc.isBiggerOrEqualValue(startInclusiveUtc) &
            doseEventsTable.scheduledAtUtc.isSmallerThanValue(endExclusiveUtc),
      )
      ..addColumns([doseEventsTable.id.count()]);
    final result = await query.getSingle();
    return result.read(doseEventsTable.id.count()) ?? 0;
  }

  Future<int> deleteDoseEvent(int id) {
    return (delete(doseEventsTable)..where((t) => t.id.equals(id))).go();
  }
}
