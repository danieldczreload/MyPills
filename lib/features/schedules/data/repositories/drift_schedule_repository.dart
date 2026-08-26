import 'dart:async';

import 'package:drift/drift.dart';
import 'package:my_pills/core/db/app_database.dart';
import 'package:my_pills/core/errors/failure.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/features/schedules/data/db/schedules_dao.dart';
import 'package:my_pills/features/schedules/data/mappers/schedule_mapper.dart';
import 'package:my_pills/features/schedules/domain/entities/schedule.dart';
import 'package:my_pills/features/schedules/domain/repositories/schedule_repository.dart';

class DriftScheduleRepository implements ScheduleRepository {
  DriftScheduleRepository(AppDatabase db, {String profileId = 'default'})
    : _db = db,
      _dao = db.scheduleDao,
      _profileId = profileId;

  final AppDatabase _db;
  final ScheduleDao _dao;
  final String _profileId;

  @override
  Future<Result<List<Schedule>>> getAll() async {
    try {
      final rows = await _dao.getAllSchedules(profileId: _profileId);
      return Result.success(rows.map(toScheduleEntity).toList(growable: false));
    } on Object catch (error, stackTrace) {
      return Result.failure(
        Failure.unexpected(error: error, stackTrace: stackTrace),
      );
    }
  }

  @override
  Stream<Result<List<Schedule>>> watchAll() {
    return Stream<Result<List<Schedule>>>.multi((controller) {
      final subscription = _dao
          .watchAllSchedules(profileId: _profileId)
          .listen(
            (rows) {
              try {
                controller.add(
                  Result.success(
                    rows.map(toScheduleEntity).toList(growable: false),
                  ),
                );
              } on Object catch (error, stackTrace) {
                controller.add(
                  Result.failure(
                    Failure.unexpected(error: error, stackTrace: stackTrace),
                  ),
                );
              }
            },
            onError: (Object error, StackTrace stackTrace) {
              controller.add(
                Result.failure(
                  Failure.unexpected(error: error, stackTrace: stackTrace),
                ),
              );
            },
            onDone: controller.close,
          );

      controller.onCancel = subscription.cancel;
    });
  }

  @override
  Future<Result<Schedule>> getById(int id) async {
    try {
      final row = await _dao.getScheduleById(id);
      if (row == null) {
        return const Result.failure(Failure.notFound());
      }
      return Result.success(toScheduleEntity(row));
    } on Object catch (error, stackTrace) {
      return Result.failure(
        Failure.unexpected(error: error, stackTrace: stackTrace),
      );
    }
  }

  @override
  Future<Result<Schedule>> create(Schedule schedule) async {
    try {
      final id = await _dao.insertSchedule(
        toScheduleInsertCompanion(schedule, profileId: _profileId),
      );
      final row = await _dao.getScheduleById(id);
      if (row == null) {
        return Result.failure(
          Failure.unexpected(error: StateError('Inserted schedule not found')),
        );
      }
      return Result.success(toScheduleEntity(row));
    } on Object catch (error, stackTrace) {
      return Result.failure(
        Failure.unexpected(error: error, stackTrace: stackTrace),
      );
    }
  }

  @override
  Future<Result<void>> delete(int id) async {
    try {
      final deleted = await _dao.deleteScheduleById(id);
      if (deleted == 0) {
        return const Result.failure(Failure.notFound());
      }
      return const Result<void>.success(null);
    } on Object catch (error, stackTrace) {
      return Result.failure(
        Failure.unexpected(error: error, stackTrace: stackTrace),
      );
    }
  }

  @override
  Future<Result<void>> cancelRecurring({
    int? scheduleId,
    int? medicationId,
    bool cancelPush = true,
    bool cancelCalendar = true,
    bool deleteSchedule = false,
  }) async {
    try {
      final db = _dao.attachedDatabase;
      if (scheduleId != null) {
        await (db.delete(db.doseEventsTable)..where(
              (t) =>
                  t.scheduleId.equals(scheduleId) & t.status.equals('pending'),
            ))
            .go();
        if (deleteSchedule) {
          await _dao.deleteScheduleById(scheduleId);
        }
      } else if (medicationId != null) {
        await (db.delete(db.doseEventsTable)..where(
              (t) =>
                  t.medicationId.equals(medicationId) &
                  t.status.equals('pending'),
            ))
            .go();
        if (deleteSchedule) {
          final scheds = await (_dao.select(
            _dao.schedulesTable,
          )..where((t) => t.medicationId.equals(medicationId))).get();
          for (final s in scheds) {
            await _dao.deleteScheduleById(s.id);
          }
        }
      }
      return const Result<void>.success(null);
    } on Object catch (error, stackTrace) {
      return Result.failure(
        Failure.unexpected(error: error, stackTrace: stackTrace),
      );
    }
  }
}
