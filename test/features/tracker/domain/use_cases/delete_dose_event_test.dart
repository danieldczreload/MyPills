import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/features/tracker/domain/repositories/dose_event_repository.dart';
import 'package:my_pills/features/tracker/domain/use_cases/delete_dose_event.dart';

class MockDoseEventRepository extends Mock implements DoseEventRepository {}

void main() {
  late MockDoseEventRepository repository;
  late DeleteDoseEvent useCase;

  setUp(() {
    repository = MockDoseEventRepository();
    useCase = DeleteDoseEvent(repository);
  });

  group('DeleteDoseEvent', () {
    test('delegates to repository delete', () async {
      when(
        () => repository.delete(1),
      ).thenAnswer((_) async => const Result.success(null));

      final result = await useCase.call(1);

      expect(result.isSuccess, isTrue);
      verify(() => repository.delete(1)).called(1);
    });
  });
}
