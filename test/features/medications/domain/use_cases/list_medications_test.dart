import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/features/medications/domain/entities/medication.dart';
import 'package:my_pills/features/medications/domain/use_cases/list_medications.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockMedicationRepository repository;
  late ListMedications useCase;

  setUpAll(registerFallbackValues);

  setUp(() {
    repository = MockMedicationRepository();
    useCase = ListMedications(repository);
  });

  group('ListMedications', () {
    test('delegates to repository.getAll', () async {
      const medications = <Medication>[];
      when(() => repository.getAll()).thenAnswer(
        (_) async => const Result.success(medications),
      );

      final result = await useCase();

      expect(result, const Result<List<Medication>>.success(medications));
      verify(() => repository.getAll()).called(1);
    });
  });
}
