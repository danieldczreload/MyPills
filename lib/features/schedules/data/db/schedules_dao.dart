import 'package:drift/drift.dart';
import 'package:my_pills/core/db/app_database.dart';
import 'package:my_pills/features/medications/data/db/medications_table.dart';
import 'package:my_pills/features/schedules/data/db/schedules_table.dart';

part 'schedules_dao.g.dart';

@DriftAccessor(tables: [MedicationsTable, SchedulesTable])
class ScheduleDao extends DatabaseAccessor<AppDatabase>
    with _$ScheduleDaoMixin {
  ScheduleDao(super.attachedDatabase);

  Future<List<SchedulesTableData>> getAllSchedules({String? profileId}) {
    final query = select(schedulesTable)
      ..where(
        (t) =>
            t.isTombstone.equals(false) &
            (profileId != null
                ? t.profileId.equals(profileId)
                : const Constant(true)),
      )
      ..orderBy([
        (t) => OrderingTerm.asc(t.startDateUtc),
        (t) => OrderingTerm.asc(t.id),
      ]);
    return query.get();
  }

  Stream<List<SchedulesTableData>> watchAllSchedules({String? profileId}) {
    final query = select(schedulesTable)
      ..where(
        (t) =>
            t.isTombstone.equals(false) &
            (profileId != null
                ? t.profileId.equals(profileId)
                : const Constant(true)),
      )
      ..orderBy([
        (t) => OrderingTerm.asc(t.startDateUtc),
        (t) => OrderingTerm.asc(t.id),
      ]);
    return query.watch();
  }

  Future<SchedulesTableData?> getScheduleById(int id) {
    final query = select(schedulesTable)..where((t) => t.id.equals(id));
    return query.getSingleOrNull();
  }

  Future<int> insertSchedule(SchedulesTableCompanion companion) {
    return into(schedulesTable).insert(companion);
  }

  Future<int> deleteScheduleById(int id) {
    final query = delete(schedulesTable)..where((t) => t.id.equals(id));
    return query.go();
  }
}
