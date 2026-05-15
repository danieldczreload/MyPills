import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/features/tracker/domain/use_cases/mark_dose_taken.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockDoseEventRepository repository;
  late MarkDoseTaken useCase;

  setUpAll(registerFallbackValues);

  setUp(() {
    repository = MockDoseEventRepository();
  });

  group('MarkDoseTaken', () {
    test('uses clock for takenAt timestamp', () async {
      final fixedNow = DateTime(2024, 6, 15, 10, 30);
      useCase = MarkDoseTaken(repository, clock: () => fixedNow);
      when(() => repository.markTaken(any(), any())).thenAnswer(
        (_) async => const Result.success(null),
      );

      final result = await useCase(42);

      expect(result, const Result<void>.success(null));
      verify(() => repository.markTaken(42, fixedNow)).called(1);
    });
  });
}
