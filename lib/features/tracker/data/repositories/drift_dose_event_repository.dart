import 'dart:async';

import 'package:my_pills/core/db/app_database.dart';
import 'package:my_pills/core/errors/failure.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/features/timeline/domain/repositories/timeline_repository.dart';
import 'package:my_pills/features/tracker/data/db/dose_events_dao.dart';
import 'package:my_pills/features/tracker/data/mappers/dose_event_mapper.dart';
import 'package:my_pills/features/tracker/domain/entities/dose_event.dart';
import 'package:my_pills/features/tracker/domain/repositories/dose_event_repository.dart';

class DriftDoseEventRepository
    implements DoseEventRepository, TimelineRepository {
  DriftDoseEventRepository(AppDatabase db) : _dao = db.doseEventsDao;

  final DoseEventsDao _dao;

  @override
  Future<Result<List<DoseEvent>>> getForDate(DateTime date) {
    final (start, endExclusive) = _dayRangeUtc(date);
    return _getInRange(start, endExclusive);
  }

  @override
  Stream<Result<List<DoseEvent>>> watchForDate(DateTime date) {
    final (start, endExclusive) = _dayRangeUtc(date);
    return _watchInRange(start, endExclusive);
  }

  @override
  Future<Result<List<DoseEvent>>> getForDateRange(
    DateTime start,
    DateTime end,
  ) {
    final startLocal = DateTime(start.year, start.month, start.day);
    final endLocal = DateTime(end.year, end.month, end.day).add(
      const Duration(days: 1),
    );
    return _getInRange(startLocal.toUtc(), endLocal.toUtc());
  }

  @override
  Stream<Result<List<DoseEvent>>> watchForDateRange(
    DateTime start,
    DateTime end,
  ) {
    final startLocal = DateTime(start.year, start.month, start.day);
    final endLocal = DateTime(end.year, end.month, end.day).add(
      const Duration(days: 1),
    );
    return _watchInRange(startLocal.toUtc(), endLocal.toUtc());
  }

  @override
  Future<Result<void>> markTaken(int id, DateTime takenAt) async {
    try {
      final changed = await _dao.markTaken(id: id, takenAtUtc: takenAt.toUtc());
      if (changed == 0) {
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
  Future<Result<void>> markMissed(int id) async {
    try {
      final changed = await _dao.markMissed(id);
      if (changed == 0) {
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
  Future<Result<void>> delete(int id) async {
    try {
      final changed = await _dao.deleteDoseEvent(id);
      if (changed == 0) {
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
  Future<Result<void>> reconcilePendingForSchedule({
    required int medicationId,
    required int scheduleId,
    required DateTime rangeStartUtc,
    required DateTime rangeEndExclusiveUtc,
    required List<DateTime> expectedScheduledAt,
  }) async {
    try {
      await _dao.replacePendingForScheduleInUtcRange(
        medicationId: medicationId,
        scheduleId: scheduleId,
        startInclusiveUtc: rangeStartUtc,
        endExclusiveUtc: rangeEndExclusiveUtc,
        expectedScheduledAtUtc: expectedScheduledAt
            .map((value) => value.toUtc())
            .toList(growable: false),
      );
      return const Result<void>.success(null);
    } on Object catch (error, stackTrace) {
      return Result.failure(
        Failure.unexpected(error: error, stackTrace: stackTrace),
      );
    }
  }

  @override
  Future<Result<int>> calculateStreak() async {
    try {
      final now = DateTime.now().toUtc();
      final startOfToday = DateTime(now.year, now.month, now.day).toUtc();
      var streak = 0;

      // Today counts only when every scheduled dose is taken.
      final todayEnd = startOfToday.add(const Duration(days: 1));
      final todayDoses = await _dao.getAllInUtcRange(
        startInclusiveUtc: startOfToday,
        endExclusiveUtc: todayEnd,
      );
      final todayComplete =
          todayDoses.isNotEmpty && todayDoses.every((d) => d.status == 'taken');
      if (todayComplete) streak++;

      // Walk backwards from yesterday; a day with no doses breaks the streak.
      var currentDayStart = startOfToday.subtract(const Duration(days: 1));

      for (var i = 0; i < 365; i++) {
        final dayEnd = currentDayStart.add(const Duration(days: 1));
        final dayDoses = await _dao.getAllInUtcRange(
          startInclusiveUtc: currentDayStart,
          endExclusiveUtc: dayEnd,
        );

        if (dayDoses.isEmpty) break; // no doses scheduled → streak ends

        final allTaken = dayDoses.every((d) => d.status == 'taken');
        if (allTaken) {
          streak++;
          currentDayStart = currentDayStart.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }

      return Result.success(streak);
    } on Object catch (error, stackTrace) {
      return Result.failure(
        Failure.unexpected(error: error, stackTrace: stackTrace),
      );
    }
  }

  @override
  Future<Result<double>> calculateAdherence() async {
    try {
      final now = DateTime.now().toUtc();
      final sevenDaysAgo = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(days: 7)).toUtc();
      final todayEnd = DateTime(
        now.year,
        now.month,
        now.day,
      ).add(const Duration(days: 1)).toUtc();

      final taken = await _dao.countTakenInUtcRange(
        startInclusiveUtc: sevenDaysAgo,
        endExclusiveUtc: todayEnd,
      );
      final total = await _dao.countTotalInUtcRange(
        startInclusiveUtc: sevenDaysAgo,
        endExclusiveUtc: todayEnd,
      );

      if (total == 0) {
        return const Result.success(100);
      }

      final adherence = (taken / total) * 100;
      return Result.success(adherence);
    } on Object catch (error, stackTrace) {
      return Result.failure(
        Failure.unexpected(error: error, stackTrace: stackTrace),
      );
    }
  }

  Future<Result<List<DoseEvent>>> _getInRange(
    DateTime startInclusiveUtc,
    DateTime endExclusiveUtc,
  ) async {
    try {
      final rows = await _dao.getInUtcRange(startInclusiveUtc, endExclusiveUtc);
      return Result.success(
        rows.map(toDoseEventEntity).toList(growable: false),
      );
    } on Object catch (error, stackTrace) {
      return Result.failure(
        Failure.unexpected(error: error, stackTrace: stackTrace),
      );
    }
  }

  Stream<Result<List<DoseEvent>>> _watchInRange(
    DateTime startInclusiveUtc,
    DateTime endExclusiveUtc,
  ) {
    return Stream<Result<List<DoseEvent>>>.multi((controller) {
      final subscription = _dao
          .watchInUtcRange(startInclusiveUtc, endExclusiveUtc)
          .listen(
            (rows) {
              try {
                controller.add(
                  Result.success(
                    rows.map(toDoseEventEntity).toList(growable: false),
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

  (DateTime, DateTime) _dayRangeUtc(DateTime date) {
    final startLocal = DateTime(date.year, date.month, date.day);
    final endLocal = startLocal.add(const Duration(days: 1));
    return (startLocal.toUtc(), endLocal.toUtc());
  }
}
