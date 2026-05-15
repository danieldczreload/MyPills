import 'package:drift/drift.dart';
import 'package:my_pills/core/db/app_database.dart';
import 'package:my_pills/features/medications/domain/entities/medication.dart';

Medication toMedicationEntity(MedicationsTableData row) {
  final form = MedicationForm.values.byName(row.form);
  return Medication(
    id: row.id,
    name: row.name,
    form: form,
    category: row.category,
    colorToken: row.colorToken,
    notes: row.notes,
  );
}

MedicationsTableCompanion toMedicationInsertCompanion(Medication medication) {
  return MedicationsTableCompanion.insert(
    name: medication.name,
    form: medication.form.name,
    category: medication.category,
    colorToken: medication.colorToken,
    notes: Value(medication.notes),
  );
}

MedicationsTableData toMedicationRow(Medication medication) {
  return MedicationsTableData(
    id: medication.id,
    name: medication.name,
    form: medication.form.name,
    category: medication.category,
    colorToken: medication.colorToken,
    notes: medication.notes,
  );
}
