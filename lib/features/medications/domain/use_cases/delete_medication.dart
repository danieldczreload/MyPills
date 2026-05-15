import 'package:my_pills/core/errors/failure.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/features/medications/domain/repositories/medication_repository.dart';

/// Removes a medication by id.
///
/// The data-layer implementation of `MedicationRepository.delete` is
/// responsible for cascading removal of related schedules and dose events
/// (e.g., via a Drift transaction). After a successful delete, [onDeleted]
/// is invoked so OS-level notifications and calendar events can be cleaned.
class DeleteMedication {
  const DeleteMedication(this._repository, {this.onDeleted});

  final MedicationRepository _repository;
  final Future<void> Function()? onDeleted;

  Future<Result<void>> call(int id) async {
    if (id <= 0) {
      return const Result.failure(
        Failure.validation(code: ValidationCode.invalidId),
      );
    }
    final result = await _repository.delete(id);
    if (result is Success && onDeleted != null) {
      await onDeleted!();
    }
    return result;
  }
}
