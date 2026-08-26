import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:my_pills/app/providers.dart';
import 'package:my_pills/app/router.dart';
import 'package:my_pills/core/theme/app_theme.dart';
import 'package:my_pills/core/utils/log.dart';
import 'package:my_pills/features/notifications/data/services/device_info.dart';
import 'package:my_pills/features/notifications/data/services/notification_init.dart';
import 'package:my_pills/features/notifications/presentation/in_app_reminder_overlay.dart';
import 'package:my_pills/features/notifications/presentation/oem_setup_dialog.dart';
import 'package:my_pills/features/notifications/presentation/providers/notification_providers.dart';
import 'package:my_pills/features/profile/presentation/providers/profile_providers.dart';
import 'package:my_pills/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  mlog('mypills.fcm', 'Handling background message: ${message.messageId}');
}

/// Resolves the local IANA timezone with multiple fallback strategies and
/// applies it to the `timezone` package.
Future<void> _setUpTimezone() async {
  String? identifier;
  try {
    final info = await FlutterTimezone.getLocalTimezone();
    identifier = info.identifier;
    mlog('mypills.boot', 'FlutterTimezone -> $identifier');
  } catch (e) {
    mlog('mypills.boot', 'FlutterTimezone failed: $e');
  }

  tz.initializeTimeZones();
  if (identifier != null && identifier.isNotEmpty) {
    try {
      tz.setLocalLocation(tz.getLocation(identifier));
      mlog('mypills.boot', 'tz.local successfully set to $identifier');
      return;
    } catch (e) {
      mlog('mypills.boot', 'tz.getLocation("$identifier") failed: $e');
    }
  }

  // Fallback 1: match by GMT offset
  final offsetHours = DateTime.now().timeZoneOffset.inHours;
  final sign = offsetHours >= 0 ? '+' : '-';
  final offsetName = 'Etc/GMT$sign${offsetHours.abs()}';
  try {
    tz.setLocalLocation(tz.getLocation(offsetName));
    mlog('mypills.boot', 'tz.local set to fallback offset: $offsetName');
    return;
  } catch (_) {}

  // Fallback 2: America/Mexico_City for Mexico Central Standard Time (GMT-6)
  if (offsetHours == -6) {
    try {
      tz.setLocalLocation(tz.getLocation('America/Mexico_City'));
      mlog('mypills.boot', 'tz.local set to fallback America/Mexico_City');
      return;
    } catch (_) {}
  }

  // Last resort: UTC
  mlog('mypills.boot', 'WARNING: tz.local defaulted to UTC');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Non-fatal crash isolation: initialize Firebase Core & Messaging safely
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e, st) {
    mlog('mypills.boot', 'Firebase init failed (non-fatal): $e\n$st');
  }

  await _setUpTimezone();

  final prefs = await SharedPreferences.getInstance();
  final plugin = await initNotifications();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        flutterLocalNotificationsPluginProvider.overrideWithValue(plugin),
      ],
      child: const MyPillsBootstrap(),
    ),
  );
}

class MyPillsBootstrap extends ConsumerStatefulWidget {
  const MyPillsBootstrap({super.key});

  @override
  ConsumerState<MyPillsBootstrap> createState() => _MyPillsBootstrapState();
}

class _MyPillsBootstrapState extends ConsumerState<MyPillsBootstrap>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(ref.read(reconciliationBootstrapProvider.future));
    ref.read(inAppReminderServiceProvider);

    // Eager initialize FCM push receiver
    try {
      final fcmService = ref.read(fcmDeviceServiceProvider);
      unawaited(
        fcmService.initialize(
          onForegroundMessage: (message) async {
            mlog('mypills.fcm', 'Foreground push received: ${message.data}');
            final data = message.data;
            final action = data['action'] ?? data['type'];
            if (action == 'cancel' ||
                action == 'cancel_notification' ||
                action == 'dose_cancelled' ||
                data.containsKey('cancelDoseEventId')) {
              final doseIdStr =
                  data['doseEventId'] ??
                  data['cancelDoseEventId'] ??
                  data['id'];
              if (doseIdStr != null) {
                final str = doseIdStr.toString();
                final parsedId = int.tryParse(str);
                if (parsedId != null) {
                  await ref
                      .read(notificationSchedulerProvider)
                      .cancelForDoseEvent(parsedId);
                } else {
                  final db = ref.read(databaseProvider);
                  final localRow = await (db.select(
                    db.doseEventsTable,
                  )..where((t) => t.serverId.equals(str))).getSingleOrNull();
                  if (localRow != null) {
                    await ref
                        .read(notificationSchedulerProvider)
                        .cancelForDoseEvent(localRow.id);
                  }
                }
              }
              unawaited(ref.read(syncNotificationsUseCaseProvider).call());
            } else if (action == 'cancel_recurring' ||
                action == 'recurring_cancelled' ||
                data.containsKey('cancelRecurring')) {
              await ref.read(notificationSchedulerProvider).cancelAll();
              unawaited(ref.read(syncNotificationsUseCaseProvider).call());
            }

            final profile = ref.read(currentUserProfileProvider);
            if (profile != null && profile.id != 'default') {
              unawaited(ref.read(syncEngineProvider).syncProfile(profile.id));
            }
            ref.read(inAppReminderServiceProvider).reevaluate();
          },
        ),
      );
    } catch (e) {
      mlog('mypills.boot', 'FCM service init error: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      mlog('mypills.boot', 'app resumed — refreshing notifications');
      unawaited(ref.read(syncNotificationsUseCaseProvider).call());
      ref.read(inAppReminderServiceProvider).reevaluate();
    }
  }

  @override
  Widget build(BuildContext context) => const MyPillsApp();
}

class MyPillsApp extends StatelessWidget {
  const MyPillsApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    theme: AppTheme.light(),
    debugShowCheckedModeBanner: false,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('es'),
    routerConfig: router,
    scrollBehavior: AppTheme.scrollBehavior,
    builder: (context, child) => _OemSetupGate(
      child: InAppReminderOverlay(child: child!),
    ),
  );
}

class _OemSetupGate extends ConsumerStatefulWidget {
  const _OemSetupGate({required this.child});

  final Widget child;

  @override
  ConsumerState<_OemSetupGate> createState() => _OemSetupGateState();
}

class _OemSetupGateState extends ConsumerState<_OemSetupGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybePrompt());
  }

  Future<void> _maybePrompt() async {
    final family = await DeviceManufacturerInfo().detectOem();
    if (!family.needsManualSetup || !mounted) return;
    final prefs = ref.read(sharedPreferencesProvider);
    await maybeShowOemSetup(
      context: context,
      prefs: prefs,
      family: family,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
