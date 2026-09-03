import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_pills/app/providers.dart';
import 'package:my_pills/app/router.dart';
import 'package:my_pills/core/config/env_config.dart';
import 'package:my_pills/core/theme/app_theme.dart';
import 'package:my_pills/core/utils/device_timezone.dart';
import 'package:my_pills/core/utils/log.dart';
import 'package:my_pills/features/notifications/data/services/notification_init.dart';
import 'package:my_pills/features/notifications/presentation/foreground_push_handler.dart';
import 'package:my_pills/features/notifications/presentation/in_app_reminder_overlay.dart';
import 'package:my_pills/features/notifications/presentation/providers/notification_providers.dart';
import 'package:my_pills/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  mlog('mypills.fcm', 'Handling background message: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  mlog('mypills.boot', 'API_BASE_URL=${EnvConfig.apiBaseUrl}');

  // Non-fatal crash isolation: initialize Firebase Core & Messaging safely
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e, st) {
    mlog('mypills.boot', 'Firebase init failed (non-fatal): $e\n$st');
  }

  await DeviceTimezone.initializeLocal();

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
          onForegroundMessage: ForegroundPushHandler(ref).handle,
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
    builder: (context, child) => InAppReminderOverlay(child: child!),
  );
}
