import 'package:drift/drift.dart';
import 'package:my_pills/core/db/app_database.dart';
import 'package:my_pills/features/medications/data/db/medications_table.dart';

part 'medications_dao.g.dart';

@DriftAccessor(tables: [MedicationsTable])
class MedicationDao extends DatabaseAccessor<AppDatabase>
    with _$MedicationDaoMixin {
  MedicationDao(super.attachedDatabase);

  Future<List<MedicationsTableData>> getAllMedications() {
    final query = select(medicationsTable)
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    return query.get();
  }

  Stream<List<MedicationsTableData>> watchAllMedications() {
    final query = select(medicationsTable)
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    return query.watch();
  }

  Future<MedicationsTableData?> getMedicationById(int id) {
    final query = select(medicationsTable)..where((t) => t.id.equals(id));
    return query.getSingleOrNull();
  }

  Future<int> insertMedication(MedicationsTableCompanion companion) {
    return into(medicationsTable).insert(companion);
  }

  Future<bool> updateMedication(MedicationsTableData row) {
    return update(medicationsTable).replace(row);
  }

  Future<int> deleteMedicationById(int id) {
    final query = delete(medicationsTable)..where((t) => t.id.equals(id));
    return query.go();
  }
}
