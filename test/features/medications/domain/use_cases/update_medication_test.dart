import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_pills/core/errors/failure.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/features/medications/domain/entities/medication.dart';
import 'package:my_pills/features/medications/domain/use_cases/update_medication.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockMedicationRepository repository;
  late UpdateMedication useCase;

  setUpAll(registerFallbackValues);

  setUp(() {
    repository = MockMedicationRepository();
    useCase = UpdateMedication(repository);
  });

  group('UpdateMedication', () {
    test('returns invalidId when id is <= 0', () async {
      final result = await useCase(
        id: 0,
        name: 'Aspirin',
        form: MedicationForm.pill,
        category: 'Pain',
        colorToken: 'blue',
      );

      expect(
        result,
        const Result<Medication>.failure(
          Failure.validation(code: ValidationCode.invalidId),
        ),
      );
      verifyNoMoreInteractions(repository);
    });

    test('returns emptyMedicationName when name is blank', () async {
      final result = await useCase(
        id: 1,
        name: '  ',
        form: MedicationForm.pill,
        category: 'Pain',
        colorToken: 'blue',
      );

      expect(
        result,
        const Result<Medication>.failure(
          Failure.validation(code: ValidationCode.emptyMedicationName),
        ),
      );
    });

    test('returns emptyColorToken when colorToken is blank', () async {
      final result = await useCase(
        id: 1,
        name: 'Aspirin',
        form: MedicationForm.pill,
        category: 'Pain',
        colorToken: '  ',
      );

      expect(
        result,
        const Result<Medication>.failure(
          Failure.validation(code: ValidationCode.emptyColorToken),
        ),
      );
    });

    test('returns repository result on success', () async {
      const updated = Medication(
        id: 1,
        name: 'Aspirin',
        form: MedicationForm.pill,
        category: 'Pain',
        colorToken: 'blue',
      );
      when(() => repository.update(any())).thenAnswer(
        (_) async => const Result.success(updated),
      );

      final result = await useCase(
        id: 1,
        name: 'Aspirin',
        form: MedicationForm.pill,
        category: 'Pain',
        colorToken: 'blue',
      );

      expect(result, const Result<Medication>.success(updated));
      final captured =
          verify(() => repository.update(captureAny())).captured.single
              as Medication;
      expect(captured.id, 1);
    });
  });
}
