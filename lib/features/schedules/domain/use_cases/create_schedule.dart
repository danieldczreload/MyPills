import 'package:my_pills/core/errors/failure.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/features/schedules/domain/entities/dose.dart';
import 'package:my_pills/features/schedules/domain/entities/schedule.dart';
import 'package:my_pills/features/schedules/domain/repositories/schedule_repository.dart';
import 'package:my_pills/features/schedules/domain/services/dose_reconciler.dart';

/// Creates a new dosing schedule after validating the input.
class CreateSchedule {
  const CreateSchedule(this._repository, {DoseReconciler? reconciler})
    : _reconciler = reconciler;

  final ScheduleRepository _repository;
  final DoseReconciler? _reconciler;

  Future<Result<Schedule>> call(Schedule schedule) async {
    if (schedule.id != 0) {
      return const Result.failure(
        Failure.validation(code: ValidationCode.invalidId),
      );
    }

    final failure = switch (schedule) {
      DailySchedule(:final timesOfDay, :final startDate, :final endDate) =>
        _validateEndDate(startDate, endDate) ?? _validateTimes(timesOfDay),
      DailyIntervalSchedule(
        :final everyHours,
        :final startAt,
        :final endAt,
        :final startDate,
        :final endDate,
      ) =>
        _validateEndDate(startDate, endDate) ??
            _validateTime(startAt) ??
            (endAt != null ? _validateTime(endAt) : null) ??
            (endAt != null && _isTimeBefore(endAt, startAt)
                ? const Failure.validation(
                    code: ValidationCode.invalidTimeRange,
                  )
                : null) ??
            (everyHours > 0
                ? null
                : const Failure.validation(
                    code: ValidationCode.invalidHoursInterval,
                  )),
      SpecificDaysSchedule(
        :final timesOfDay,
        :final daysOfWeek,
        :final startDate,
        :final endDate,
      ) =>
        _validateEndDate(startDate, endDate) ??
            (daysOfWeek.isEmpty
                ? const Failure.validation(code: ValidationCode.noDaysOfWeek)
                : _validateDaysOfWeek(daysOfWeek) ??
                      _validateTimes(timesOfDay)),
    };

    if (failure != null) {
      return Result.failure(failure);
    }

    final doseFailure = validateDose(schedule.dose);
    if (doseFailure != null) {
      return Result.failure(doseFailure);
    }

    final created = await _repository.create(schedule);
    if (created case FailureResult()) {
      return created;
    }

    if (_reconciler != null) {
      await _reconciler.reconcileUpcoming();
    }

    return created;
  }

  /// Returns a [Failure] when any [daysOfWeek] entry is outside 1–7 (ISO 8601).
  Failure? _validateDaysOfWeek(List<int> daysOfWeek) {
    for (final d in daysOfWeek) {
      if (d < 1 || d > 7) {
        return const Failure.validation(code: ValidationCode.invalidDayOfWeek);
      }
    }
    return null;
  }

  /// Returns a [Failure] when [endDate] is set and precedes [startDate].
  Failure? _validateEndDate(DateTime startDate, DateTime? endDate) {
    if (endDate != null && endDate.isBefore(startDate)) {
      return const Failure.validation(
        code: ValidationCode.endDateBeforeStartDate,
      );
    }
    return null;
  }

  /// Returns a [Failure] when the list is empty or any entry is out of range.
  Failure? _validateTimes(List<TimeOfDayValue> times) {
    if (times.isEmpty) {
      return const Failure.validation(code: ValidationCode.noTimesOfDay);
    }
    for (final t in times) {
      final failure = _validateTime(t);
      if (failure != null) return failure;
    }
    return null;
  }

  /// Returns a [Failure] when [t] is outside the valid 24-hour clock range.
  Failure? _validateTime(TimeOfDayValue t) {
    if (t.hour < 0 || t.hour > 23 || t.minute < 0 || t.minute > 59) {
      return const Failure.validation(code: ValidationCode.invalidTime);
    }
    return null;
  }

  /// Returns `true` when [a] is strictly before [b] on a 24-hour clock.
  static bool _isTimeBefore(TimeOfDayValue a, TimeOfDayValue b) {
    return a.hour < b.hour || (a.hour == b.hour && a.minute < b.minute);
  }
}
