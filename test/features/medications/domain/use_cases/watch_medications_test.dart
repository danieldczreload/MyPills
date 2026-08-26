import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/features/medications/domain/entities/medication.dart';
import 'package:my_pills/features/medications/domain/repositories/medication_repository.dart';
import 'package:my_pills/features/medications/domain/use_cases/watch_medications.dart';

class MockMedicationRepository extends Mock implements MedicationRepository {}

void main() {
  late MockMedicationRepository repository;
  late WatchMedications useCase;

  setUp(() {
    repository = MockMedicationRepository();
    useCase = WatchMedications(repository);
  });

  group('WatchMedications', () {
    const med = Medication(
      id: 1,
      name: 'Ibuprofeno',
      form: MedicationForm.pill,
      category: 'General',
      colorToken: 'sky',
    );

    test('delegates to repository watchAll', () async {
      when(
        () => repository.watchAll(),
      ).thenAnswer((_) => Stream.value(const Result.success([med])));

      final stream = useCase.call();
      expect(await stream.first, equals(const Result.success([med])));
      verify(() => repository.watchAll()).called(1);
    });
  });
}
