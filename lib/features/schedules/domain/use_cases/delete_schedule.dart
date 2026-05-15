import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/features/schedules/domain/repositories/schedule_repository.dart';

/// Removes a schedule and (via repository cascade) its future dose events.
/// After a successful delete, [onDeleted] is invoked so notification +
/// calendar state can be reconciled.
class DeleteSchedule {
  const DeleteSchedule(this._repository, {this.onDeleted});

  final ScheduleRepository _repository;
  final Future<void> Function()? onDeleted;

  Future<Result<void>> call(int id) async {
    final result = await _repository.delete(id);
    if (result is Success && onDeleted != null) {
      await onDeleted!();
    }
    return result;
  }
}
