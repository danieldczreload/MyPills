import 'package:my_pills/features/schedules/domain/entities/schedule.dart';
import 'package:my_pills/features/tracker/domain/entities/dose_event.dart';

/// Expands a [Schedule] rule into concrete [DoseEvent] occurrences.
///
/// Input and output datetimes are handled in the device local timezone.
/// Persistence mappers convert to UTC at the data-layer boundary.
class ScheduleExpander {
  const ScheduleExpander();

  /// Expands [schedule] within `[windowStartInclusive, windowEndExclusive)`.
  List<DoseEvent> expand({
    required Schedule schedule,
    required DateTime windowStartInclusive,
    required DateTime windowEndExclusive,
  }) {
    if (!windowStartInclusive.isBefore(windowEndExclusive)) {
      return const [];
    }

    final start = _dayStart(windowStartInclusive);
    final endExclusive = _dayStart(windowEndExclusive);

    final dates = switch (schedule) {
      DailySchedule(:final timesOfDay, :final startDate, :final endDate) =>
        _expandDaily(
          schedule: schedule,
          timesOfDay: timesOfDay,
          startDate: _dayStart(startDate),
          endDate: endDate == null ? null : _dayStart(endDate),
          windowStartInclusive: windowStartInclusive,
          windowEndExclusive: windowEndExclusive,
          dayCursorStart: start,
          dayCursorEndExclusive: endExclusive,
        ),
      DailyIntervalSchedule(
        :final everyHours,
        :final startAt,
        :final endAt,
        :final startDate,
        :final endDate,
      ) =>
        _expandDailyInterval(
          schedule: schedule,
          everyHours: everyHours,
          startAt: startAt,
          endAt: endAt,
          startDate: _dayStart(startDate),
          endDate: endDate == null ? null : _dayStart(endDate),
          windowStartInclusive: windowStartInclusive,
          windowEndExclusive: windowEndExclusive,
          dayCursorStart: endAt == null
              ? start.subtract(const Duration(days: 1))
              : start,
          dayCursorEndExclusive: endExclusive,
        ),
      SpecificDaysSchedule(
        :final daysOfWeek,
        :final timesOfDay,
        :final startDate,
        :final endDate,
      ) =>
        _expandSpecificDays(
          schedule: schedule,
          daysOfWeek: daysOfWeek,
          timesOfDay: timesOfDay,
          startDate: _dayStart(startDate),
          endDate: endDate == null ? null : _dayStart(endDate),
          windowStartInclusive: windowStartInclusive,
          windowEndExclusive: windowEndExclusive,
          dayCursorStart: start,
          dayCursorEndExclusive: endExclusive,
        ),
    };

    final sortedEvents = dates.toList(growable: false)
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return sortedEvents;
  }

  List<DoseEvent> _expandDaily({
    required Schedule schedule,
    required List<TimeOfDayValue> timesOfDay,
    required DateTime startDate,
    required DateTime? endDate,
    required DateTime windowStartInclusive,
    required DateTime windowEndExclusive,
    required DateTime dayCursorStart,
    required DateTime dayCursorEndExclusive,
  }) {
    final events = <DoseEvent>[];
    for (
      var day = dayCursorStart;
      day.isBefore(dayCursorEndExclusive);
      day = day.add(const Duration(days: 1))
    ) {
      if (!_isWithinActiveDate(day, startDate: startDate, endDate: endDate)) {
        continue;
      }

      for (final t in timesOfDay) {
        final scheduledAt = DateTime(
          day.year,
          day.month,
          day.day,
          t.hour,
          t.minute,
        );
        if (!_isWithinWindow(
          scheduledAt,
          windowStartInclusive: windowStartInclusive,
          windowEndExclusive: windowEndExclusive,
        )) {
          continue;
        }

        events.add(
          DoseEvent(
            id: 0,
            medicationId: schedule.medicationId,
            scheduleId: schedule.id,
            scheduledAt: scheduledAt,
            status: DoseStatus.pending,
          ),
        );
      }
    }
    return events;
  }

  List<DoseEvent> _expandSpecificDays({
    required Schedule schedule,
    required List<int> daysOfWeek,
    required List<TimeOfDayValue> timesOfDay,
    required DateTime startDate,
    required DateTime? endDate,
    required DateTime windowStartInclusive,
    required DateTime windowEndExclusive,
    required DateTime dayCursorStart,
    required DateTime dayCursorEndExclusive,
  }) {
    final daySet = daysOfWeek.toSet();
    final events = <DoseEvent>[];

    for (
      var day = dayCursorStart;
      day.isBefore(dayCursorEndExclusive);
      day = day.add(const Duration(days: 1))
    ) {
      if (!_isWithinActiveDate(day, startDate: startDate, endDate: endDate)) {
        continue;
      }
      if (!daySet.contains(day.weekday)) {
        continue;
      }

      for (final t in timesOfDay) {
        final scheduledAt = DateTime(
          day.year,
          day.month,
          day.day,
          t.hour,
          t.minute,
        );
        if (!_isWithinWindow(
          scheduledAt,
          windowStartInclusive: windowStartInclusive,
          windowEndExclusive: windowEndExclusive,
        )) {
          continue;
        }

        events.add(
          DoseEvent(
            id: 0,
            medicationId: schedule.medicationId,
            scheduleId: schedule.id,
            scheduledAt: scheduledAt,
            status: DoseStatus.pending,
          ),
        );
      }
    }

    return events;
  }

  List<DoseEvent> _expandDailyInterval({
    required Schedule schedule,
    required int everyHours,
    required TimeOfDayValue startAt,
    required TimeOfDayValue? endAt,
    required DateTime startDate,
    required DateTime? endDate,
    required DateTime windowStartInclusive,
    required DateTime windowEndExclusive,
    required DateTime dayCursorStart,
    required DateTime dayCursorEndExclusive,
  }) {
    final events = <DoseEvent>[];

    for (
      var day = dayCursorStart;
      day.isBefore(dayCursorEndExclusive);
      day = day.add(const Duration(days: 1))
    ) {
      if (day.isBefore(startDate)) {
        continue;
      }
      if (endDate != null && day.isAfter(endDate)) {
        continue;
      }

      final intervalStart = DateTime(
        day.year,
        day.month,
        day.day,
        startAt.hour,
        startAt.minute,
      );
      final intervalEndExclusive = endAt == null
          ? intervalStart.add(const Duration(days: 1))
          : DateTime(
              day.year,
              day.month,
              day.day,
              endAt.hour,
              endAt.minute,
            ).add(const Duration(minutes: 1));

      for (
        var cursor = intervalStart;
        cursor.isBefore(intervalEndExclusive);
        cursor = cursor.add(Duration(hours: everyHours))
      ) {
        final eventDay = _dayStart(cursor);
        if (!_isWithinActiveDate(
          eventDay,
          startDate: startDate,
          endDate: endDate,
        )) {
          continue;
        }
        if (!_isWithinWindow(
          cursor,
          windowStartInclusive: windowStartInclusive,
          windowEndExclusive: windowEndExclusive,
        )) {
          continue;
        }

        events.add(
          DoseEvent(
            id: 0,
            medicationId: schedule.medicationId,
            scheduleId: schedule.id,
            scheduledAt: cursor,
            status: DoseStatus.pending,
          ),
        );
      }
    }

    return events;
  }

  static DateTime _dayStart(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static bool _isWithinWindow(
    DateTime value, {
    required DateTime windowStartInclusive,
    required DateTime windowEndExclusive,
  }) {
    return !value.isBefore(windowStartInclusive) &&
        value.isBefore(windowEndExclusive);
  }

  static bool _isWithinActiveDate(
    DateTime day, {
    required DateTime startDate,
    required DateTime? endDate,
  }) {
    if (day.isBefore(startDate)) {
      return false;
    }
    if (endDate != null && day.isAfter(endDate)) {
      return false;
    }
    return true;
  }
}
