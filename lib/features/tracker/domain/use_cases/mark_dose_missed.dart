import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/features/tracker/domain/repositories/dose_event_repository.dart';

/// Marks a dose as missed.
class MarkDoseMissed {
  const MarkDoseMissed(this._repository);

  final DoseEventRepository _repository;

  Future<Result<void>> call(int id) => _repository.markMissed(id);
}
