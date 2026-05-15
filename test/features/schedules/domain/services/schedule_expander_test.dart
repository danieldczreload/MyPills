import 'package:flutter_test/flutter_test.dart';
import 'package:my_pills/features/schedules/domain/entities/schedule.dart';
import 'package:my_pills/features/schedules/domain/services/schedule_expander.dart';

void main() {
  const expander = ScheduleExpander();

  group('ScheduleExpander', () {
    group('Daily', () {
      test('expands daily schedule for matching days and times', () {
        final schedule = Schedule.daily(
          id: 10,
          medicationId: 99,
          timesOfDay: const [(hour: 8, minute: 0), (hour: 20, minute: 30)],
          startDate: DateTime(2024, 6, 10),
        );

        final events = expander.expand(
          schedule: schedule,
          windowStartInclusive: DateTime(2024, 6, 10),
          windowEndExclusive: DateTime(2024, 6, 12),
        );

        expect(events, hasLength(4));
        expect(
          events.map((e) => e.scheduledAt),
          [
            DateTime(2024, 6, 10, 8),
            DateTime(2024, 6, 10, 20, 30),
            DateTime(2024, 6, 11, 8),
            DateTime(2024, 6, 11, 20, 30),
          ],
        );
      });

      test('returns empty when window does not overlap schedule', () {
        final schedule = Schedule.daily(
          id: 10,
          medicationId: 99,
          timesOfDay: const [(hour: 8, minute: 0)],
          startDate: DateTime(2024, 6, 20),
          endDate: DateTime(2024, 6, 25),
        );

        final events = expander.expand(
          schedule: schedule,
          windowStartInclusive: DateTime(2024, 6, 10),
          windowEndExclusive: DateTime(2024, 6, 15),
        );

        expect(events, isEmpty);
      });

      test('returns empty when start is not before end', () {
        final schedule = Schedule.daily(
          id: 10,
          medicationId: 99,
          timesOfDay: const [(hour: 8, minute: 0)],
          startDate: DateTime(2024, 6, 10),
        );

        final events = expander.expand(
          schedule: schedule,
          windowStartInclusive: DateTime(2024, 6, 12),
          windowEndExclusive: DateTime(2024, 6, 12),
        );

        expect(events, isEmpty);
      });

      test('respects schedule endDate boundary', () {
        final schedule = Schedule.daily(
          id: 14,
          medicationId: 99,
          timesOfDay: const [(hour: 8, minute: 0)],
          startDate: DateTime(2024, 6, 10),
          endDate: DateTime(2024, 6, 11),
        );

        final events = expander.expand(
          schedule: schedule,
          windowStartInclusive: DateTime(2024, 6, 10),
          windowEndExclusive: DateTime(2024, 6, 14),
        );

        expect(
          events.map((e) => e.scheduledAt),
          [
            DateTime(2024, 6, 10, 8),
            DateTime(2024, 6, 11, 8),
          ],
        );
      });

      test('crosses month boundary correctly', () {
        final schedule = Schedule.daily(
          id: 10,
          medicationId: 99,
          timesOfDay: const [(hour: 8, minute: 0)],
          startDate: DateTime(2024, 1, 31),
        );

        final events = expander.expand(
          schedule: schedule,
          windowStartInclusive: DateTime(2024, 1, 31),
          windowEndExclusive: DateTime(2024, 2, 2),
        );

        expect(events, hasLength(2));
        expect(events[0].scheduledAt, DateTime(2024, 1, 31, 8));
        expect(events[1].scheduledAt, DateTime(2024, 2, 1, 8));
      });

      test('crosses year boundary correctly', () {
        final schedule = Schedule.daily(
          id: 10,
          medicationId: 99,
          timesOfDay: const [(hour: 8, minute: 0)],
          startDate: DateTime(2024, 12, 31),
        );

        final events = expander.expand(
          schedule: schedule,
          windowStartInclusive: DateTime(2024, 12, 31),
          windowEndExclusive: DateTime(2025, 1, 2),
        );

        expect(events, hasLength(2));
        expect(events[0].scheduledAt, DateTime(2024, 12, 31, 8));
        expect(events[1].scheduledAt, DateTime(2025, 1, 1, 8));
      });

      test('filters times outside window on first and last day', () {
        final schedule = Schedule.daily(
          id: 10,
          medicationId: 99,
          timesOfDay: const [
            (hour: 6, minute: 0),
            (hour: 12, minute: 0),
            (hour: 18, minute: 0),
          ],
          startDate: DateTime(2024, 6, 10),
        );

        final events = expander.expand(
          schedule: schedule,
          windowStartInclusive: DateTime(2024, 6, 10, 8),
          windowEndExclusive: DateTime(2024, 6, 11, 14),
        );

        expect(events, hasLength(2));
        expect(events[0].scheduledAt, DateTime(2024, 6, 10, 12));
        expect(events[1].scheduledAt, DateTime(2024, 6, 10, 18));
      });
    });

    group('SpecificDays', () {
      test('expands specific-days schedule only for matching weekdays', () {
        final schedule = Schedule.specificDays(
          id: 11,
          medicationId: 99,
          daysOfWeek: const [1, 3, 5],
          timesOfDay: const [(hour: 9, minute: 0)],
          startDate: DateTime(2024, 6, 10),
        );

        final events = expander.expand(
          schedule: schedule,
          windowStartInclusive: DateTime(2024, 6, 10),
          windowEndExclusive: DateTime(2024, 6, 17),
        );

        expect(events, hasLength(3));
        expect(
          events.map((e) => e.scheduledAt),
          [
            DateTime(2024, 6, 10, 9),
            DateTime(2024, 6, 12, 9),
            DateTime(2024, 6, 14, 9),
          ],
        );
      });

      test('returns empty when no days match', () {
        final schedule = Schedule.specificDays(
          id: 11,
          medicationId: 99,
          daysOfWeek: const [2], // Tuesday only
          timesOfDay: const [(hour: 9, minute: 0)],
          startDate: DateTime(2024, 6, 10), // Monday
        );

        final events = expander.expand(
          schedule: schedule,
          windowStartInclusive: DateTime(2024, 6, 10),
          windowEndExclusive: DateTime(2024, 6, 11),
        );

        expect(events, isEmpty);
      });

      test('respects endDate on specific days', () {
        final schedule = Schedule.specificDays(
          id: 11,
          medicationId: 99,
          daysOfWeek: const [1, 3, 5],
          timesOfDay: const [(hour: 9, minute: 0)],
          startDate: DateTime(2024, 6, 10),
          endDate: DateTime(2024, 6, 12),
        );

        final events = expander.expand(
          schedule: schedule,
          windowStartInclusive: DateTime(2024, 6, 10),
          windowEndExclusive: DateTime(2024, 6, 20),
        );

        expect(events, hasLength(2));
        expect(events[0].scheduledAt, DateTime(2024, 6, 10, 9));
        expect(events[1].scheduledAt, DateTime(2024, 6, 12, 9));
      });
    });

    group('DailyInterval', () {
      test('expands daily-interval schedule with inclusive endAt', () {
        final schedule = Schedule.dailyInterval(
          id: 12,
          medicationId: 99,
          everyHours: 4,
          startAt: (hour: 8, minute: 0),
          endAt: (hour: 20, minute: 0),
          startDate: DateTime(2024, 6, 10),
        );

        final events = expander.expand(
          schedule: schedule,
          windowStartInclusive: DateTime(2024, 6, 10),
          windowEndExclusive: DateTime(2024, 6, 11),
        );

        expect(
          events.map((e) => e.scheduledAt),
          [
            DateTime(2024, 6, 10, 8),
            DateTime(2024, 6, 10, 12),
            DateTime(2024, 6, 10, 16),
            DateTime(2024, 6, 10, 20),
          ],
        );
      });

      test('expands interval across midnight when endAt is omitted', () {
        final schedule = Schedule.dailyInterval(
          id: 13,
          medicationId: 99,
          everyHours: 4,
          startAt: (hour: 22, minute: 0),
          startDate: DateTime(2024, 6, 10),
        );

        final events = expander.expand(
          schedule: schedule,
          windowStartInclusive: DateTime(2024, 6, 11),
          windowEndExclusive: DateTime(2024, 6, 12),
        );

        expect(
          events.map((e) => e.scheduledAt),
          [
            DateTime(2024, 6, 11, 2),
            DateTime(2024, 6, 11, 6),
            DateTime(2024, 6, 11, 10),
            DateTime(2024, 6, 11, 14),
            DateTime(2024, 6, 11, 18),
            DateTime(2024, 6, 11, 22),
          ],
        );
      });

      test('handles single-dose per day when endAt equals startAt', () {
        final schedule = Schedule.dailyInterval(
          id: 14,
          medicationId: 99,
          everyHours: 24,
          startAt: (hour: 8, minute: 0),
          endAt: (hour: 8, minute: 0),
          startDate: DateTime(2024, 6, 10),
        );

        final events = expander.expand(
          schedule: schedule,
          windowStartInclusive: DateTime(2024, 6, 10),
          windowEndExclusive: DateTime(2024, 6, 13),
        );

        expect(events, hasLength(3));
        expect(events.map((e) => e.scheduledAt), [
          DateTime(2024, 6, 10, 8),
          DateTime(2024, 6, 11, 8),
          DateTime(2024, 6, 12, 8),
        ]);
      });

      test('does not include dose before startDate', () {
        final schedule = Schedule.dailyInterval(
          id: 15,
          medicationId: 99,
          everyHours: 4,
          startAt: (hour: 22, minute: 0),
          startDate: DateTime(2024, 6, 11),
        );

        final events = expander.expand(
          schedule: schedule,
          windowStartInclusive: DateTime(2024, 6, 10),
          windowEndExclusive: DateTime(2024, 6, 12),
        );

        // June 10 is skipped because it is before startDate.
        // On June 11 the interval starts at 22:00; the next would be 02:00 on
        // June 12, which is outside the window (ends at June 12 midnight).
        expect(
          events.map((e) => e.scheduledAt),
          [DateTime(2024, 6, 11, 22)],
        );
      });
    });

    group('DST edge cases', () {
      // Detect at runtime whether the current local timezone springs forward
      // on the US date (Mar 10). This keeps the tests deterministic without
      // requiring a specific TZ environment variable.
      bool springsForwardOnMar10() {
        final twoThirty = DateTime(2024, 3, 10, 2, 30);
        return twoThirty.hour == 3 && twoThirty.minute == 30;
      }

      // Note: Dart DateTime handles DST transitions automatically when
      // constructing local DateTime objects. The expander operates on local
      // wall-clock times, so we verify behavior around transition dates.

      test('spring forward: daily schedule skips missing hour', () {
        final schedule = Schedule.daily(
          id: 20,
          medicationId: 99,
          timesOfDay: const [
            (hour: 1, minute: 30),
            (hour: 2, minute: 30),
            (hour: 3, minute: 30),
          ],
          startDate: DateTime(2024, 3, 10),
        );

        final events = expander.expand(
          schedule: schedule,
          windowStartInclusive: DateTime(2024, 3, 10),
          windowEndExclusive: DateTime(2024, 3, 11),
        );

        expect(events, hasLength(3));
        expect(events[0].scheduledAt, DateTime(2024, 3, 10, 1, 30));

        if (springsForwardOnMar10()) {
          // In zones where 02:30 springs forward to 03:30, both the 02:30
          // and 03:30 wall-clock times resolve to the same instant.
          expect(events[1].scheduledAt, DateTime(2024, 3, 10, 3, 30));
          expect(events[2].scheduledAt, DateTime(2024, 3, 10, 3, 30));
        } else {
          // Fixed-offset zones (or zones with DST on different dates) keep
          // the literal wall-clock time.
          expect(events[1].scheduledAt, DateTime(2024, 3, 10, 2, 30));
          expect(events[2].scheduledAt, DateTime(2024, 3, 10, 3, 30));
        }
      });

      test('fall back: daily schedule handles duplicated hour', () {
        // US DST 2024: clocks fall back Nov 3 at 02:00 → 01:00
        final schedule = Schedule.daily(
          id: 21,
          medicationId: 99,
          timesOfDay: const [(hour: 1, minute: 30)],
          startDate: DateTime(2024, 11, 3),
        );

        final events = expander.expand(
          schedule: schedule,
          windowStartInclusive: DateTime(2024, 11, 3),
          windowEndExclusive: DateTime(2024, 11, 4),
        );

        expect(events, hasLength(1));
        expect(events.single.scheduledAt.hour, 1);
        expect(events.single.scheduledAt.minute, 30);
      });

      test('interval schedule around spring-forward boundary', () {
        final schedule = Schedule.dailyInterval(
          id: 22,
          medicationId: 99,
          everyHours: 2,
          startAt: (hour: 0, minute: 0),
          endAt: (hour: 6, minute: 0),
          startDate: DateTime(2024, 3, 10),
        );

        final events = expander.expand(
          schedule: schedule,
          windowStartInclusive: DateTime(2024, 3, 10),
          windowEndExclusive: DateTime(2024, 3, 11),
        );

        if (springsForwardOnMar10()) {
          // 02:00 is skipped, so the sequence becomes 00:00, 03:00, 05:00.
          expect(events, hasLength(3));
          expect(events[0].scheduledAt, DateTime(2024, 3, 10));
          expect(events[1].scheduledAt, DateTime(2024, 3, 10, 3));
          expect(events[2].scheduledAt, DateTime(2024, 3, 10, 5));
        } else {
          expect(events, hasLength(4));
          expect(events[0].scheduledAt, DateTime(2024, 3, 10));
          expect(events[1].scheduledAt, DateTime(2024, 3, 10, 2));
          expect(events[2].scheduledAt, DateTime(2024, 3, 10, 4));
          expect(events[3].scheduledAt, DateTime(2024, 3, 10, 6));
        }
      });
    });

    group('event properties', () {
      test('all events have pending status and correct metadata', () {
        final schedule = Schedule.daily(
          id: 30,
          medicationId: 42,
          timesOfDay: const [(hour: 8, minute: 0)],
          startDate: DateTime(2024, 6, 10),
        );

        final events = expander.expand(
          schedule: schedule,
          windowStartInclusive: DateTime(2024, 6, 10),
          windowEndExclusive: DateTime(2024, 6, 11),
        );

        expect(events.single.id, 0);
        expect(events.single.medicationId, 42);
        expect(events.single.scheduleId, 30);
        expect(events.single.status.name, 'pending');
      });

      test('events are sorted by scheduledAt', () {
        final schedule = Schedule.daily(
          id: 30,
          medicationId: 42,
          timesOfDay: const [(hour: 20, minute: 0), (hour: 8, minute: 0)],
          startDate: DateTime(2024, 6, 10),
        );

        final events = expander.expand(
          schedule: schedule,
          windowStartInclusive: DateTime(2024, 6, 10),
          windowEndExclusive: DateTime(2024, 6, 12),
        );

        expect(events[0].scheduledAt, DateTime(2024, 6, 10, 8));
        expect(events[1].scheduledAt, DateTime(2024, 6, 10, 20));
        expect(events[2].scheduledAt, DateTime(2024, 6, 11, 8));
        expect(events[3].scheduledAt, DateTime(2024, 6, 11, 20));
      });
    });
  });
}
