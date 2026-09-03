import 'package:flutter_test/flutter_test.dart';
import 'package:my_pills/core/db/app_database.dart';
import 'package:my_pills/features/schedules/data/mappers/schedule_mapper.dart';
import 'package:my_pills/features/schedules/domain/entities/dose.dart';
import 'package:my_pills/features/schedules/domain/entities/schedule.dart';

void main() {
  group('ScheduleMapper', () {
    group('toScheduleEntity', () {
      test('rehydrates Daily schedule from row', () {
        final row = SchedulesTableData(
          id: 1,
          medicationId: 10,
          ruleType: 'daily',
          ruleJson:
              '{"timesOfDay":[{"hour":8,"minute":0},{"hour":20,"minute":30}]}',
          startDateUtc: DateTime(2024, 6, 10).toUtc(),
          endDateUtc: DateTime(2024, 6, 20).toUtc(),
          profileId: 'default',
          syncStatus: 'synced',
          isTombstone: false,
        );

        final entity = toScheduleEntity(row);

        expect(entity, isA<DailySchedule>());
        expect(entity.id, 1);
        expect(entity.medicationId, 10);
        expect(entity.startDate, DateTime(2024, 6, 10));
        expect(entity.endDate, DateTime(2024, 6, 20));
        final daily = entity as DailySchedule;
        expect(daily.timesOfDay, const [
          (hour: 8, minute: 0),
          (hour: 20, minute: 30),
        ]);
      });

      test('rehydrates DailyInterval schedule from row', () {
        final row = SchedulesTableData(
          id: 2,
          medicationId: 20,
          ruleType: 'daily_interval',
          ruleJson:
              '{"everyHours":4,"startAt":{"hour":8,"minute":0},'
              '"endAt":{"hour":20,"minute":0}}',
          startDateUtc: DateTime(2024, 6, 10).toUtc(),
          profileId: 'default',
          syncStatus: 'synced',
          isTombstone: false,
        );

        final entity = toScheduleEntity(row);

        expect(entity, isA<DailyIntervalSchedule>());
        final interval = entity as DailyIntervalSchedule;
        expect(interval.everyHours, 4);
        expect(interval.startAt, (hour: 8, minute: 0));
        expect(interval.endAt, (hour: 20, minute: 0));
        expect(interval.endDate, isNull);
      });

      test('rehydrates DailyInterval without endAt', () {
        final row = SchedulesTableData(
          id: 3,
          medicationId: 30,
          ruleType: 'daily_interval',
          ruleJson:
              '{"everyHours":6,"startAt":{"hour":22,"minute":0},"endAt":null}',
          startDateUtc: DateTime(2024, 6, 10).toUtc(),
          profileId: 'default',
          syncStatus: 'synced',
          isTombstone: false,
        );

        final entity = toScheduleEntity(row);

        expect(entity, isA<DailyIntervalSchedule>());
        final interval = entity as DailyIntervalSchedule;
        expect(interval.endAt, isNull);
      });

      test('rehydrates SpecificDays schedule from row', () {
        final row = SchedulesTableData(
          id: 4,
          medicationId: 40,
          ruleType: 'specific_days',
          ruleJson:
              '{"daysOfWeek":[1,3,5],"timesOfDay":[{"hour":9,"minute":0}]}',
          startDateUtc: DateTime(2024, 6, 10).toUtc(),
          endDateUtc: DateTime(2024, 7, 10).toUtc(),
          profileId: 'default',
          syncStatus: 'synced',
          isTombstone: false,
        );

        final entity = toScheduleEntity(row);

        expect(entity, isA<SpecificDaysSchedule>());
        final specific = entity as SpecificDaysSchedule;
        expect(specific.daysOfWeek, [1, 3, 5]);
        expect(specific.timesOfDay, const [(hour: 9, minute: 0)]);
        expect(specific.endDate, DateTime(2024, 7, 10));
      });

      test('rehydrates nullable dose as null', () {
        final row = SchedulesTableData(
          id: 1,
          medicationId: 10,
          ruleType: 'daily',
          ruleJson: '{"timesOfDay":[{"hour":8,"minute":0}]}',
          startDateUtc: DateTime(2024, 6, 10).toUtc(),
          profileId: 'default',
          syncStatus: 'synced',
          isTombstone: false,
        );

        final entity = toScheduleEntity(row);
        expect(entity.dose, isNull);
      });

      test('rehydrates dose object from columns', () {
        final row = SchedulesTableData(
          id: 1,
          medicationId: 10,
          ruleType: 'daily',
          ruleJson: '{"timesOfDay":[{"hour":8,"minute":0}]}',
          startDateUtc: DateTime(2024, 6, 10).toUtc(),
          doseAmount: 5,
          doseUnit: 'ml',
          doseDisplay: '5 ml',
          profileId: 'default',
          syncStatus: 'synced',
          isTombstone: false,
        );

        final entity = toScheduleEntity(row);
        expect(
          entity.dose,
          const Dose(amount: 5, unit: 'ml', display: '5 ml'),
        );
      });

      test('throws on unknown rule type', () {
        final row = SchedulesTableData(
          id: 5,
          medicationId: 50,
          ruleType: 'unknown',
          ruleJson: '{}',
          startDateUtc: DateTime(2024, 6, 10).toUtc(),
          profileId: 'default',
          syncStatus: 'synced',
          isTombstone: false,
        );

        expect(() => toScheduleEntity(row), throwsFormatException);
      });
    });

    group('toScheduleInsertCompanion', () {
      test('serializes Daily schedule', () {
        final schedule = Schedule.daily(
          id: 0,
          medicationId: 10,
          timesOfDay: const [(hour: 8, minute: 0)],
          startDate: DateTime(2024, 6, 10),
          endDate: DateTime(2024, 6, 20),
          dose: const Dose(amount: 400, unit: 'mg', display: '400 mg'),
        );

        final companion = toScheduleInsertCompanion(schedule);

        expect(companion.medicationId.value, 10);
        expect(companion.ruleType.value, 'daily');
        expect(
          companion.ruleJson.value,
          '{"timesOfDay":[{"hour":8,"minute":0}],"notifyPush":true,"notifyCalendar":false}',
        );
        expect(companion.startDateUtc.value, DateTime(2024, 6, 10).toUtc());
        expect(companion.endDateUtc.value, DateTime(2024, 6, 20).toUtc());
        expect(companion.doseAmount.value, 400);
        expect(companion.doseUnit.value, 'mg');
        expect(companion.doseDisplay.value, '400 mg');
      });

      test('serializes DailyInterval schedule with endAt', () {
        final schedule = Schedule.dailyInterval(
          id: 0,
          medicationId: 20,
          everyHours: 4,
          startAt: (hour: 8, minute: 0),
          endAt: (hour: 20, minute: 0),
          startDate: DateTime(2024, 6, 10),
        );

        final companion = toScheduleInsertCompanion(schedule);

        expect(companion.ruleType.value, 'daily_interval');
        expect(
          companion.ruleJson.value,
          '{"everyHours":4,"startAt":{"hour":8,"minute":0},'
          '"endAt":{"hour":20,"minute":0},"notifyPush":true,"notifyCalendar":false}',
        );
        expect(companion.endDateUtc.present, isTrue);
        expect(companion.endDateUtc.value, isNull);
      });

      test('serializes SpecificDays schedule', () {
        final schedule = Schedule.specificDays(
          id: 0,
          medicationId: 30,
          daysOfWeek: const [1, 3, 5],
          timesOfDay: const [(hour: 9, minute: 0)],
          startDate: DateTime(2024, 6, 10),
        );

        final companion = toScheduleInsertCompanion(schedule);

        expect(companion.ruleType.value, 'specific_days');
        expect(
          companion.ruleJson.value,
          '{"daysOfWeek":[1,3,5],"timesOfDay":[{"hour":9,"minute":0}],"notifyPush":true,"notifyCalendar":false}',
        );
      });
    });
  });
}
