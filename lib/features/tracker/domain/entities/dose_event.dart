import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:my_pills/features/schedules/domain/entities/dose.dart';

part 'dose_event.freezed.dart';

/// Status of a single materialized dose occurrence.
enum DoseStatus {
  pending,
  taken,
  missed,
}

/// A concrete occurrence produced by the schedule expander.
///
/// This is the read-side projection the UI subscribes to.
/// .NET analogue: a materialized view row / read-model DTO.
@freezed
abstract class DoseEvent with _$DoseEvent {
  const factory DoseEvent({
    required int id,
    required int medicationId,
    required int scheduleId,
    required DateTime scheduledAt,
    required DoseStatus status,
    DateTime? takenAt,
    Dose? dose,
  }) = _DoseEvent;
}
