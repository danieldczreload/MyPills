import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/features/timeline/domain/repositories/timeline_repository.dart';
import 'package:my_pills/features/tracker/domain/entities/dose_event.dart';

/// Watches dose events across a date range for the timeline screen.
class WatchTimelineRange {
  const WatchTimelineRange(this._repository);

  final TimelineRepository _repository;

  Stream<Result<List<DoseEvent>>> call({
    required DateTime start,
    required DateTime end,
  }) {
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    return _repository.watchForDateRange(s, e);
  }
}
