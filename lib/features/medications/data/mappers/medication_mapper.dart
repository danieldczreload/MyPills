import 'package:drift/drift.dart';
import 'package:my_pills/core/db/app_database.dart';
import 'package:my_pills/features/medications/domain/entities/medication.dart';

import 'package:uuid/uuid.dart';

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

MedicationsTableCompanion toMedicationInsertCompanion(
  Medication medication, {
  String? clientId,
  String? serverId,
  String? profileId,
}) {
  return MedicationsTableCompanion.insert(
    name: medication.name,
    form: medication.form.name,
    category: medication.category,
    colorToken: medication.colorToken,
    notes: Value(medication.notes),
    clientId: Value(clientId ?? const Uuid().v4()),
    serverId: Value(serverId),
    profileId: Value(profileId ?? 'default'),
  );
}

MedicationsTableData toMedicationRow(
  Medication medication, {
  String? clientId,
  String? serverId,
  String profileId = 'default',
}) {
  return MedicationsTableData(
    id: medication.id,
    name: medication.name,
    form: medication.form.name,
    category: medication.category,
    colorToken: medication.colorToken,
    notes: medication.notes,
    clientId: clientId,
    serverId: serverId,
    profileId: profileId,
    syncStatus: 'synced',
    isTombstone: false,
  );
}
