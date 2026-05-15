import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/features/medications/domain/entities/medication.dart';
import 'package:my_pills/features/medications/domain/repositories/medication_repository.dart';

/// Returns every medication in the catalog.
class ListMedications {
  const ListMedications(this._repository);

  final MedicationRepository _repository;

  Future<Result<List<Medication>>> call() => _repository.getAll();
}
