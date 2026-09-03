import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_pills/app/providers.dart';
import 'package:my_pills/core/utils/log.dart';
import 'package:my_pills/features/notifications/domain/entities/in_app_banner.dart';
import 'package:my_pills/features/notifications/presentation/providers/notification_providers.dart';
import 'package:my_pills/features/profile/presentation/providers/profile_providers.dart';

/// Handles FCM messages received while the app is in the foreground.
class ForegroundPushHandler {
  ForegroundPushHandler(this._ref);

  final WidgetRef _ref;

  Future<void> handle(RemoteMessage message) async {
    mlog('mypills.fcm', 'Foreground push received: ${message.data}');
    final data = message.data;
    final action = data['action'] ?? data['type'];

    if (_isCancel(action, data)) {
      await _cancelDose(data);
    } else if (action == 'cancel_recurring' ||
        action == 'recurring_cancelled' ||
        data.containsKey('cancelRecurring')) {
      await _ref.read(notificationSchedulerProvider).cancelAll();
      unawaited(_ref.read(syncNotificationsUseCaseProvider).call());
    } else if (action == 'dose_reminder') {
      await _onDoseReminder(data);
    }

    final profile = _ref.read(currentUserProfileProvider);
    if (profile != null && profile.id != 'default') {
      unawaited(_ref.read(syncEngineProvider).syncProfile(profile.id));
    }
    _ref.read(inAppReminderServiceProvider).reevaluate();
  }

  bool _isCancel(Object? action, Map<String, dynamic> data) {
    return action == 'cancel' ||
        action == 'cancel_notification' ||
        action == 'dose_cancelled' ||
        data.containsKey('cancelDoseEventId');
  }

  Future<void> _cancelDose(Map<String, dynamic> data) async {
    final doseIdStr =
        data['doseEventId'] ?? data['cancelDoseEventId'] ?? data['id'];
    if (doseIdStr == null) return;
    final localId = await _localDoseEventId(doseIdStr.toString());
    if (localId != null) {
      await _ref
          .read(notificationSchedulerProvider)
          .cancelForDoseEvent(localId);
    }
    unawaited(_ref.read(syncNotificationsUseCaseProvider).call());
  }

  Future<void> _onDoseReminder(Map<String, dynamic> data) async {
    final prefs = _ref.read(notificationPreferencesProvider);
    if (prefs.inAppBannersEnabled) {
      final name = (data['medicationName'] ?? '').toString();
      final display = (data['doseDisplay'] ?? data['dosage'] ?? '').toString();
      _ref
          .read(inAppReminderServiceProvider)
          .showBanner(
            InAppBanner(
              medicationName: name.isEmpty ? 'Medicamento' : name,
              doseDisplay: display.isEmpty ? null : display,
            ),
          );
    }
    final doseEventId = data['doseEventId']?.toString();
    if (doseEventId == null || doseEventId.isEmpty) return;
    final localId = await _localDoseEventId(doseEventId);
    if (localId != null) {
      _ref.read(inAppReminderServiceProvider).markNotified(localId);
    }
  }

  Future<int?> _localDoseEventId(String raw) async {
    final parsed = int.tryParse(raw);
    if (parsed != null) return parsed;
    final db = _ref.read(databaseProvider);
    final localRow = await (db.select(
      db.doseEventsTable,
    )..where((t) => t.serverId.equals(raw))).getSingleOrNull();
    return localRow?.id;
  }
}
