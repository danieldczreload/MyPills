import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:my_pills/features/schedules/domain/entities/dose.dart';

part 'schedule.freezed.dart';

/// Time-of-day value stored as hour + minute (24-hour clock).
///
/// .NET analogue: a lightweight `record` — immutable by default.
typedef TimeOfDayValue = ({int hour, int minute});

/// A dosing rule that drives the schedule expander.
///
/// Sealed union of three cadence types. .NET analogue:
/// a discriminated union (`record` with `switch` pattern matching).
///
/// **id sentinel convention:** a value of `0` means the entity has not yet
/// been persisted. Pass `id: 0` when creating a new [Schedule] to hand to
/// `ScheduleRepository.create`; the returned entity carries the real
/// repository-assigned id.
@freezed
sealed class Schedule with _$Schedule {
  /// Daily at fixed clock times (e.g. 08:00 and 20:00).
  const factory Schedule.daily({
    required int id,
    required int medicationId,
    required List<TimeOfDayValue> timesOfDay,
    required DateTime startDate,
    DateTime? endDate,
    @Default(true) bool notifyPush,
    @Default(false) bool notifyCalendar,
    Dose? dose,
  }) = DailySchedule;

  /// Recurring every N hours within a daily window (e.g. every 4 h from 08:00).
  ///
  /// [startDate] anchors the first day the rule becomes active; this is
  /// required for the schedule expander to produce a deterministic window and
  /// for consistent `endDate >= startDate` validation.
  const factory Schedule.dailyInterval({
    required int id,
    required int medicationId,
    required int everyHours,
    required TimeOfDayValue startAt,
    required DateTime startDate,
    TimeOfDayValue? endAt,
    DateTime? endDate,
    @Default(true) bool notifyPush,
    @Default(false) bool notifyCalendar,
    Dose? dose,
  }) = DailyIntervalSchedule;

  /// Fixed days of the week at fixed clock times (e.g. Mon/Wed/Fri at 09:00).
  ///
  /// [daysOfWeek] values follow ISO 8601: 1 = Monday … 7 = Sunday.
  const factory Schedule.specificDays({
    required int id,
    required int medicationId,
    required List<int> daysOfWeek,
    required List<TimeOfDayValue> timesOfDay,
    required DateTime startDate,
    DateTime? endDate,
    @Default(true) bool notifyPush,
    @Default(false) bool notifyCalendar,
    Dose? dose,
  }) = SpecificDaysSchedule;
}
