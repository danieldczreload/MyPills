import 'dart:async';
import 'dart:convert';
import 'package:my_pills/core/db/app_database.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/core/sync/sync_engine.dart';
import 'package:my_pills/features/medications/domain/entities/medication.dart';
import 'package:my_pills/features/medications/domain/repositories/medication_repository.dart';
import 'package:uuid/uuid.dart';

class SyncedMedicationRepository implements MedicationRepository {
  SyncedMedicationRepository({
    required MedicationRepository localRepo,
    required AppDatabase db,
    required SyncEngine syncEngine,
    String profileId = 'default',
  }) : _localRepo = localRepo,
       _db = db,
       _syncEngine = syncEngine,
       _profileId = profileId;

  final MedicationRepository _localRepo;
  final AppDatabase _db;
  final SyncEngine _syncEngine;
  final String _profileId;
  static const _uuid = Uuid();

  @override
  Future<Result<List<Medication>>> getAll() => _localRepo.getAll();

  @override
  Stream<Result<List<Medication>>> watchAll() => _localRepo.watchAll();

  @override
  Future<Result<Medication>> getById(int id) => _localRepo.getById(id);

  @override
  Future<Result<Medication>> add(Medication medication) async {
    final result = await _localRepo.add(medication);
    if (result case Success(:final value)) {
      final row = await (_db.select(
        _db.medicationsTable,
      )..where((t) => t.id.equals(value.id))).getSingleOrNull();
      final clientId = row?.clientId ?? _uuid.v4();

      await _db
          .into(_db.outboxTable)
          .insert(
            OutboxTableCompanion.insert(
              profileId: _profileId,
              entityType: 'medication',
              entityId: value.id.toString(),
              clientId: clientId,
              action: 'CREATE',
              payloadJson: jsonEncode({
                'name': value.name,
                'dosage': value.category.isNotEmpty
                    ? value.category
                    : '1 dosis',
                'instructions': value.notes,
                'clientId': clientId,
                'form': value.form.name,
                'colorToken': value.colorToken,
              }),
              createdAt: DateTime.now().toUtc(),
            ),
          );
      unawaited(_syncEngine.flushOutbox());
    }
    return result;
  }

  @override
  Future<Result<Medication>> update(Medication medication) async {
    final row = await (_db.select(
      _db.medicationsTable,
    )..where((t) => t.id.equals(medication.id))).getSingleOrNull();
    final clientId = row?.clientId ?? _uuid.v4();
    final serverId = row?.serverId;

    final result = await _localRepo.update(medication);
    if (result case Success(:final value)) {
      await _db
          .into(_db.outboxTable)
          .insert(
            OutboxTableCompanion.insert(
              profileId: _profileId,
              entityType: 'medication',
              entityId: serverId ?? value.id.toString(),
              clientId: clientId,
              action: 'UPDATE',
              payloadJson: jsonEncode({
                'name': value.name,
                'dosage': value.category.isNotEmpty
                    ? value.category
                    : '1 dosis',
                'instructions': value.notes,
                'form': value.form.name,
                'colorToken': value.colorToken,
              }),
              createdAt: DateTime.now().toUtc(),
            ),
          );
      unawaited(_syncEngine.flushOutbox());
    }
    return result;
  }

  @override
  Future<Result<void>> delete(int id) async {
    final row = await (_db.select(
      _db.medicationsTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    final serverId = row?.serverId;
    final clientId = row?.clientId ?? _uuid.v4();

    final result = await _localRepo.delete(id);
    if (result case Success()) {
      await _db
          .into(_db.outboxTable)
          .insert(
            OutboxTableCompanion.insert(
              profileId: _profileId,
              entityType: 'medication',
              entityId: serverId ?? id.toString(),
              clientId: clientId,
              action: 'DELETE',
              payloadJson: jsonEncode({'id': serverId ?? id.toString()}),
              createdAt: DateTime.now().toUtc(),
            ),
          );
      unawaited(_syncEngine.flushOutbox());
    }
    return result;
  }
}
