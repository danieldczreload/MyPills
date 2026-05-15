import 'dart:io' show Platform;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:my_pills/core/utils/log.dart';

const String kMedicationChannelId = 'medication_reminders';
const String kMedicationChannelName = 'Recordatorios de medicación';
const String kMedicationChannelDescription =
    'Avisos para la toma de medicamentos';

/// Whether the device can fire exact alarms. Cached after [initNotifications].
bool exactAlarmsAllowed = false;

const AndroidNotificationChannel _medicationChannel = AndroidNotificationChannel(
  kMedicationChannelId,
  kMedicationChannelName,
  description: kMedicationChannelDescription,
  importance: Importance.max,
);

Future<FlutterLocalNotificationsPlugin> initNotifications() async {
  mlog('mypills.notif', 'initNotifications start');
  final plugin = FlutterLocalNotificationsPlugin();

  const initSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    linux: LinuxInitializationSettings(defaultActionName: 'Open notification'),
  );
  await plugin.initialize(initSettings);
  mlog('mypills.notif', 'plugin.initialize done');

  if (Platform.isAndroid) {
    final android = plugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin
    >();
    if (android == null) {
      mlog('mypills.notif', 'android plugin impl is null');
      return plugin;
    }

    try {
      await android.createNotificationChannel(_medicationChannel);
      mlog('mypills.notif', 'channel created: $kMedicationChannelId');
    } catch (e, st) {
      mlogError(
        'mypills.notif',
        'createNotificationChannel failed',
        error: e,
        stackTrace: st,
      );
    }

    try {
      final granted = await android.requestNotificationsPermission();
      mlog('mypills.notif', 'requestNotificationsPermission -> $granted');
    } catch (e) {
      mlog('mypills.notif', 'requestNotificationsPermission failed: $e');
    }

    try {
      final exact = await android.requestExactAlarmsPermission();
      mlog('mypills.notif', 'requestExactAlarmsPermission -> $exact');
    } catch (e) {
      mlog('mypills.notif', 'requestExactAlarmsPermission failed: $e');
    }

    try {
      exactAlarmsAllowed =
          await android.canScheduleExactNotifications() ?? false;
      mlog(
        'mypills.notif',
        'canScheduleExactNotifications -> $exactAlarmsAllowed',
      );
    } catch (e) {
      mlog('mypills.notif', 'canScheduleExactNotifications failed: $e');
      exactAlarmsAllowed = false;
    }
  }

  mlog('mypills.notif', 'initNotifications done');
  return plugin;
}
