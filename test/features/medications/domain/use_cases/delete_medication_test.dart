import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_pills/core/errors/failure.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/features/medications/domain/use_cases/delete_medication.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockMedicationRepository repository;
  late DeleteMedication useCase;

  setUpAll(registerFallbackValues);

  setUp(() {
    repository = MockMedicationRepository();
    useCase = DeleteMedication(repository);
  });

  group('DeleteMedication', () {
    test('returns invalidId when id is <= 0', () async {
      final result = await useCase(0);

      expect(
        result,
        const Result<void>.failure(
          Failure.validation(code: ValidationCode.invalidId),
        ),
      );
      verifyNoMoreInteractions(repository);
    });

    test('delegates to repository.delete on success', () async {
      when(() => repository.delete(any())).thenAnswer(
        (_) async => const Result.success(null),
      );

      final result = await useCase(1);

      expect(result, const Result<void>.success(null));
      verify(() => repository.delete(1)).called(1);
    });
  });
}
