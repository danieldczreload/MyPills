import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_pills/core/db/app_database.dart';
import 'package:my_pills/core/network/api_client.dart';
import 'package:my_pills/core/network/media_upload_service.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/core/storage/token_storage.dart';
import 'package:my_pills/core/sync/sync_engine.dart';
import 'package:my_pills/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:my_pills/features/auth/domain/repositories/auth_repository.dart';
import 'package:my_pills/features/calendar_integration/data/services/pkce_calendar_service.dart';
import 'package:my_pills/features/medications/data/repositories/drift_medication_repository.dart';
import 'package:my_pills/features/medications/data/repositories/synced_medications_repository.dart';
import 'package:my_pills/features/medications/domain/repositories/medication_repository.dart';
import 'package:my_pills/features/medications/domain/use_cases/add_medication.dart';
import 'package:my_pills/features/medications/domain/use_cases/delete_medication.dart';
import 'package:my_pills/features/medications/domain/use_cases/update_medication.dart';
import 'package:my_pills/features/medications/domain/use_cases/watch_medications.dart';
import 'package:my_pills/features/notifications/data/services/fcm_device_service.dart';
import 'package:my_pills/features/notifications/domain/use_cases/sync_notifications.dart';
import 'package:my_pills/features/notifications/presentation/providers/notification_providers.dart';
import 'package:my_pills/features/profile/presentation/providers/profile_providers.dart';
import 'package:my_pills/features/schedules/data/repositories/cached_dose_unit_repository.dart';
import 'package:my_pills/features/schedules/data/repositories/drift_schedule_repository.dart';
import 'package:my_pills/features/schedules/data/repositories/synced_schedules_repository.dart';
import 'package:my_pills/features/schedules/domain/entities/dose_unit.dart';
import 'package:my_pills/features/schedules/domain/entities/schedule.dart';
import 'package:my_pills/features/schedules/domain/repositories/dose_unit_repository.dart';
import 'package:my_pills/features/schedules/domain/repositories/schedule_repository.dart';
import 'package:my_pills/features/schedules/domain/services/dose_reconciler.dart';
import 'package:my_pills/features/schedules/domain/services/schedule_expander.dart';
import 'package:my_pills/features/schedules/domain/use_cases/cancel_recurring_notifications.dart';
import 'package:my_pills/features/schedules/domain/use_cases/create_schedule.dart';
import 'package:my_pills/features/schedules/domain/use_cases/delete_schedule.dart';
import 'package:my_pills/features/timeline/domain/repositories/timeline_repository.dart';
import 'package:my_pills/features/timeline/domain/use_cases/get_timeline_range.dart';
import 'package:my_pills/features/timeline/domain/use_cases/watch_timeline_range.dart';
import 'package:my_pills/features/tracker/data/repositories/drift_dose_event_repository.dart';
import 'package:my_pills/features/tracker/data/repositories/synced_dose_events_repository.dart';
import 'package:my_pills/features/tracker/domain/repositories/dose_event_repository.dart';
import 'package:my_pills/features/tracker/domain/use_cases/delete_dose_event.dart';
import 'package:my_pills/features/tracker/domain/use_cases/mark_dose_missed.dart';
import 'package:my_pills/features/tracker/domain/use_cases/mark_dose_taken.dart';
import 'package:my_pills/features/tracker/domain/use_cases/watch_today_doses.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
SharedPreferences sharedPreferences(Ref ref) => throw UnimplementedError(
  'sharedPreferencesProvider must be overridden in main()',
);

@Riverpod(keepAlive: true)
AppDatabase database(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}

@riverpod
DateTime clock(Ref ref) => DateTime.now();

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(tokenStorage: ref.watch(tokenStorageProvider));
});

final mediaUploadServiceProvider = Provider<MediaUploadService>((ref) {
  return MediaUploadService(ref.watch(apiClientProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    apiClient: ref.watch(apiClientProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

final syncEngineProvider = Provider<SyncEngine>((ref) {
  return SyncEngine(
    apiClient: ref.watch(apiClientProvider),
    db: ref.watch(databaseProvider),
    prefs: ref.watch(sharedPreferencesProvider),
  );
});

final fcmDeviceServiceProvider = Provider<FcmDeviceService>((ref) {
  return FcmDeviceService(
    ref.watch(apiClientProvider),
    ref.watch(sharedPreferencesProvider),
  );
});

final doseUnitRepositoryProvider = Provider<DoseUnitRepository>((ref) {
  return CachedDoseUnitRepository(
    apiClient: ref.watch(apiClientProvider),
    prefs: ref.watch(sharedPreferencesProvider),
  );
});

final doseUnitsProvider = FutureProvider<List<DoseUnit>>((ref) async {
  final result = await ref.watch(doseUnitRepositoryProvider).getAll();
  return result.valueOrNull ?? [];
});

final pkceCalendarServiceProvider = Provider<PkceCalendarService>((ref) {
  return PkceCalendarService(
    ref.watch(apiClientProvider),
    ref.watch(sharedPreferencesProvider),
  );
});

final calendarConnectionsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      profileId,
    ) async {
      final service = ref.watch(pkceCalendarServiceProvider);
      final result = await service.getConnections(profileId: profileId);
      return result.valueOrNull ?? [];
    });

/// Provides [MedicationRepository] backed by Drift + Offline-First Sync.
@Riverpod(keepAlive: true)
MedicationRepository medicationRepository(Ref ref) {
  final db = ref.watch(databaseProvider);
  final profile = ref.watch(currentUserProfileProvider);
  final profileId = profile?.id ?? 'default';
  final localRepo = DriftMedicationRepository(db, profileId: profileId);
  final syncEngine = ref.watch(syncEngineProvider);
  return SyncedMedicationRepository(
    localRepo: localRepo,
    db: db,
    syncEngine: syncEngine,
    profileId: profileId,
  );
}

/// Profile-scoped [ScheduleRepository]. [scheduleRepositoryProvider] is the
/// current-profile view of this family.
final scheduleRepositoryForProfileProvider =
    Provider.family<ScheduleRepository, String>((ref, profileId) {
      final db = ref.watch(databaseProvider);
      return SyncedScheduleRepository(
        localRepo: DriftScheduleRepository(db, profileId: profileId),
        db: db,
        syncEngine: ref.watch(syncEngineProvider),
        profileId: profileId,
      );
    });

/// Provides [ScheduleRepository] backed by Drift + Offline-First Sync.
@Riverpod(keepAlive: true)
ScheduleRepository scheduleRepository(Ref ref) {
  final profileId = ref.watch(currentUserProfileProvider)?.id ?? 'default';
  return ref.watch(scheduleRepositoryForProfileProvider(profileId));
}

/// Provides [DoseEventRepository] backed by Drift + Offline-First Sync.
@Riverpod(keepAlive: true)
DoseEventRepository doseEventRepository(Ref ref) {
  final db = ref.watch(databaseProvider);
  final profile = ref.watch(currentUserProfileProvider);
  final profileId = profile?.id ?? 'default';
  final localRepo = ref.watch(driftDoseEventRepositoryProvider);
  final syncEngine = ref.watch(syncEngineProvider);
  return SyncedDoseEventRepository(
    localRepo: localRepo,
    db: db,
    syncEngine: syncEngine,
    profileId: profileId,
  );
}

@Riverpod(keepAlive: true)
DriftDoseEventRepository driftDoseEventRepository(Ref ref) {
  final db = ref.watch(databaseProvider);
  final profile = ref.watch(currentUserProfileProvider);
  final profileId = profile?.id ?? 'default';
  return DriftDoseEventRepository(db, profileId: profileId);
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
  return DeleteDoseEvent(
    ref.watch(doseEventRepositoryProvider),
    onDeleted: (id) async {
      await ref.read(notificationSchedulerProvider).cancelForDoseEvent(id);
      ref.read(inAppReminderServiceProvider).reevaluate();
    },
  );
});

final cancelRecurringNotificationsUseCaseProvider =
    Provider<CancelRecurringNotifications>((ref) {
      return CancelRecurringNotifications(
        ref.watch(scheduleRepositoryProvider),
        onCancelled: () async {
          try {
            await ref.read(syncNotificationsUseCaseProvider).call();
            ref.read(inAppReminderServiceProvider).reevaluate();
          } catch (_) {}
        },
      );
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

final createScheduleUseCaseProvider = Provider.family<CreateSchedule, String>((
  ref,
  profileId,
) {
  final db = ref.watch(databaseProvider);
  return CreateSchedule(
    ref.watch(scheduleRepositoryForProfileProvider(profileId)),
    reconciler: DoseReconciler(
      scheduleRepository: ref.watch(
        scheduleRepositoryForProfileProvider(profileId),
      ),
      doseEventRepository: DriftDoseEventRepository(
        db,
        profileId: profileId,
      ),
      expander: ref.watch(scheduleExpanderProvider),
      clock: () => ref.read(clockProvider),
      onReconciled: () => ref.read(syncNotificationsUseCaseProvider).call(),
    ),
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
    prefsRepo: ref.watch(notificationPreferencesRepositoryProvider),
    doseRepo: ref.watch(doseEventRepositoryProvider),
    medRepo: ref.watch(medicationRepositoryProvider),
    clock: () => ref.read(clockProvider),
    scheduleRepo: ref.watch(scheduleRepositoryProvider),
  );
});
