import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/features/medications/domain/entities/medication.dart';

/// Repository interface for medication persistence.
///
/// .NET analogue: a repository interface in the domain layer —
/// implemented by the data layer (Drift DAO + mapper).
abstract interface class MedicationRepository {
  /// Returns all medications sorted by name.
  Future<Result<List<Medication>>> getAll();

  /// Watches all medications sorted by name, emitting a new value whenever
  /// the underlying data changes.
  ///
  /// Use this with Riverpod's `StreamProvider` to keep the UI reactive
  /// without polling.
  Stream<Result<List<Medication>>> watchAll();

  /// Returns a single medication by [id] or a not-found failure.
  Future<Result<Medication>> getById(int id);

  /// Persists a new medication.
  ///
  /// The [medication] must carry `id == 0` (the unassigned sentinel); the
  /// returned entity contains the repository-assigned id.
  Future<Result<Medication>> add(Medication medication);

  /// Replaces the stored medication with [medication].
  ///
  /// The [medication] must carry a valid persisted id (`id > 0`).
  /// Returns the updated entity, or `Failure.notFound` if the id does not
  /// exist.
  Future<Result<Medication>> update(Medication medication);

  /// Removes the medication by [id].
  ///
  /// Callers should use the `DeleteMedication` use case, which also
  /// orchestrates cascading removal of related schedules and dose events.
  Future<Result<void>> delete(int id);
}
