import 'package:drift/drift.dart';
import 'package:my_pills/core/db/app_database.dart';
import 'package:my_pills/features/schedules/data/mappers/dose_mapper.dart';
import 'package:my_pills/features/tracker/domain/entities/dose_event.dart';
import 'package:uuid/uuid.dart';

DoseEvent toDoseEventEntity(DoseEventsTableData row) {
  final status = DoseStatus.values.byName(row.status);
  return DoseEvent(
    id: row.id,
    medicationId: row.medicationId,
    scheduleId: row.scheduleId,
    scheduledAt: row.scheduledAtUtc.toLocal(),
    status: status,
    takenAt: row.takenAtUtc?.toLocal(),
    dose: DoseFields(
      amount: row.doseAmount,
      unit: row.doseUnit,
      display: row.doseDisplay,
    ).toDose(),
  );
}

DoseEventsTableCompanion toDoseEventInsertCompanion(
  DoseEvent event, {
  String? clientId,
  String? serverId,
  String? profileId,
}) {
  final dose = DoseFields.of(event.dose);
  return DoseEventsTableCompanion.insert(
    medicationId: event.medicationId,
    scheduleId: event.scheduleId,
    scheduledAtUtc: event.scheduledAt.toUtc(),
    status: event.status.name,
    takenAtUtc: Value(event.takenAt?.toUtc()),
    doseAmount: dose.amountValue,
    doseUnit: dose.unitValue,
    doseDisplay: dose.displayValue,
    clientId: Value(clientId ?? const Uuid().v4()),
    serverId: Value(serverId),
    profileId: Value(profileId ?? 'default'),
  );
}
