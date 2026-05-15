import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/features/tracker/domain/entities/dose_event.dart';
import 'package:my_pills/features/tracker/domain/use_cases/watch_today_doses.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockDoseEventRepository repository;
  late WatchTodayDoses useCase;

  setUpAll(registerFallbackValues);

  setUp(() {
    repository = MockDoseEventRepository();
  });

  group('WatchTodayDoses', () {
    test('uses clock and strips time when date is omitted', () {
      final now = DateTime(2024, 6, 15, 14, 30);
      final expectedDay = DateTime(2024, 6, 15);
      const doses = <DoseEvent>[];

      useCase = WatchTodayDoses(repository, clock: () => now);
      when(() => repository.watchForDate(any())).thenAnswer(
        (_) => Stream.value(const Result.success(doses)),
      );

      final stream = useCase();

      expect(stream, emits(const Result<List<DoseEvent>>.success(doses)));
      final captured =
          verify(() => repository.watchForDate(captureAny())).captured.single
              as DateTime;
      expect(captured, expectedDay);
    });

    test('strips time from explicit date parameter', () {
      final explicit = DateTime(2024, 6, 20, 23, 59);
      final expectedDay = DateTime(2024, 6, 20);
      const doses = <DoseEvent>[];

      useCase = WatchTodayDoses(repository);
      when(() => repository.watchForDate(any())).thenAnswer(
        (_) => Stream.value(const Result.success(doses)),
      );

      final stream = useCase(date: explicit);

      expect(stream, emits(const Result<List<DoseEvent>>.success(doses)));
      final captured =
          verify(() => repository.watchForDate(captureAny())).captured.single
              as DateTime;
      expect(captured, expectedDay);
    });
  });
}
