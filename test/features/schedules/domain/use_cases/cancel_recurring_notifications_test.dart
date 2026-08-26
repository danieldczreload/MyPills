import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/features/schedules/domain/repositories/schedule_repository.dart';
import 'package:my_pills/features/schedules/domain/use_cases/cancel_recurring_notifications.dart';

class MockScheduleRepository extends Mock implements ScheduleRepository {}

void main() {
  late MockScheduleRepository repository;
  late CancelRecurringNotifications useCase;
  var onCancelledCalled = false;

  setUp(() {
    repository = MockScheduleRepository();
    onCancelledCalled = false;
    useCase = CancelRecurringNotifications(
      repository,
      onCancelled: () async {
        onCancelledCalled = true;
      },
    );
  });

  group('CancelRecurringNotifications', () {
    test(
      'delegates to repository and triggers onCancelled callback on success',
      () async {
        when(
          () => repository.cancelRecurring(scheduleId: 1),
        ).thenAnswer((_) async => const Result.success(null));

        final result = await useCase.call(scheduleId: 1);

        expect(result.isSuccess, isTrue);
        expect(onCancelledCalled, isTrue);
        verify(
          () => repository.cancelRecurring(scheduleId: 1),
        ).called(1);
      },
    );
  });
}
