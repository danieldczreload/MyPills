import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_pills/core/errors/failure.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/features/schedules/domain/entities/dose.dart';
import 'package:my_pills/features/schedules/domain/entities/schedule.dart';
import 'package:my_pills/features/schedules/domain/services/dose_reconciler.dart';
import 'package:my_pills/features/schedules/domain/use_cases/create_schedule.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockScheduleRepository repository;
  late MockDoseReconciler reconciler;
  late CreateSchedule useCase;

  setUpAll(registerFallbackValues);

  setUp(() {
    repository = MockScheduleRepository();
    reconciler = MockDoseReconciler();
    useCase = CreateSchedule(repository, reconciler: reconciler);
    when(() => reconciler.reconcileUpcoming()).thenAnswer(
      (_) async => const Result<void>.success(null),
    );
  });

  final startDate = DateTime(2024, 6);
  final endDate = DateTime(2024, 6, 10);
  const dose = Dose(amount: 400, unit: 'mg', display: '400 mg');

  group('CreateSchedule', () {
    test('returns invalidId when schedule.id != 0', () async {
      final schedule = Schedule.daily(
        id: 5,
        medicationId: 1,
        timesOfDay: const [(hour: 8, minute: 0)],
        startDate: startDate,
      );

      final result = await useCase(schedule);

      expect(
        result,
        const Result<Schedule>.failure(
          Failure.validation(code: ValidationCode.invalidId),
        ),
      );
      verifyNoMoreInteractions(repository);
    });

    group('DailySchedule', () {
      test('returns noTimesOfDay when empty', () async {
        final schedule = Schedule.daily(
          id: 0,
          medicationId: 1,
          timesOfDay: const [],
          startDate: startDate,
        );

        final result = await useCase(schedule);

        expect(
          result,
          const Result<Schedule>.failure(
            Failure.validation(code: ValidationCode.noTimesOfDay),
          ),
        );
      });

      test('returns invalidTime when hour out of range', () async {
        final schedule = Schedule.daily(
          id: 0,
          medicationId: 1,
          timesOfDay: const [(hour: 24, minute: 0)],
          startDate: startDate,
        );

        final result = await useCase(schedule);

        expect(
          result,
          const Result<Schedule>.failure(
            Failure.validation(code: ValidationCode.invalidTime),
          ),
        );
      });

      test(
        'returns endDateBeforeStartDate when endDate precedes startDate',
        () async {
          final schedule = Schedule.daily(
            id: 0,
            medicationId: 1,
            timesOfDay: const [(hour: 8, minute: 0)],
            startDate: endDate,
            endDate: startDate,
          );

          final result = await useCase(schedule);

          expect(
            result,
            const Result<Schedule>.failure(
              Failure.validation(code: ValidationCode.endDateBeforeStartDate),
            ),
          );
        },
      );

      test('delegates to repository on valid schedule', () async {
        final schedule = Schedule.daily(
          id: 0,
          medicationId: 1,
          timesOfDay: const [(hour: 8, minute: 0)],
          startDate: startDate,
          endDate: endDate,
          dose: dose,
        );
        final persisted = schedule.copyWith(id: 42);
        when(() => repository.create(any())).thenAnswer(
          (_) async => Result.success(persisted),
        );

        final result = await useCase(schedule);

        expect(result, Result<Schedule>.success(persisted));
        verify(() => reconciler.reconcileUpcoming()).called(1);
      });
    });

    group('DailyIntervalSchedule', () {
      test('returns invalidHoursInterval when everyHours <= 0', () async {
        final schedule = Schedule.dailyInterval(
          id: 0,
          medicationId: 1,
          everyHours: 0,
          startAt: (hour: 8, minute: 0),
          startDate: startDate,
        );

        final result = await useCase(schedule);

        expect(
          result,
          const Result<Schedule>.failure(
            Failure.validation(code: ValidationCode.invalidHoursInterval),
          ),
        );
      });

      test('returns invalidTimeRange when endAt is before startAt', () async {
        final schedule = Schedule.dailyInterval(
          id: 0,
          medicationId: 1,
          everyHours: 4,
          startAt: (hour: 12, minute: 0),
          endAt: (hour: 8, minute: 0),
          startDate: startDate,
        );

        final result = await useCase(schedule);

        expect(
          result,
          const Result<Schedule>.failure(
            Failure.validation(code: ValidationCode.invalidTimeRange),
          ),
        );
      });

      test('returns invalidTime when endAt is out of range', () async {
        final schedule = Schedule.dailyInterval(
          id: 0,
          medicationId: 1,
          everyHours: 4,
          startAt: (hour: 8, minute: 0),
          endAt: (hour: 24, minute: 0),
          startDate: startDate,
        );

        final result = await useCase(schedule);

        expect(
          result,
          const Result<Schedule>.failure(
            Failure.validation(code: ValidationCode.invalidTime),
          ),
        );
      });

      test('allows endAt equal to startAt (single dose per day)', () async {
        final schedule = Schedule.dailyInterval(
          id: 0,
          medicationId: 1,
          everyHours: 4,
          startAt: (hour: 8, minute: 0),
          endAt: (hour: 8, minute: 0),
          startDate: startDate,
          dose: dose,
        );
        when(() => repository.create(any())).thenAnswer(
          (_) async => Result.success(schedule.copyWith(id: 1)),
        );

        final result = await useCase(schedule);

        expect(result.isSuccess, isTrue);
      });

      test('delegates to repository on valid schedule', () async {
        final schedule = Schedule.dailyInterval(
          id: 0,
          medicationId: 1,
          everyHours: 4,
          startAt: (hour: 8, minute: 0),
          endAt: (hour: 20, minute: 0),
          startDate: startDate,
          dose: dose,
        );
        final persisted = schedule.copyWith(id: 42);
        when(() => repository.create(any())).thenAnswer(
          (_) async => Result.success(persisted),
        );

        final result = await useCase(schedule);

        expect(result, Result<Schedule>.success(persisted));
        verify(() => reconciler.reconcileUpcoming()).called(1);
      });
    });

    group('SpecificDaysSchedule', () {
      test('returns noDaysOfWeek when empty', () async {
        final schedule = Schedule.specificDays(
          id: 0,
          medicationId: 1,
          daysOfWeek: const [],
          timesOfDay: const [(hour: 8, minute: 0)],
          startDate: startDate,
        );

        final result = await useCase(schedule);

        expect(
          result,
          const Result<Schedule>.failure(
            Failure.validation(code: ValidationCode.noDaysOfWeek),
          ),
        );
      });

      test('returns invalidDayOfWeek when value outside 1–7', () async {
        final schedule = Schedule.specificDays(
          id: 0,
          medicationId: 1,
          daysOfWeek: const [1, 8],
          timesOfDay: const [(hour: 8, minute: 0)],
          startDate: startDate,
        );

        final result = await useCase(schedule);

        expect(
          result,
          const Result<Schedule>.failure(
            Failure.validation(code: ValidationCode.invalidDayOfWeek),
          ),
        );
      });

      test('delegates to repository on valid schedule', () async {
        final schedule = Schedule.specificDays(
          id: 0,
          medicationId: 1,
          daysOfWeek: const [1, 3, 5],
          timesOfDay: const [(hour: 9, minute: 0)],
          startDate: startDate,
          dose: dose,
        );
        final persisted = schedule.copyWith(id: 42);
        when(() => repository.create(any())).thenAnswer(
          (_) async => Result.success(persisted),
        );

        final result = await useCase(schedule);

        expect(result, Result<Schedule>.success(persisted));
        verify(() => reconciler.reconcileUpcoming()).called(1);
      });
    });

    test('returns created schedule even when reconciliation fails', () async {
      final schedule = Schedule.daily(
        id: 0,
        medicationId: 1,
        timesOfDay: const [(hour: 8, minute: 0)],
        startDate: startDate,
        dose: dose,
      );
      final persisted = schedule.copyWith(id: 42);
      when(
        () => repository.create(any()),
      ).thenAnswer((_) async => Result.success(persisted));
      when(() => reconciler.reconcileUpcoming()).thenAnswer(
        (_) async => const Result<void>.failure(Failure.conflict()),
      );

      final result = await useCase(schedule);

      expect(result, Result<Schedule>.success(persisted));
      verify(() => reconciler.reconcileUpcoming()).called(1);
    });

    test('returns doseRequired when dose is missing', () async {
      final schedule = Schedule.daily(
        id: 0,
        medicationId: 1,
        timesOfDay: const [(hour: 8, minute: 0)],
        startDate: startDate,
      );

      final result = await useCase(schedule);

      expect(
        result,
        const Result<Schedule>.failure(
          Failure.validation(code: ValidationCode.doseRequired),
        ),
      );
      verifyNoMoreInteractions(repository);
    });

    test('returns invalidDoseAmount when amount is not positive', () async {
      final schedule = Schedule.daily(
        id: 0,
        medicationId: 1,
        timesOfDay: const [(hour: 8, minute: 0)],
        startDate: startDate,
        dose: const Dose(amount: 0, unit: 'mg', display: '0 mg'),
      );

      final result = await useCase(schedule);

      expect(
        result,
        const Result<Schedule>.failure(
          Failure.validation(code: ValidationCode.invalidDoseAmount),
        ),
      );
      verifyNoMoreInteractions(repository);
    });
  });
}

class MockDoseReconciler extends Mock implements DoseReconciler {}
