import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_pills/core/errors/failure.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/features/medications/domain/entities/medication.dart';
import 'package:my_pills/features/medications/domain/use_cases/add_medication.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockMedicationRepository repository;
  late AddMedication useCase;

  setUpAll(registerFallbackValues);

  setUp(() {
    repository = MockMedicationRepository();
    useCase = AddMedication(repository);
  });

  group('AddMedication', () {
    test('returns emptyMedicationName when name is blank', () async {
      final result = await useCase(
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
      verifyNoMoreInteractions(repository);
    });

    test('returns emptyCategory when category is blank', () async {
      final result = await useCase(
        name: 'Aspirin',
        form: MedicationForm.pill,
        category: '  ',
        colorToken: 'blue',
      );

      expect(
        result,
        const Result<Medication>.failure(
          Failure.validation(code: ValidationCode.emptyCategory),
        ),
      );
      verifyNoMoreInteractions(repository);
    });

    test('returns emptyColorToken when colorToken is blank', () async {
      final result = await useCase(
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
      verifyNoMoreInteractions(repository);
    });

    test('normalizes whitespace-only notes to null', () async {
      const expected = Medication(
        id: 0,
        name: 'Aspirin',
        form: MedicationForm.pill,
        category: 'Pain',
        colorToken: 'blue',
      );
      when(() => repository.add(any())).thenAnswer(
        (_) async => const Result.success(expected),
      );

      final result = await useCase(
        name: 'Aspirin',
        form: MedicationForm.pill,
        category: 'Pain',
        colorToken: 'blue',
        notes: '   ',
      );

      expect(result, const Result<Medication>.success(expected));
      final captured =
          verify(() => repository.add(captureAny())).captured.single
              as Medication;
      expect(captured.notes, isNull);
    });

    test('trims name and category', () async {
      const returned = Medication(
        id: 1,
        name: 'Aspirin',
        form: MedicationForm.pill,
        category: 'Pain',
        colorToken: 'blue',
      );
      when(() => repository.add(any())).thenAnswer(
        (_) async => const Result.success(returned),
      );

      await useCase(
        name: '  Aspirin  ',
        form: MedicationForm.pill,
        category: '  Pain  ',
        colorToken: 'blue',
      );

      final captured =
          verify(() => repository.add(captureAny())).captured.single
              as Medication;
      expect(captured.name, 'Aspirin');
      expect(captured.category, 'Pain');
    });

    test('returns repository result on success', () async {
      const medication = Medication(
        id: 1,
        name: 'Aspirin',
        form: MedicationForm.pill,
        category: 'Pain',
        colorToken: 'blue',
      );
      when(() => repository.add(any())).thenAnswer(
        (_) async => const Result.success(medication),
      );

      final result = await useCase(
        name: 'Aspirin',
        form: MedicationForm.pill,
        category: 'Pain',
        colorToken: 'blue',
      );

      expect(result, const Result<Medication>.success(medication));
    });
  });
}
