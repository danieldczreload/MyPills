import 'dart:async';
import 'dart:convert';
import 'package:my_pills/core/db/app_database.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/core/sync/sync_engine.dart';
import 'package:my_pills/features/tracker/domain/entities/dose_event.dart';
import 'package:my_pills/features/tracker/domain/repositories/dose_event_repository.dart';
import 'package:uuid/uuid.dart';

class SyncedDoseEventRepository implements DoseEventRepository {
  SyncedDoseEventRepository({
    required DoseEventRepository localRepo,
    required AppDatabase db,
    required SyncEngine syncEngine,
    String profileId = 'default',
  }) : _localRepo = localRepo,
       _db = db,
       _syncEngine = syncEngine,
       _profileId = profileId;

  final DoseEventRepository _localRepo;
  final AppDatabase _db;
  final SyncEngine _syncEngine;
  final String _profileId;
  static const _uuid = Uuid();

  @override
  Future<Result<List<DoseEvent>>> getForDate(DateTime date) =>
      _localRepo.getForDate(date);

  @override
  Stream<Result<List<DoseEvent>>> watchForDate(DateTime date) =>
      _localRepo.watchForDate(date);

  @override
  Future<Result<List<DoseEvent>>> getForDateRange(
    DateTime start,
    DateTime end,
  ) => _localRepo.getForDateRange(start, end);

  @override
  Future<Result<void>> markTaken(int id, DateTime takenAt) async {
    final result = await _localRepo.markTaken(id, takenAt);
    if (result case Success()) {
      await _queueSyncTrackDose(id: id, status: 'taken', takenAt: takenAt);
    }
    return result;
  }

  @override
  Future<Result<void>> markMissed(int id) async {
    final result = await _localRepo.markMissed(id);
    if (result case Success()) {
      await _queueSyncTrackDose(id: id, status: 'missed');
    }
    return result;
  }

  Future<void> _queueSyncTrackDose({
    required int id,
    required String status,
    DateTime? takenAt,
  }) async {
    final localDose = await _db.doseEventsDao.getById(id);
    if (localDose == null) return;

    final localSched = await _db.scheduleDao.getScheduleById(
      localDose.scheduleId,
    );
    final scheduleRef =
        localSched?.serverId ??
        localSched?.clientId ??
        localDose.scheduleId.toString();
    final clientId = localDose.clientId ?? _uuid.v4();

    final payload = <String, dynamic>{
      'scheduleId': scheduleRef,
      'localScheduleId': localDose.scheduleId,
      'scheduledAt': localDose.scheduledAtUtc.toIso8601String(),
      'status': status,
      'clientId': clientId,
      if (takenAt != null) 'takenAt': takenAt.toUtc().toIso8601String(),
    };

    await _db
        .into(_db.outboxTable)
        .insert(
          OutboxTableCompanion.insert(
            profileId: _profileId,
            entityType: 'dose_event',
            entityId: id.toString(),
            clientId: clientId,
            action: 'TRACK',
            payloadJson: jsonEncode(payload),
            createdAt: DateTime.now().toUtc(),
          ),
        );
    unawaited(_syncEngine.flushOutbox());
  }

  @override
  Future<Result<void>> delete(int id) async {
    final localDose = await _db.doseEventsDao.getById(id);
    final serverId = localDose?.serverId;
    final clientId = localDose?.clientId ?? _uuid.v4();

    final result = await _localRepo.delete(id);
    if (result case Success()) {
      await _db
          .into(_db.outboxTable)
          .insert(
            OutboxTableCompanion.insert(
              profileId: _profileId,
              entityType: 'dose_event',
              entityId: serverId ?? id.toString(),
              clientId: clientId,
              action: 'DELETE',
              payloadJson: jsonEncode({
                'id': serverId ?? id.toString(),
                'serverId': serverId,
                'cancelPush': true,
                'cancelCalendar': true,
              }),
              createdAt: DateTime.now().toUtc(),
            ),
          );
      unawaited(_syncEngine.flushOutbox());
    }
    return result;
  }

  @override
  Future<Result<void>> reconcilePendingForSchedule({
    required int medicationId,
    required int scheduleId,
    required DateTime rangeStartUtc,
    required DateTime rangeEndExclusiveUtc,
    required List<DateTime> expectedScheduledAt,
  }) => _localRepo.reconcilePendingForSchedule(
    medicationId: medicationId,
    scheduleId: scheduleId,
    rangeStartUtc: rangeStartUtc,
    rangeEndExclusiveUtc: rangeEndExclusiveUtc,
    expectedScheduledAt: expectedScheduledAt,
  );

  @override
  Future<Result<int>> calculateStreak() => _localRepo.calculateStreak();

  @override
  Future<Result<double>> calculateAdherence() =>
      _localRepo.calculateAdherence();
}
