import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/features/tracker/domain/use_cases/mark_dose_missed.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockDoseEventRepository repository;
  late MarkDoseMissed useCase;

  setUpAll(registerFallbackValues);

  setUp(() {
    repository = MockDoseEventRepository();
    useCase = MarkDoseMissed(repository);
  });

  group('MarkDoseMissed', () {
    test('delegates to repository.markMissed', () async {
      when(() => repository.markMissed(any())).thenAnswer(
        (_) async => const Result.success(null),
      );

      final result = await useCase(42);

      expect(result, const Result<void>.success(null));
      verify(() => repository.markMissed(42)).called(1);
    });
  });
}
