import 'package:my_pills/core/errors/failure.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/features/medications/domain/entities/medication.dart';
import 'package:my_pills/features/medications/domain/repositories/medication_repository.dart';

/// Adds a new medication after validating the input.
///
/// The id on the returned [Medication] is assigned by the repository
/// (id 0 is the conventional "unassigned" sentinel passed to `add`).
class AddMedication {
  const AddMedication(this._repository);

  final MedicationRepository _repository;

  Future<Result<Medication>> call({
    required String name,
    required MedicationForm form,
    required String category,
    required String colorToken,
    String? notes,
  }) async {
    if (name.trim().isEmpty) {
      return const Result.failure(
        Failure.validation(code: ValidationCode.emptyMedicationName),
      );
    }
    if (category.trim().isEmpty) {
      return const Result.failure(
        Failure.validation(code: ValidationCode.emptyCategory),
      );
    }
    if (colorToken.trim().isEmpty) {
      return const Result.failure(
        Failure.validation(code: ValidationCode.emptyColorToken),
      );
    }

    final medication = Medication(
      id: 0, // sentinel: repository assigns the real id on insert
      name: name.trim(),
      form: form,
      category: category.trim(),
      colorToken: colorToken,
      notes: _normalizeNotes(notes),
    );

    return _repository.add(medication);
  }

  /// Trims [notes] and returns `null` when the result is empty.
  ///
  /// Ensures the domain never stores a whitespace-only notes string; callers
  /// receive an unambiguous `null` instead of `''`.
  String? _normalizeNotes(String? notes) {
    if (notes == null) return null;
    final trimmed = notes.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
