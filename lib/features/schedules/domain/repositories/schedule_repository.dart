import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/features/schedules/domain/entities/schedule.dart';

/// Repository interface for schedule persistence.
///
/// The data layer stores rules as JSON + a discriminator column
/// and maps back to the sealed [Schedule] entity.
abstract interface class ScheduleRepository {
  /// Returns all schedules.
  Future<Result<List<Schedule>>> getAll();

  /// Watches all schedules, emitting a new value whenever the underlying
  /// data changes.
  ///
  /// Use this with Riverpod's `StreamProvider` to keep the UI reactive.
  Stream<Result<List<Schedule>>> watchAll();

  /// Returns a single schedule by [id] or a not-found failure.
  Future<Result<Schedule>> getById(int id);

  /// Persists a new schedule. The returned entity contains the assigned ID.
  Future<Result<Schedule>> create(Schedule schedule);

  /// Removes the schedule and all related future dose events.
  Future<Result<void>> delete(int id);
}
