import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/features/tracker/domain/entities/dose_event.dart';
import 'package:my_pills/features/tracker/domain/use_cases/get_today_doses.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockDoseEventRepository repository;
  late GetTodayDoses useCase;

  setUpAll(registerFallbackValues);

  setUp(() {
    repository = MockDoseEventRepository();
  });

  group('GetTodayDoses', () {
    test('uses clock and strips time when date is omitted', () async {
      final now = DateTime(2024, 6, 15, 14, 30);
      final expectedDay = DateTime(2024, 6, 15);
      const doses = <DoseEvent>[];

      useCase = GetTodayDoses(repository, clock: () => now);
      when(() => repository.getForDate(any())).thenAnswer(
        (_) async => const Result.success(doses),
      );

      final result = await useCase();

      expect(result, const Result<List<DoseEvent>>.success(doses));
      final captured =
          verify(() => repository.getForDate(captureAny())).captured.single
              as DateTime;
      expect(captured, expectedDay);
    });

    test('strips time from explicit date parameter', () async {
      final explicit = DateTime(2024, 6, 20, 23, 59);
      final expectedDay = DateTime(2024, 6, 20);
      const doses = <DoseEvent>[];

      useCase = GetTodayDoses(repository);
      when(() => repository.getForDate(any())).thenAnswer(
        (_) async => const Result.success(doses),
      );

      final result = await useCase(date: explicit);

      expect(result, const Result<List<DoseEvent>>.success(doses));
      final captured =
          verify(() => repository.getForDate(captureAny())).captured.single
              as DateTime;
      expect(captured, expectedDay);
    });
  });
}
