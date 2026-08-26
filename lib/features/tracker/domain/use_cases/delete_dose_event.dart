import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/features/tracker/domain/repositories/dose_event_repository.dart';

/// Deletes a dose event (silences the alert and cancels local alarms / calendar events).
class DeleteDoseEvent {
  const DeleteDoseEvent(this._repository, {this.onDeleted});

  final DoseEventRepository _repository;
  final Future<void> Function(int id)? onDeleted;

  Future<Result<void>> call(int id) async {
    final result = await _repository.delete(id);
    if (result is Success && onDeleted != null) {
      await onDeleted!(id);
    }
    return result;
  }
}
