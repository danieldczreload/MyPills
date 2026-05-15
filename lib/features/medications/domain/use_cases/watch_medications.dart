import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/features/medications/domain/entities/medication.dart';
import 'package:my_pills/features/medications/domain/repositories/medication_repository.dart';

/// Watches medications sorted by name for reactive presentation updates.
class WatchMedications {
  const WatchMedications(this._repository);

  final MedicationRepository _repository;

  Stream<Result<List<Medication>>> call() => _repository.watchAll();
}
