import 'package:freezed_annotation/freezed_annotation.dart';

part 'medication.freezed.dart';

/// Physical form of a medication.
///
/// Presentation layer maps enum values → localized labels via
/// `AppLocalizations` — never embed translated strings in the domain layer.
enum MedicationForm {
  pill,
  capsule,
  liquid,
  injection,
  drops,
  inhaler,
  patch,
  other,
}

/// A medication tracked by the user.
///
/// .NET analogue: an immutable `record` with validation performed by the
/// use case before construction.
///
/// **id sentinel convention:** a value of `0` means the entity has not yet
/// been persisted. Pass `id: 0` when creating a new [Medication] to hand to
/// `MedicationRepository.add`; the returned entity carries the real
/// repository-assigned id. Never store or display `id == 0` in the UI.
@freezed
abstract class Medication with _$Medication {
  const factory Medication({
    required int id,
    required String name,
    required MedicationForm form,
    required String category,
    required String colorToken,
    String? notes,
  }) = _Medication;
}
