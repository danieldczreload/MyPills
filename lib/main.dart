import 'dart:async';

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
import 'package:my_pills/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Resolves the local IANA timezone with multiple fallback strategies and
/// applies it to the `timezone` package. If everything fails we leave it as
/// UTC and log loudly — this is a critical bug for `zonedSchedule`, since
/// schedule times computed from local DateTimes get reinterpreted as UTC,
/// which on a non-UTC device places them in the past and the OS drops them
/// without firing.
Future<void> _setUpTimezone() async {
  String? identifier;
  try {
    final info = await FlutterTimezone.getLocalTimezone();
    identifier = info.identifier;
    mlog('mypills.boot', 'FlutterTimezone -> $identifier');
  } catch (e) {
    mlog('mypills.boot', 'FlutterTimezone failed: $e');
  }

  if (identifier != null) {
    try {
      tz.setLocalLocation(tz.getLocation(identifier));
      mlog('mypills.boot', 'tz.local set to $identifier');
      return;
    } catch (e) {
      mlog('mypills.boot', 'tz.getLocation($identifier) failed: $e');
    }
  }

  // Fallback: use the device's offset to locate a matching tz database entry.
  final offset = DateTime.now().timeZoneOffset;
  final tzName = DateTime.now().timeZoneName;
  mlog(
    'mypills.boot',
    'fallback offset=$offset name=$tzName — keeping tz.local=${tz.local.name} (likely UTC)',
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();
  await _setUpTimezone();

  final plugin = await initNotifications();
  final prefs = await SharedPreferences.getInstance();

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
    // Eager-create the in-app reminder service so it starts watching doses
    // immediately, not when the overlay first listens.
    ref.read(inAppReminderServiceProvider);
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
