import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_pills/core/errors/failure.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/features/schedules/domain/entities/schedule.dart';
import 'package:my_pills/features/schedules/domain/services/dose_reconciler.dart';
import 'package:my_pills/features/schedules/domain/services/schedule_expander.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockScheduleRepository scheduleRepository;
  late MockDoseEventRepository doseEventRepository;
  late DoseReconciler reconciler;

  setUpAll(registerFallbackValues);

  setUp(() {
    scheduleRepository = MockScheduleRepository();
    doseEventRepository = MockDoseEventRepository();
    reconciler = DoseReconciler(
      scheduleRepository: scheduleRepository,
      doseEventRepository: doseEventRepository,
      expander: const ScheduleExpander(),
      clock: () => DateTime(2024, 6, 10, 9),
      windowDays: 2,
    );
  });

  group('DoseReconciler', () {
    test('reconciles each schedule for the upcoming window', () async {
      final schedules = [
        Schedule.daily(
          id: 1,
          medicationId: 10,
          timesOfDay: const [(hour: 8, minute: 0), (hour: 20, minute: 0)],
          startDate: DateTime(2024, 6),
        ),
        Schedule.specificDays(
          id: 2,
          medicationId: 20,
          daysOfWeek: const [1],
          timesOfDay: const [(hour: 9, minute: 0)],
          startDate: DateTime(2024, 6),
        ),
      ];

      when(
        () => scheduleRepository.getAll(),
      ).thenAnswer((_) async => Result.success(schedules));
      when(
        () => doseEventRepository.reconcilePendingForSchedule(
          medicationId: any(named: 'medicationId'),
          scheduleId: any(named: 'scheduleId'),
          rangeStartUtc: any(named: 'rangeStartUtc'),
          rangeEndExclusiveUtc: any(named: 'rangeEndExclusiveUtc'),
          expectedScheduledAt: any(named: 'expectedScheduledAt'),
        ),
      ).thenAnswer((_) async => const Result<void>.success(null));

      final result = await reconciler.reconcileUpcoming();

      expect(result, const Result<void>.success(null));
      verify(() => scheduleRepository.getAll()).called(1);

      verify(
        () => doseEventRepository.reconcilePendingForSchedule(
          medicationId: 10,
          scheduleId: 1,
          rangeStartUtc: DateTime(2024, 6, 10).toUtc(),
          rangeEndExclusiveUtc: DateTime(2024, 6, 12).toUtc(),
          expectedScheduledAt: [
            DateTime(2024, 6, 10, 8).toUtc(),
            DateTime(2024, 6, 10, 20).toUtc(),
            DateTime(2024, 6, 11, 8).toUtc(),
            DateTime(2024, 6, 11, 20).toUtc(),
          ],
        ),
      ).called(1);

      verify(
        () => doseEventRepository.reconcilePendingForSchedule(
          medicationId: 20,
          scheduleId: 2,
          rangeStartUtc: DateTime(2024, 6, 10).toUtc(),
          rangeEndExclusiveUtc: DateTime(2024, 6, 12).toUtc(),
          expectedScheduledAt: [DateTime(2024, 6, 10, 9).toUtc()],
        ),
      ).called(1);
    });

    test('returns schedule repository failure', () async {
      when(() => scheduleRepository.getAll()).thenAnswer(
        (_) async => const Result<List<Schedule>>.failure(Failure.notFound()),
      );

      final result = await reconciler.reconcileUpcoming();

      expect(result, const Result<void>.failure(Failure.notFound()));
      verifyNever(
        () => doseEventRepository.reconcilePendingForSchedule(
          medicationId: any(named: 'medicationId'),
          scheduleId: any(named: 'scheduleId'),
          rangeStartUtc: any(named: 'rangeStartUtc'),
          rangeEndExclusiveUtc: any(named: 'rangeEndExclusiveUtc'),
          expectedScheduledAt: any(named: 'expectedScheduledAt'),
        ),
      );
    });

    test('returns reconciliation failure from dose-event repository', () async {
      final schedule = Schedule.daily(
        id: 1,
        medicationId: 10,
        timesOfDay: const [(hour: 8, minute: 0)],
        startDate: DateTime(2024, 6),
      );
      when(
        () => scheduleRepository.getAll(),
      ).thenAnswer((_) async => Result.success([schedule]));
      when(
        () => doseEventRepository.reconcilePendingForSchedule(
          medicationId: any(named: 'medicationId'),
          scheduleId: any(named: 'scheduleId'),
          rangeStartUtc: any(named: 'rangeStartUtc'),
          rangeEndExclusiveUtc: any(named: 'rangeEndExclusiveUtc'),
          expectedScheduledAt: any(named: 'expectedScheduledAt'),
        ),
      ).thenAnswer((_) async => const Result<void>.failure(Failure.conflict()));

      final result = await reconciler.reconcileUpcoming();

      expect(result, const Result<void>.failure(Failure.conflict()));
    });
  });
}
