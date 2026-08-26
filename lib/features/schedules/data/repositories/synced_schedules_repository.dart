import 'dart:async';
import 'dart:convert';
import 'package:my_pills/core/db/app_database.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/core/sync/sync_engine.dart';
import 'package:my_pills/features/schedules/domain/entities/schedule.dart';
import 'package:my_pills/features/schedules/domain/repositories/schedule_repository.dart';
import 'package:uuid/uuid.dart';

class SyncedScheduleRepository implements ScheduleRepository {
  SyncedScheduleRepository({
    required ScheduleRepository localRepo,
    required AppDatabase db,
    required SyncEngine syncEngine,
    String profileId = 'default',
  }) : _localRepo = localRepo,
       _db = db,
       _syncEngine = syncEngine,
       _profileId = profileId;

  final ScheduleRepository _localRepo;
  final AppDatabase _db;
  final SyncEngine _syncEngine;
  final String _profileId;
  static const _uuid = Uuid();

  @override
  Future<Result<List<Schedule>>> getAll() => _localRepo.getAll();

  @override
  Stream<Result<List<Schedule>>> watchAll() => _localRepo.watchAll();

  @override
  Future<Result<Schedule>> getById(int id) => _localRepo.getById(id);

  @override
  Future<Result<Schedule>> create(Schedule schedule) async {
    final result = await _localRepo.create(schedule);
    if (result case Success(:final value)) {
      final localSched = await _db.scheduleDao.getScheduleById(value.id);
      final clientId = localSched?.clientId ?? _uuid.v4();

      // Fetch local medication row to get its serverId or clientId
      final localMed = await _db.medicationDao.getMedicationById(
        value.medicationId,
      );
      final medicationRef =
          localMed?.serverId ??
          localMed?.clientId ??
          value.medicationId.toString();

      final type = value.map(
        daily: (_) => 'daily',
        dailyInterval: (_) => 'daily_interval',
        specificDays: (_) => 'specific_days',
      );

      final Map<String, dynamic> payload = {
        'medicationId': medicationRef,
        'localMedicationId': value.medicationId,
        'type': type,
        'startDate': value.startDate.toUtc().toIso8601String(),
        if (value.endDate != null)
          'endDate': value.endDate!.toUtc().toIso8601String(),
        'clientId': clientId,
      };

      value.map(
        daily: (s) {
          payload['timesOfDay'] = s.timesOfDay
              .map((t) => {'hour': t.hour, 'minute': t.minute})
              .toList();
        },
        dailyInterval: (s) {
          payload['everyHours'] = s.everyHours;
          payload['startAt'] = {
            'hour': s.startAt.hour,
            'minute': s.startAt.minute,
          };
          if (s.endAt != null) {
            payload['endAt'] = {
              'hour': s.endAt!.hour,
              'minute': s.endAt!.minute,
            };
          }
        },
        specificDays: (s) {
          payload['daysOfWeek'] = s.daysOfWeek;
          payload['timesOfDay'] = s.timesOfDay
              .map((t) => {'hour': t.hour, 'minute': t.minute})
              .toList();
        },
      );

      await _db
          .into(_db.outboxTable)
          .insert(
            OutboxTableCompanion.insert(
              profileId: _profileId,
              entityType: 'schedule',
              entityId: value.id.toString(),
              clientId: clientId,
              action: 'CREATE',
              payloadJson: jsonEncode(payload),
              createdAt: DateTime.now().toUtc(),
            ),
          );
      unawaited(_syncEngine.flushOutbox());
    }
    return result;
  }

  @override
  Future<Result<void>> delete(int id) async {
    final localSched = await _db.scheduleDao.getScheduleById(id);
    final serverId = localSched?.serverId;
    final clientId = localSched?.clientId ?? _uuid.v4();

    final result = await _localRepo.delete(id);
    if (result case Success()) {
      await _db
          .into(_db.outboxTable)
          .insert(
            OutboxTableCompanion.insert(
              profileId: _profileId,
              entityType: 'schedule',
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

  @override
  Future<Result<void>> cancelRecurring({
    int? scheduleId,
    int? medicationId,
    bool cancelPush = true,
    bool cancelCalendar = true,
    bool deleteSchedule = false,
  }) async {
    String? targetServerScheduleId;
    String? targetServerMedicationId;
    var clientId = _uuid.v4();

    if (scheduleId != null) {
      final localSched = await _db.scheduleDao.getScheduleById(scheduleId);
      targetServerScheduleId = localSched?.serverId;
      if (localSched?.clientId != null) {
        clientId = localSched!.clientId!;
      }
    }

    if (medicationId != null) {
      final localMed = await _db.medicationDao.getMedicationById(medicationId);
      targetServerMedicationId = localMed?.serverId;
    }

    final result = await _localRepo.cancelRecurring(
      scheduleId: scheduleId,
      medicationId: medicationId,
      cancelPush: cancelPush,
      cancelCalendar: cancelCalendar,
      deleteSchedule: deleteSchedule,
    );

    if (result case Success()) {
      await _db
          .into(_db.outboxTable)
          .insert(
            OutboxTableCompanion.insert(
              profileId: _profileId,
              entityType: 'schedule',
              entityId: targetServerScheduleId ?? scheduleId?.toString() ?? '',
              clientId: clientId,
              action: 'CANCEL_RECURRING',
              payloadJson: jsonEncode({
                'scheduleId': targetServerScheduleId,
                'medicationId': targetServerMedicationId,
                'cancelPush': cancelPush,
                'cancelCalendar': cancelCalendar,
                'deleteSchedule': deleteSchedule,
              }),
              createdAt: DateTime.now().toUtc(),
            ),
          );
      unawaited(_syncEngine.flushOutbox());
    }
    return result;
  }
}
