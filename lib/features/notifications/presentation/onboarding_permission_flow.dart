import 'dart:developer' as developer;
import 'package:my_pills/core/utils/log.dart';

import 'package:device_calendar/device_calendar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_pills/app/providers.dart';
import 'package:my_pills/features/notifications/presentation/providers/notification_providers.dart';
import 'package:permission_handler/permission_handler.dart';

/// Runs the first-launch permission sequence: notifications, battery
/// optimisation, and calendar (with auto-pick of the first writable
/// calendar). Persists the calendar id into notification preferences and
/// triggers the initial sync.
///
/// Best-effort: any individual step that fails or is denied is logged but
/// doesn't block the rest. The user can re-grant from Settings later.
Future<void> runOnboardingPermissionFlow(WidgetRef ref) async {
  await _requestNotifications();
  await _requestBattery();
  await _requestCalendarAndAutoPick(ref);
  // Sync now uses the freshly granted permissions and picked calendar.
  await ref.read(syncNotificationsUseCaseProvider).call();
}

Future<void> _requestNotifications() async {
  try {
    final s = await Permission.notification.request();
    mlog('mypills.onboarding', 'notifications -> $s');
  } catch (e) {
    mlog('mypills.onboarding', 'notifications request failed: $e');
  }
}

Future<void> _requestBattery() async {
  try {
    final s = await Permission.ignoreBatteryOptimizations.request();
    mlog('mypills.onboarding', 'ignoreBattery -> $s');
  } catch (e) {
    mlog('mypills.onboarding', 'battery request failed: $e');
  }
}

Future<void> _requestCalendarAndAutoPick(WidgetRef ref) async {
  try {
    final plugin = DeviceCalendarPlugin();
    var perm = await plugin.hasPermissions();
    if (!(perm.isSuccess && (perm.data ?? false))) {
      perm = await plugin.requestPermissions();
    }
    if (!(perm.isSuccess && (perm.data ?? false))) {
      mlog('mypills.onboarding', 'calendar permission denied');
      return;
    }

    final cals = await plugin.retrieveCalendars();
    if (!cals.isSuccess || cals.data == null || cals.data!.isEmpty) {
      mlog('mypills.onboarding', 'no calendars available');
      return;
    }

    // Prefer writable, then default, then first.
    final sorted = [...cals.data!]
      ..sort((a, b) {
        final aRo = a.isReadOnly ?? true;
        final bRo = b.isReadOnly ?? true;
        if (aRo != bRo) return aRo ? 1 : -1;
        final aDef = a.isDefault ?? false;
        final bDef = b.isDefault ?? false;
        if (aDef != bDef) return aDef ? -1 : 1;
        return 0;
      });
    final picked = sorted.first;
    if (picked.id == null) return;

    await ref
        .read(notificationPreferencesProvider.notifier)
        .updatePreferences(
          (p) => p.copyWith(defaultCalendarId: picked.id),
        );
    developer.log(
      'auto-picked calendar ${picked.name} (${picked.id})',
      name: 'mypills.onboarding',
    );
  } catch (e) {
    mlog('mypills.onboarding', 'calendar setup failed: $e');
  }
}
