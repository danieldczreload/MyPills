import 'package:mocktail/mocktail.dart';
import 'package:my_pills/core/errors/failure.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/features/medications/domain/entities/medication.dart';
import 'package:my_pills/features/medications/domain/repositories/medication_repository.dart';
import 'package:my_pills/features/schedules/domain/entities/schedule.dart';
import 'package:my_pills/features/schedules/domain/repositories/schedule_repository.dart';
import 'package:my_pills/features/timeline/domain/repositories/timeline_repository.dart';
import 'package:my_pills/features/tracker/domain/entities/dose_event.dart';
import 'package:my_pills/features/tracker/domain/repositories/dose_event_repository.dart';

class MockMedicationRepository extends Mock implements MedicationRepository {}

class MockScheduleRepository extends Mock implements ScheduleRepository {}

class MockDoseEventRepository extends Mock implements DoseEventRepository {}

class MockTimelineRepository extends Mock implements TimelineRepository {}

void registerFallbackValues() {
  registerFallbackValue(
    const Medication(
      id: 0,
      name: '',
      form: MedicationForm.pill,
      category: '',
      colorToken: '',
    ),
  );
  registerFallbackValue(
    Schedule.daily(
      id: 0,
      medicationId: 1,
      timesOfDay: const [],
      startDate: _epoch,
    ),
  );
  registerFallbackValue(
    DoseEvent(
      id: 0,
      medicationId: 1,
      scheduleId: 1,
      scheduledAt: _epoch,
      status: DoseStatus.pending,
    ),
  );
  registerFallbackValue(const Result.success(0));
  registerFallbackValue(const Failure.notFound());
  registerFallbackValue(_epoch);
}

final _epoch = DateTime.fromMillisecondsSinceEpoch(0);
