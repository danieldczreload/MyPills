import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_pills/app/providers.dart';
import 'package:my_pills/features/notifications/data/repositories/shared_prefs_notification_preferences_repository.dart';
import 'package:my_pills/features/notifications/data/services/flutter_local_notification_scheduler.dart';
import 'package:my_pills/features/notifications/data/services/remote_notification_preferences_service.dart';
import 'package:my_pills/features/notifications/domain/entities/notification_preferences.dart';
import 'package:my_pills/features/notifications/domain/repositories/notification_preferences_repository.dart';
import 'package:my_pills/features/medications/presentation/providers/medications_providers.dart';
import 'package:my_pills/features/notifications/domain/entities/in_app_banner.dart';
import 'package:my_pills/features/notifications/domain/services/in_app_reminder_service.dart';
import 'package:my_pills/features/notifications/domain/services/notification_scheduler.dart';
import 'package:my_pills/features/tracker/domain/entities/dose_event.dart';

final remoteNotificationPreferencesServiceProvider =
    Provider<RemoteNotificationPreferencesService>((ref) {
      return RemoteNotificationPreferencesService(ref.watch(apiClientProvider));
    });

final notificationPreferencesRepositoryProvider =
    Provider<NotificationPreferencesRepository>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return SharedPrefsNotificationPreferencesRepository(prefs);
    });

class NotificationPreferencesNotifier
    extends Notifier<NotificationPreferences> {
  late final NotificationPreferencesRepository _repository;

  @override
  NotificationPreferences build() {
    _repository = ref.watch(notificationPreferencesRepositoryProvider);
    return _repository.load();
  }

  Future<void> updatePreferences(
    NotificationPreferences Function(NotificationPreferences) updater,
  ) async {
    final newState = updater(state);
    if (newState == state) return;
    state = newState;
    await _repository.save(newState);
    await ref.read(syncNotificationsUseCaseProvider).call();

    unawaited(
      ref
          .read(remoteNotificationPreferencesServiceProvider)
          .updatePreferences(newState),
    );
  }
}

final notificationPreferencesProvider =
    NotifierProvider<NotificationPreferencesNotifier, NotificationPreferences>(
      NotificationPreferencesNotifier.new,
    );

final flutterLocalNotificationsPluginProvider =
    Provider<FlutterLocalNotificationsPlugin>((ref) {
      final plugin = FlutterLocalNotificationsPlugin();
      // Initialization happens in main.dart
      return plugin;
    });

final notificationSchedulerProvider = Provider<NotificationScheduler>((ref) {
  final plugin = ref.watch(flutterLocalNotificationsPluginProvider);
  return FlutterLocalNotificationScheduler(plugin);
});

final inAppReminderServiceProvider = Provider<InAppReminderService>((ref) {
  final todayDosesStream = ref
      .watch(watchTodayDosesUseCaseProvider)
      .call()
      .map((result) => result.valueOrNull ?? <DoseEvent>[]);
  final prefs = ref.watch(sharedPreferencesProvider);
  final service = InAppReminderService(
    todayDosesStream: todayDosesStream,
    clock: DateTime.now,
    prefs: prefs,
    minutesBefore: () =>
        ref.read(notificationPreferencesProvider).reminderMinutesBefore,
    medicationNameOf: (id) {
      final meds = ref.read(medicationsStreamProvider).value?.valueOrNull;
      return meds?.where((m) => m.id == id).firstOrNull?.name ?? 'Medicamento';
    },
  );

  ref.onDispose(service.dispose);
  ref.keepAlive();
  return service;
});

final inAppBannersStreamProvider = StreamProvider<InAppBanner>((ref) {
  final service = ref.watch(inAppReminderServiceProvider);
  return service.banners;
});
