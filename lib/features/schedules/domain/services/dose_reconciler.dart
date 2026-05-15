import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/core/utils/clock.dart';
import 'package:my_pills/features/schedules/domain/repositories/schedule_repository.dart';
import 'package:my_pills/features/schedules/domain/services/schedule_expander.dart';
import 'package:my_pills/features/tracker/domain/repositories/dose_event_repository.dart';

/// Materializes and reconciles pending dose events for upcoming days.
///
/// It keeps user-updated statuses (`taken` / `missed`) intact and only mutates
/// pending projections created by the schedule engine.
class DoseReconciler {
  DoseReconciler({
    required ScheduleRepository scheduleRepository,
    required DoseEventRepository doseEventRepository,
    required ScheduleExpander expander,
    Clock? clock,
    this.windowDays = 14,
    this.onReconciled,
  }) : _scheduleRepository = scheduleRepository,
       _doseEventRepository = doseEventRepository,
       _expander = expander,
       _clock = clock ?? DateTime.now;

  final ScheduleRepository _scheduleRepository;
  final DoseEventRepository _doseEventRepository;
  final ScheduleExpander _expander;
  final Clock _clock;
  final int windowDays;
  final Future<void> Function()? onReconciled;

  Future<Result<void>> reconcileUpcoming() async {
    final schedulesResult = await _scheduleRepository.getAll();
    if (schedulesResult case FailureResult(:final failure)) {
      return Result.failure(failure);
    }

    final schedules = schedulesResult.valueOrNull!;
    final now = _clock();
    final windowStart = DateTime(now.year, now.month, now.day);
    final windowEndExclusive = windowStart.add(Duration(days: windowDays));

    for (final schedule in schedules) {
      final expectedEvents = _expander.expand(
        schedule: schedule,
        windowStartInclusive: windowStart,
        windowEndExclusive: windowEndExclusive,
      );

      final reconcileResult = await _doseEventRepository
          .reconcilePendingForSchedule(
            medicationId: schedule.medicationId,
            scheduleId: schedule.id,
            rangeStartUtc: windowStart.toUtc(),
            rangeEndExclusiveUtc: windowEndExclusive.toUtc(),
            expectedScheduledAt: expectedEvents
                .map((event) => event.scheduledAt.toUtc())
                .toList(growable: false),
          );

      if (reconcileResult case FailureResult(:final failure)) {
        return Result.failure(failure);
      }
    }

    if (onReconciled != null) {
      await onReconciled!();
    }

    return const Result<void>.success(null);
  }
}
