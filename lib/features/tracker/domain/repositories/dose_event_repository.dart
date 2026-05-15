import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/features/tracker/domain/entities/dose_event.dart';

/// Repository interface for dose-event persistence.
///
/// The data layer materializes rows via the schedule expander
/// and indexes them by `scheduledAt` for fast range queries.
abstract interface class DoseEventRepository {
  /// Returns dose events for a single calendar day (00:00–23:59 local time).
  Future<Result<List<DoseEvent>>> getForDate(DateTime date);

  /// Watches dose events for a single calendar day, emitting a new value
  /// whenever the underlying data changes.
  ///
  /// Use this with Riverpod's `StreamProvider` to drive the tracker screen
  /// reactively.
  Stream<Result<List<DoseEvent>>> watchForDate(DateTime date);

  /// Returns dose events within an inclusive date range.
  Future<Result<List<DoseEvent>>> getForDateRange(DateTime start, DateTime end);

  /// Marks a pending dose as taken at [takenAt].
  Future<Result<void>> markTaken(int id, DateTime takenAt);

  /// Marks a pending dose as missed.
  Future<Result<void>> markMissed(int id);

  /// Deletes a dose event by [id].
  Future<Result<void>> delete(int id);

  /// Reconciles pending materialized events for one schedule in a UTC range.
  ///
  /// Existing non-pending events are preserved. Pending events not present in
  /// [expectedScheduledAt] are removed; missing pending events are inserted.
  Future<Result<void>> reconcilePendingForSchedule({
    required int medicationId,
    required int scheduleId,
    required DateTime rangeStartUtc,
    required DateTime rangeEndExclusiveUtc,
    required List<DateTime> expectedScheduledAt,
  });

  /// Returns the current streak (consecutive days with all doses taken).
  Future<Result<int>> calculateStreak();

  /// Returns adherence percentage (taken / total) for the last 7 days.
  Future<Result<double>> calculateAdherence();
}
