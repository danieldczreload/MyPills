import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/features/tracker/domain/entities/dose_event.dart';

/// Repository interface for timeline queries.
///
/// Declared in the `timeline` feature so `GetTimelineRange` depends only on
/// this contract — not on the `tracker` feature's `DoseEventRepository`.
/// The data-layer implementation backs both interfaces with the same DAO.
///
/// NOTE: `DoseEvent` is imported from `tracker` because it is the shared
/// read-model projection. If `DoseEvent` grows beyond tracker concerns it
/// should be promoted to `core/domain/`.
abstract interface class TimelineRepository {
  /// Returns all dose events within the inclusive [start]–[end] date range.
  Future<Result<List<DoseEvent>>> getForDateRange(
    DateTime start,
    DateTime end,
  );

  /// Watches dose events within the inclusive [start]–[end] date range,
  /// emitting a new value whenever the underlying data changes.
  Stream<Result<List<DoseEvent>>> watchForDateRange(
    DateTime start,
    DateTime end,
  );
}
