import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/features/timeline/domain/repositories/timeline_repository.dart';
import 'package:my_pills/features/timeline/domain/use_cases/watch_timeline_range.dart';
import 'package:my_pills/features/tracker/domain/entities/dose_event.dart';

class MockTimelineRepository extends Mock implements TimelineRepository {}

void main() {
  late MockTimelineRepository repository;
  late WatchTimelineRange useCase;

  setUp(() {
    repository = MockTimelineRepository();
    useCase = WatchTimelineRange(repository);
  });

  group('WatchTimelineRange', () {
    final start = DateTime(2026, 8);
    final end = DateTime(2026, 8, 31);
    final dose = DoseEvent(
      id: 1,
      medicationId: 10,
      scheduleId: 20,
      scheduledAt: DateTime(2026, 8, 13, 8),
      status: DoseStatus.pending,
    );

    test('delegates to repository watchForDateRange', () async {
      when(
        () => repository.watchForDateRange(start, end),
      ).thenAnswer((_) => Stream.value(Result.success([dose])));

      final stream = useCase.call(start: start, end: end);
      expect(await stream.first, equals(Result.success([dose])));
      verify(() => repository.watchForDateRange(start, end)).called(1);
    });
  });
}
