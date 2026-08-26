import 'package:drift/drift.dart';
import 'package:my_pills/core/db/app_database.dart';
import 'package:my_pills/features/tracker/data/db/dose_events_table.dart';
import 'package:uuid/uuid.dart';

part 'dose_events_dao.g.dart';

@DriftAccessor(tables: [DoseEventsTable])
class DoseEventsDao extends DatabaseAccessor<AppDatabase>
    with _$DoseEventsDaoMixin {
  DoseEventsDao(super.attachedDatabase);

  Future<List<DoseEventsTableData>> getInUtcRange(
    DateTime startInclusiveUtc,
    DateTime endExclusiveUtc, {
    String? profileId,
  }) {
    final query = _rangeQuery(
      startInclusiveUtc,
      endExclusiveUtc,
      profileId: profileId,
    );
    return query.get();
  }

  Stream<List<DoseEventsTableData>> watchInUtcRange(
    DateTime startInclusiveUtc,
    DateTime endExclusiveUtc, {
    String? profileId,
  }) {
    final query = _rangeQuery(
      startInclusiveUtc,
      endExclusiveUtc,
      profileId: profileId,
    );
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
    String? profileId,
  }) {
    final query = select(doseEventsTable)
      ..where(
        (t) =>
            t.isTombstone.equals(false) &
            (profileId != null
                ? t.profileId.equals(profileId)
                : const Constant(true)) &
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
    String? profileId,
  }) {
    final query = select(doseEventsTable)
      ..where(
        (t) =>
            t.isTombstone.equals(false) &
            (profileId != null
                ? t.profileId.equals(profileId)
                : const Constant(true)) &
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
    String? profileId,
  }) {
    return transaction(() async {
      final existing = await getPendingForScheduleInUtcRange(
        scheduleId: scheduleId,
        startInclusiveUtc: startInclusiveUtc,
        endExclusiveUtc: endExclusiveUtc,
        profileId: profileId,
      );
      final allExisting = await getForScheduleInUtcRange(
        scheduleId: scheduleId,
        startInclusiveUtc: startInclusiveUtc,
        endExclusiveUtc: endExclusiveUtc,
        profileId: profileId,
      );

      // Drift reads DateTime from SQLite as local (isUtc=false) even when the
      // stored value is a UTC epoch millis. The incoming expected timestamps have
      // isUtc=true. Dart's DateTime.== checks the isUtc flag, so a UTC and a
      // local DateTime with the same millisecondsSinceEpoch are NOT equal.
      // Normalise everything to epoch-millis integers to avoid false mismatches
      // that would cause already-existing records to be re-inserted as duplicates.
      final allExistingMs = allExisting
          .map((row) => row.scheduledAtUtc.millisecondsSinceEpoch)
          .toSet();

      for (final scheduledAt in expectedScheduledAtUtc) {
        final key = scheduledAt.millisecondsSinceEpoch;
        if (!allExistingMs.contains(key)) {
          await insertDoseEvent(
            DoseEventsTableCompanion.insert(
              medicationId: medicationId,
              scheduleId: scheduleId,
              scheduledAtUtc: scheduledAt,
              status: 'pending',
              profileId: Value(profileId ?? 'default'),
              clientId: Value(const Uuid().v4()),
            ),
          );
        }
      }

      final expectedMs = expectedScheduledAtUtc
          .map((dt) => dt.millisecondsSinceEpoch)
          .toSet();

      for (final row in existing) {
        final key = row.scheduledAtUtc.millisecondsSinceEpoch;
        if (!expectedMs.contains(key)) {
          await (delete(
            doseEventsTable,
          )..where((t) => t.id.equals(row.id))).go();
        }
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
    DateTime endExclusiveUtc, {
    String? profileId,
  }) {
    final query = select(doseEventsTable)
      ..where(
        (t) =>
            t.isTombstone.equals(false) &
            (profileId != null
                ? t.profileId.equals(profileId)
                : const Constant(true)) &
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
    String? profileId,
  }) {
    return (select(doseEventsTable)
          ..where(
            (t) =>
                t.isTombstone.equals(false) &
                (profileId != null
                    ? t.profileId.equals(profileId)
                    : const Constant(true)) &
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
    String? profileId,
  }) async {
    final query = selectOnly(doseEventsTable)
      ..where(
        doseEventsTable.isTombstone.equals(false) &
            (profileId != null
                ? doseEventsTable.profileId.equals(profileId)
                : const Constant(true)) &
            doseEventsTable.scheduledAtUtc.isBiggerOrEqualValue(
              startInclusiveUtc,
            ) &
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
    String? profileId,
  }) async {
    final query = selectOnly(doseEventsTable)
      ..where(
        doseEventsTable.isTombstone.equals(false) &
            (profileId != null
                ? doseEventsTable.profileId.equals(profileId)
                : const Constant(true)) &
            doseEventsTable.scheduledAtUtc.isBiggerOrEqualValue(
              startInclusiveUtc,
            ) &
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
