import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/features/schedules/domain/repositories/schedule_repository.dart';

/// Use case to cancel recurring notifications (Firebase Push & Google/Outlook Calendars)
/// for a schedule or all schedules of a medication.
class CancelRecurringNotifications {
  const CancelRecurringNotifications(
    this._repository, {
    this.onCancelled,
  });

  final ScheduleRepository _repository;
  final Future<void> Function()? onCancelled;

  Future<Result<void>> call({
    int? scheduleId,
    int? medicationId,
    bool cancelPush = true,
    bool cancelCalendar = true,
    bool deleteSchedule = false,
  }) async {
    final result = await _repository.cancelRecurring(
      scheduleId: scheduleId,
      medicationId: medicationId,
      cancelPush: cancelPush,
      cancelCalendar: cancelCalendar,
      deleteSchedule: deleteSchedule,
    );
    if (result is Success && onCancelled != null) {
      await onCancelled!();
    }
    return result;
  }
}
