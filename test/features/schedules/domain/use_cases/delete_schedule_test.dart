import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/features/schedules/domain/repositories/schedule_repository.dart';
import 'package:my_pills/features/schedules/domain/use_cases/delete_schedule.dart';

class MockScheduleRepository extends Mock implements ScheduleRepository {}

void main() {
  late MockScheduleRepository repository;
  late DeleteSchedule useCase;
  var onDeletedCalled = false;

  setUp(() {
    repository = MockScheduleRepository();
    onDeletedCalled = false;
    useCase = DeleteSchedule(
      repository,
      onDeleted: () async {
        onDeletedCalled = true;
      },
    );
  });

  group('DeleteSchedule', () {
    test(
      'delegates to repository and triggers onDeleted callback on success',
      () async {
        when(
          () => repository.delete(1),
        ).thenAnswer((_) async => const Result.success(null));

        final result = await useCase.call(1);

        expect(result.isSuccess, isTrue);
        expect(onDeletedCalled, isTrue);
        verify(() => repository.delete(1)).called(1);
      },
    );
  });
}
