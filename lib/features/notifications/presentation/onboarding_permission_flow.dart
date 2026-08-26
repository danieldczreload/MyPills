import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_pills/app/providers.dart';
import 'package:my_pills/core/utils/log.dart';
import 'package:permission_handler/permission_handler.dart';

/// Runs the first-launch permission sequence: notifications, battery
/// optimisation, and registers the device with the Firebase backend.
///
/// Best-effort: any individual step that fails or is denied is logged but
/// doesn't block the rest. The user can re-grant from Settings later.
Future<void> runOnboardingPermissionFlow(WidgetRef ref) async {
  await _requestNotifications();
  await _requestBattery();
  await _initFcm(ref);
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

Future<void> _initFcm(WidgetRef ref) async {
  try {
    final fcmService = ref.read(fcmDeviceServiceProvider);
    await fcmService.initialize();
    developer.log(
      'FCM registered during onboarding',
      name: 'mypills.onboarding',
    );
  } catch (e) {
    mlog('mypills.onboarding', 'FCM init failed: $e');
  }
}
