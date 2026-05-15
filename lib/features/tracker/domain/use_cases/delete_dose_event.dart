import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/features/tracker/domain/repositories/dose_event_repository.dart';

/// Deletes a dose event (silences the alert).
class DeleteDoseEvent {
  const DeleteDoseEvent(this._repository);

  final DoseEventRepository _repository;

  Future<Result<void>> call(int id) => _repository.delete(id);
}
