import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_pills/core/db/app_database.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/features/medications/data/repositories/drift_medication_repository.dart';
import 'package:my_pills/features/medications/domain/repositories/medication_repository.dart';
import 'package:my_pills/features/medications/domain/use_cases/add_medication.dart';
import 'package:my_pills/features/medications/domain/use_cases/delete_medication.dart';
import 'package:my_pills/features/medications/domain/use_cases/update_medication.dart';
import 'package:my_pills/features/medications/domain/use_cases/watch_medications.dart';
import 'package:my_pills/features/notifications/domain/use_cases/sync_notifications.dart';
import 'package:my_pills/features/notifications/presentation/providers/notification_providers.dart';
import 'package:my_pills/features/schedules/data/repositories/drift_schedule_repository.dart';
import 'package:my_pills/features/schedules/domain/repositories/schedule_repository.dart';
import 'package:my_pills/features/schedules/domain/services/dose_reconciler.dart';
import 'package:my_pills/features/schedules/domain/services/schedule_expander.dart';
import 'package:my_pills/features/schedules/domain/entities/schedule.dart';
import 'package:my_pills/features/schedules/domain/use_cases/create_schedule.dart';
import 'package:my_pills/features/schedules/domain/use_cases/delete_schedule.dart';
import 'package:my_pills/features/timeline/domain/repositories/timeline_repository.dart';
import 'package:my_pills/features/timeline/domain/use_cases/get_timeline_range.dart';
import 'package:my_pills/features/timeline/domain/use_cases/watch_timeline_range.dart';
import 'package:my_pills/features/tracker/data/repositories/drift_dose_event_repository.dart';
import 'package:my_pills/features/tracker/domain/repositories/dose_event_repository.dart';
import 'package:my_pills/features/tracker/domain/use_cases/delete_dose_event.dart';
import 'package:my_pills/features/tracker/domain/use_cases/mark_dose_missed.dart';
import 'package:my_pills/features/tracker/domain/use_cases/mark_dose_taken.dart';
import 'package:my_pills/features/tracker/domain/use_cases/watch_today_doses.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'providers.g.dart';

/// Provides the [SharedPreferences] singleton.
///
/// Must be overridden in [ProviderScope] after calling
/// [SharedPreferences.getInstance] in `main()`. Throws if used without
/// the override to make misconfiguration explicit at runtime.
@Riverpod(keepAlive: true)
SharedPreferences sharedPreferences(Ref ref) => throw UnimplementedError(
  'sharedPreferencesProvider must be overridden in main()',
);

/// Provides the singleton [AppDatabase].
///
/// .NET analogue: `AddDbContext<T>()` in `Program.cs` — registered as a
/// scoped/singleton service and disposed when the provider scope ends.
///
/// Tests can override this with an in-memory executor:
/// ```dart
/// ProviderScope(
///   overrides: [
///     databaseProvider.overrideWithValue(inMemoryDb),
///   ],
///   child: const MyApp(),
/// );
/// ```
@Riverpod(keepAlive: true)
AppDatabase database(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}

/// Provides the current [DateTime] (wall-clock).
///
/// .NET analogue: `IClock` / `TimeProvider` abstraction — allows tests to
/// override "now" so time-based logic is deterministic.
///
/// ```dart
/// clockProvider.overrideWithValue(FixedClock(DateTime(2024, 1, 1)));
/// ```
///
/// **Note:** This provider is intentionally simple for Phase 1.  It returns
/// `DateTime.now()` at read time and does not auto-refresh.  If you need
/// a live ticking clock, watch a `StreamProvider.periodic` instead.
@riverpod
DateTime clock(Ref ref) => DateTime.now();

/// Provides [MedicationRepository] backed by Drift.
@Riverpod(keepAlive: true)
MedicationRepository medicationRepository(Ref ref) {
  final db = ref.watch(databaseProvider);
  return DriftMedicationRepository(db);
}

/// Provides [ScheduleRepository] backed by Drift.
@Riverpod(keepAlive: true)
ScheduleRepository scheduleRepository(Ref ref) {
  final db = ref.watch(databaseProvider);
  return DriftScheduleRepository(db);
}

/// Provides [DoseEventRepository] backed by Drift.
@Riverpod(keepAlive: true)
DoseEventRepository doseEventRepository(Ref ref) {
  final repository = ref.watch(driftDoseEventRepositoryProvider);
  return repository;
}

@Riverpod(keepAlive: true)
DriftDoseEventRepository driftDoseEventRepository(Ref ref) {
  final db = ref.watch(databaseProvider);
  return DriftDoseEventRepository(db);
}

/// Provides [TimelineRepository] backed by Drift.
@Riverpod(keepAlive: true)
TimelineRepository timelineRepository(Ref ref) {
  final repository = ref.watch(driftDoseEventRepositoryProvider);
  return repository;
}

/// Provides the pure schedule expansion engine.
@Riverpod(keepAlive: true)
ScheduleExpander scheduleExpander(Ref ref) => const ScheduleExpander();

/// Provides the service that materializes upcoming pending dose events.
@Riverpod(keepAlive: true)
DoseReconciler doseReconciler(Ref ref) {
  return DoseReconciler(
    scheduleRepository: ref.watch(scheduleRepositoryProvider),
    doseEventRepository: ref.watch(doseEventRepositoryProvider),
    expander: ref.watch(scheduleExpanderProvider),
    clock: () => ref.read(clockProvider),
    onReconciled: () => ref.read(syncNotificationsUseCaseProvider).call(),
  );
}

/// Runs one reconciliation pass when first read at app startup.
@Riverpod(keepAlive: true)
Future<void> reconciliationBootstrap(Ref ref) async {
  final reconciler = ref.watch(doseReconcilerProvider);
  final result = await reconciler.reconcileUpcoming();
  if (result case FailureResult(:final failure)) {
    developer.log(
      'Startup reconciliation failed: $failure',
      name: 'my_pills.reconciliation_bootstrap',
    );
  }
}

final watchTodayDosesUseCaseProvider = Provider<WatchTodayDoses>((ref) {
  return WatchTodayDoses(
    ref.watch(doseEventRepositoryProvider),
    clock: () => ref.read(clockProvider),
  );
});

final markDoseTakenUseCaseProvider = Provider<MarkDoseTaken>((ref) {
  return MarkDoseTaken(
    ref.watch(doseEventRepositoryProvider),
    clock: () => ref.read(clockProvider),
  );
});

final markDoseMissedUseCaseProvider = Provider<MarkDoseMissed>((ref) {
  return MarkDoseMissed(ref.watch(doseEventRepositoryProvider));
});

final deleteDoseEventUseCaseProvider = Provider<DeleteDoseEvent>((ref) {
  return DeleteDoseEvent(ref.watch(doseEventRepositoryProvider));
});

final watchMedicationsUseCaseProvider = Provider<WatchMedications>((ref) {
  return WatchMedications(ref.watch(medicationRepositoryProvider));
});

final addMedicationUseCaseProvider = Provider<AddMedication>((ref) {
  return AddMedication(ref.watch(medicationRepositoryProvider));
});

final updateMedicationUseCaseProvider = Provider<UpdateMedication>((ref) {
  return UpdateMedication(ref.watch(medicationRepositoryProvider));
});

final deleteMedicationUseCaseProvider = Provider<DeleteMedication>((ref) {
  return DeleteMedication(
    ref.watch(medicationRepositoryProvider),
    onDeleted: () => ref.read(syncNotificationsUseCaseProvider).call(),
  );
});

final createScheduleUseCaseProvider = Provider<CreateSchedule>((ref) {
  return CreateSchedule(
    ref.watch(scheduleRepositoryProvider),
    reconciler: ref.watch(doseReconcilerProvider),
  );
});

final deleteScheduleUseCaseProvider = Provider<DeleteSchedule>((ref) {
  return DeleteSchedule(
    ref.watch(scheduleRepositoryProvider),
    onDeleted: () => ref.read(syncNotificationsUseCaseProvider).call(),
  );
});

/// Watches all schedules filtered by medication id.
final schedulesForMedicationProvider =
    StreamProvider.family<Result<List<Schedule>>, int>((ref, medicationId) {
      return ref
          .watch(scheduleRepositoryProvider)
          .watchAll()
          .map(
            (result) => switch (result) {
              Success(:final value) => Result.success(
                value.where((s) => s.medicationId == medicationId).toList(),
              ),
              FailureResult(:final failure) => Result<List<Schedule>>.failure(
                failure,
              ),
            },
          );
    });

final getTimelineRangeUseCaseProvider = Provider<GetTimelineRange>((ref) {
  return GetTimelineRange(ref.watch(timelineRepositoryProvider));
});

final watchTimelineRangeUseCaseProvider = Provider<WatchTimelineRange>((ref) {
  return WatchTimelineRange(ref.watch(timelineRepositoryProvider));
});

final syncNotificationsUseCaseProvider = Provider<SyncNotifications>((ref) {
  return SyncNotifications(
    scheduler: ref.watch(notificationSchedulerProvider),
    calendarSyncService: ref.watch(calendarSyncServiceProvider),
    prefsRepo: ref.watch(notificationPreferencesRepositoryProvider),
    doseRepo: ref.watch(doseEventRepositoryProvider),
    medRepo: ref.watch(medicationRepositoryProvider),
    clock: () => ref.read(clockProvider),
  );
});
