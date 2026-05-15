import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/features/timeline/domain/use_cases/get_timeline_range.dart';
import 'package:my_pills/features/tracker/domain/entities/dose_event.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockTimelineRepository repository;
  late GetTimelineRange useCase;

  setUpAll(registerFallbackValues);

  setUp(() {
    repository = MockTimelineRepository();
    useCase = GetTimelineRange(repository);
  });

  group('GetTimelineRange', () {
    test('normalizes start and end dates to midnight', () async {
      final start = DateTime(2024, 6, 10, 14, 30);
      final end = DateTime(2024, 6, 20, 8, 15);
      const doses = <DoseEvent>[];

      when(() => repository.getForDateRange(any(), any())).thenAnswer(
        (_) async => const Result.success(doses),
      );

      final result = await useCase(start: start, end: end);

      expect(result, const Result<List<DoseEvent>>.success(doses));
      final captured = verify(
        () => repository.getForDateRange(captureAny(), captureAny()),
      ).captured;
      expect(captured[0], DateTime(2024, 6, 10));
      expect(captured[1], DateTime(2024, 6, 20));
    });
  });
}
