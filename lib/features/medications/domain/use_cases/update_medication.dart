import 'package:my_pills/core/errors/failure.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/features/medications/domain/entities/medication.dart';
import 'package:my_pills/features/medications/domain/repositories/medication_repository.dart';

/// Updates an existing medication after validating the input.
///
/// The caller must supply a [Medication] with a valid persisted id (`id > 0`).
/// Applies the same name and category rules as `AddMedication`.
class UpdateMedication {
  const UpdateMedication(this._repository);

  final MedicationRepository _repository;

  Future<Result<Medication>> call({
    required int id,
    required String name,
    required MedicationForm form,
    required String category,
    required String colorToken,
    String? notes,
  }) async {
    if (id <= 0) {
      return const Result.failure(
        Failure.validation(code: ValidationCode.invalidId),
      );
    }
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
      id: id,
      name: name.trim(),
      form: form,
      category: category.trim(),
      colorToken: colorToken,
      notes: _normalizeNotes(notes),
    );

    return _repository.update(medication);
  }

  String? _normalizeNotes(String? notes) {
    if (notes == null) return null;
    final trimmed = notes.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
