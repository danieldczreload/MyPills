import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_pills/app/providers.dart';
import 'package:my_pills/app/router.dart';
import 'package:my_pills/core/theme/serene_theme.dart';
import 'package:my_pills/core/widgets/sanctuary_app_bar.dart';
import 'package:my_pills/features/notifications/data/services/flutter_local_notification_scheduler.dart';
import 'package:my_pills/features/notifications/data/services/notification_init.dart';
import 'package:my_pills/features/notifications/presentation/providers/notification_providers.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:my_pills/features/profile/presentation/providers/profile_providers.dart';
import 'package:my_pills/l10n/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _hasNotificationPermission = false;
  final DeviceCalendarPlugin _calendarPlugin = DeviceCalendarPlugin();

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final status = await Permission.notification.status;
    setState(() {
      _hasNotificationPermission = status.isGranted;
    });
  }

  Future<void> _requestPermissions() async {
    final status = await Permission.notification.request();
    setState(() {
      _hasNotificationPermission = status.isGranted;
    });
    if (status.isGranted) {
      // Best-effort: ask to ignore battery optimizations so AlarmManager can
      // wake us. On EMUI/MIUI the OS may still kill us; the Huawei dialog
      // covers the rest of the setup.
      final battery = await Permission.ignoreBatteryOptimizations.status;
      if (!battery.isGranted) {
        await Permission.ignoreBatteryOptimizations.request();
      }
      await ref
          .read(notificationPreferencesProvider.notifier)
          .updatePreferences(
            (p) => p.copyWith(pushNotificationsEnabled: true),
          );
    }
  }

  Future<void> _toggleCalendarSync(bool enable, AppLocalizations l10n) async {
    final prefsNotifier = ref.read(notificationPreferencesProvider.notifier);

    if (!enable) {
      final currentPrefs = ref.read(notificationPreferencesProvider);
      if (currentPrefs.defaultCalendarId != null) {
        await ref
            .read(calendarSyncServiceProvider)
            .removeAllCalendarEvents(currentPrefs.defaultCalendarId!);
      }
      prefsNotifier.updatePreferences(
        (p) => p.copyWith(calendarSyncEnabled: false, defaultCalendarId: null),
      );
      return;
    }

    var permissionsGranted = await _calendarPlugin.hasPermissions();
    if (permissionsGranted.isSuccess && !(permissionsGranted.data ?? false)) {
      permissionsGranted = await _calendarPlugin.requestPermissions();
      if (!permissionsGranted.isSuccess ||
          !(permissionsGranted.data ?? false)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.settingsCalendarPermissionDenied)),
          );
        }
        return;
      }
    }

    final calendarsResult = await _calendarPlugin.retrieveCalendars();
    if (calendarsResult.isSuccess &&
        calendarsResult.data != null &&
        calendarsResult.data!.isNotEmpty) {
      // Sort: writable calendars first, read-only at the bottom.
      // Google Calendar often reports isReadOnly=true even when writable —
      // we show all and attempt writes, letting the service handle failures.
      final calendars = [...calendarsResult.data!]
        ..sort((a, b) {
          final aRo = a.isReadOnly ?? true;
          final bRo = b.isReadOnly ?? true;
          if (aRo == bRo) return 0;
          return aRo ? 1 : -1;
        });

      if (!mounted) return;
      final selectedCalendar = await showDialog<Calendar>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(l10n.settingsCalendarSelectTitle),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: calendars.length,
                itemBuilder: (context, index) {
                  final calendar = calendars[index];
                  final isReadOnly = calendar.isReadOnly ?? false;
                  return ListTile(
                    title: Text(calendar.name ?? 'Calendar'),
                    subtitle: Text(calendar.accountName ?? ''),
                    trailing: isReadOnly
                        ? const Tooltip(
                            message: 'Solo lectura',
                            child: Icon(Icons.lock_outline, size: 16),
                          )
                        : null,
                    onTap: () => Navigator.pop(context, calendar),
                  );
                },
              ),
            ),
          );
        },
      );

      if (selectedCalendar != null) {
        prefsNotifier.updatePreferences(
          (p) => p.copyWith(
            calendarSyncEnabled: true,
            defaultCalendarId: selectedCalendar.id,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final sereneTheme = theme.extension<SereneTheme>()!;
    final colorScheme = theme.colorScheme;
    final prefs = ref.watch(notificationPreferencesProvider);

    return Scaffold(
      appBar: SanctuaryAppBar(
        title: l10n.settingsTitle,
        onBack: () => context.pop(),
      ),
      body: ListView(
        padding: EdgeInsets.all(sereneTheme.spacing.md),
        children: [
          // Profile Section
          Text(
            l10n.settingsProfileSection,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: sereneTheme.spacing.sm),
          _ProfileCard(),
          SizedBox(height: sereneTheme.spacing.lg),

          // In-App Reminders Section
          Text(
            l10n.settingsInAppRemindersSection,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: sereneTheme.spacing.sm),
          _SettingsSectionCard(
            children: [
              SwitchListTile(
                title: Text(l10n.settingsInAppRemindersToggle),
                subtitle: Text(l10n.settingsInAppRemindersDesc),
                value: prefs.inAppBannersEnabled,
                onChanged: (val) {
                  ref
                      .read(notificationPreferencesProvider.notifier)
                      .updatePreferences(
                        (p) => p.copyWith(inAppBannersEnabled: val),
                      );
                },
              ),
            ],
          ),
          SizedBox(height: sereneTheme.spacing.lg),

          // Push Notifications Section
          Text(
            l10n.settingsPushNotificationsSection,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: sereneTheme.spacing.sm),
          _SettingsSectionCard(
            children: [
              SwitchListTile(
                title: Text(l10n.settingsPushNotificationsToggle),
                subtitle: Text(l10n.settingsPushNotificationsDesc),
                value:
                    prefs.pushNotificationsEnabled &&
                    _hasNotificationPermission,
                onChanged: (val) {
                  if (val && !_hasNotificationPermission) {
                    _requestPermissions();
                  } else {
                    ref
                        .read(notificationPreferencesProvider.notifier)
                        .updatePreferences(
                          (p) => p.copyWith(pushNotificationsEnabled: val),
                        );
                  }
                },
              ),
              if (!_hasNotificationPermission)
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: sereneTheme.spacing.md,
                  ),
                  child: ElevatedButton(
                    onPressed: _requestPermissions,
                    child: Text(l10n.settingsPermissionButton),
                  ),
                ),
              if (prefs.pushNotificationsEnabled &&
                  _hasNotificationPermission) ...[
                const Divider(height: 1),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: sereneTheme.spacing.md,
                    vertical: sereneTheme.spacing.sm,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.settingsAnticipationLabel,
                        style: theme.textTheme.bodyLarge,
                      ),
                      DropdownButton<int>(
                        value: prefs.reminderMinutesBefore,
                        items: [
                          DropdownMenuItem(
                            value: 0,
                            child: Text(l10n.settingsAnticipationExact),
                          ),
                          DropdownMenuItem(
                            value: 5,
                            child: Text(l10n.settingsAnticipationMinutes(5)),
                          ),
                          DropdownMenuItem(
                            value: 10,
                            child: Text(l10n.settingsAnticipationMinutes(10)),
                          ),
                          DropdownMenuItem(
                            value: 15,
                            child: Text(l10n.settingsAnticipationMinutes(15)),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            ref
                                .read(notificationPreferencesProvider.notifier)
                                .updatePreferences(
                                  (p) => p.copyWith(reminderMinutesBefore: val),
                                );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: sereneTheme.spacing.lg),

          // Calendar Section (Phase 2)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.settingsCalendarSection,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: sereneTheme.spacing.sm),
          _SettingsSectionCard(
            children: [
              SwitchListTile(
                title: Text(l10n.settingsCalendarToggle),
                subtitle: Text(l10n.settingsCalendarDesc),
                value: prefs.calendarSyncEnabled,
                onChanged: (val) => _toggleCalendarSync(val, l10n),
              ),
            ],
          ),
          SizedBox(height: sereneTheme.spacing.lg),

          // Diagnostic section
          Text(
            'Diagnóstico',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: sereneTheme.spacing.sm),
          const _NotificationDiagnostics(),
        ],
      ),
    );
  }
}

class _NotificationDiagnostics extends ConsumerStatefulWidget {
  const _NotificationDiagnostics();

  @override
  ConsumerState<_NotificationDiagnostics> createState() =>
      _NotificationDiagnosticsState();
}

class _NotificationDiagnosticsState
    extends ConsumerState<_NotificationDiagnostics> {
  int _pending = -1;
  bool _notifGranted = false;
  bool _exactGranted = false;
  bool _calendarGranted = false;
  bool _batteryIgnored = false;
  String? _lastTestResult;
  String? _lastSyncReport;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final scheduler = ref.read(notificationSchedulerProvider);
    final pending = await scheduler.pendingCount();
    final notifStatus = await Permission.notification.status;
    final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
    final calStatus = await DeviceCalendarPlugin().hasPermissions();

    var exact = exactAlarmsAllowed;
    final plugin = ref.read(flutterLocalNotificationsPluginProvider);
    final android = plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      try {
        exact = await android.canScheduleExactNotifications() ?? exact;
        exactAlarmsAllowed = exact;
      } catch (_) {}
    }

    final report = ref.read(syncNotificationsUseCaseProvider).lastReport;

    if (!mounted) return;
    setState(() {
      _pending = pending;
      _notifGranted = notifStatus.isGranted;
      _exactGranted = exact;
      _batteryIgnored = batteryStatus.isGranted;
      _calendarGranted =
          calStatus.isSuccess && (calStatus.data ?? false);
      _lastSyncReport = report?.oneLine;
    });
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _requestBattery() async {
    final status = await Permission.ignoreBatteryOptimizations.request();
    await _refresh();
    _toast(
      status.isGranted
          ? 'Optimización de batería ignorada'
          : 'No se concedió. Hazlo manualmente desde Ajustes → Batería',
    );
  }

  Future<void> _runTest() async {
    final scheduler = ref.read(notificationSchedulerProvider);
    try {
      await scheduler.showTest(
        title: 'Prueba MyPills',
        body: 'Si ves esto, las notificaciones funcionan.',
      );
      setState(() => _lastTestResult = 'Enviada');
      _toast('Notificación enviada');
    } catch (e) {
      setState(() => _lastTestResult = 'Error: $e');
      _toast('Error: $e');
    }
    await _refresh();
  }

  Future<void> _resync() async {
    await ref.read(syncNotificationsUseCaseProvider).call();
    await _refresh();
    _toast('Re-sincronizado · cola: $_pending');
  }

  Future<void> _listPending() async {
    final scheduler = ref.read(notificationSchedulerProvider);
    final list = await scheduler.pendingNotifications();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Pendientes (${list.length})'),
        content: SizedBox(
          width: double.maxFinite,
          child: list.isEmpty
              ? const Text('No hay notificaciones programadas.')
              : ListView(
                  shrinkWrap: true,
                  children: list
                      .map(
                        (e) => ListTile(
                          dense: true,
                          title: Text('id=${e.id} · ${e.title ?? "—"}'),
                          subtitle: Text(e.body ?? ''),
                        ),
                      )
                      .toList(),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _scheduleTest1Min() async {
    final scheduler = ref.read(notificationSchedulerProvider);
    try {
      await scheduler.scheduleTestIn(
        delay: const Duration(minutes: 1),
        title: 'Prueba programada MyPills',
        body: 'Si la ves, el scheduler funciona end-to-end.',
      );
      _toast('Programada para dentro de 1 min. Espera y observa.');
    } catch (e) {
      _toast('Error al programar: $e');
    }
    await _refresh();
  }

  String _yesNo(bool v) => v ? 'sí' : 'no';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sereneTheme = theme.extension<SereneTheme>()!;

    final inApp = ref.read(inAppReminderServiceProvider);
    final next = inApp.nextReminder();
    final lastCheck = inApp.lastCheckAt;
    String tzName;
    try {
      tzName = tz.local.name;
    } catch (_) {
      tzName = 'unset';
    }
    final mode = exactAlarmsAllowed ? 'exact' : 'inexact';
    final testDetail = FlutterLocalNotificationScheduler.lastTestDetail;

    return _SettingsSectionCard(
      children: [
        Padding(
          padding: EdgeInsets.all(sereneTheme.spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Permiso notificaciones: ${_yesNo(_notifGranted)}'),
              Text('Alarmas exactas: ${_yesNo(_exactGranted)}'),
              Text('Ignorar optimización batería: ${_yesNo(_batteryIgnored)}'),
              Text('Permiso calendario: ${_yesNo(_calendarGranted)}'),
              Text('Notificaciones en cola: $_pending'),
              Text('Zona horaria: $tzName · modo: $mode'),
              if (testDetail != null) ...[
                const Divider(),
                Text('Última prueba 1-min:', style: theme.textTheme.bodySmall),
                Text(testDetail, style: theme.textTheme.bodySmall),
              ],
              const Divider(),
              Text(
                'In-app · dosis hoy: ${inApp.currentDosesCount} '
                '(pendientes: ${inApp.pendingDosesCount}) · '
                'disparadas: ${inApp.firedToday}',
                style: theme.textTheme.bodySmall,
              ),
              Text(
                'In-app · último check: ${lastCheck ?? "—"}',
                style: theme.textTheme.bodySmall,
              ),
              Text(
                next == null
                    ? 'In-app · próxima: —'
                    : 'In-app · próxima dose=${next.doseId} '
                          'fireAt=${next.fireAt}',
                style: theme.textTheme.bodySmall,
              ),
              if (_lastSyncReport != null) ...[
                const Divider(),
                Text('Último sync:', style: theme.textTheme.bodySmall),
                Text(_lastSyncReport!, style: theme.textTheme.bodySmall),
              ],
              if (_lastTestResult != null) ...[
                SizedBox(height: sereneTheme.spacing.sm),
                Text('Última prueba: $_lastTestResult'),
              ],
              SizedBox(height: sereneTheme.spacing.md),
              Wrap(
                spacing: sereneTheme.spacing.sm,
                runSpacing: sereneTheme.spacing.sm,
                children: [
                  ElevatedButton(
                    onPressed: _runTest,
                    child: const Text('Probar push ya'),
                  ),
                  ElevatedButton(
                    onPressed: _scheduleTest1Min,
                    child: const Text('Probar push en 1 min'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      ref
                          .read(inAppReminderServiceProvider)
                          .fireDiagnosticTest();
                      _toast('Modal disparado (revisa la pantalla)');
                    },
                    child: const Text('Probar modal'),
                  ),
                  OutlinedButton(
                    onPressed: _listPending,
                    child: const Text('Listar pendientes'),
                  ),
                  OutlinedButton(
                    onPressed: _resync,
                    child: const Text('Re-sincronizar'),
                  ),
                  OutlinedButton(
                    onPressed: () async {
                      await _refresh();
                      _toast('Actualizado');
                    },
                    child: const Text('Actualizar'),
                  ),
                  if (!_batteryIgnored)
                    OutlinedButton(
                      onPressed: _requestBattery,
                      child: const Text('Ignorar batería'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsSectionCard extends StatelessWidget {
  const _SettingsSectionCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sereneTheme = theme.extension<SereneTheme>()!;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: sereneTheme.radius.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _ProfileCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileRepositoryProvider).getProfile();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sereneTheme = theme.extension<SereneTheme>()!;
    final l10n = AppLocalizations.of(context);

    return InkWell(
      onTap: () => context.push(AppRoutes.editProfile),
      borderRadius: sereneTheme.radius.lg,
      child: Container(
        padding: EdgeInsets.all(sereneTheme.spacing.md),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: sereneTheme.radius.lg,
          border: Border.all(
            color: colorScheme.outlineVariant.withOpacity(0.5),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: colorScheme.primaryContainer,
              child: profile?.photoPath != null
                  ? ClipOval(
                      child: Image.asset(
                        profile!.photoPath!,
                        fit: BoxFit.cover,
                        width: 60,
                        height: 60,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.person,
                          color: colorScheme.primary,
                          size: 30,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.person,
                      color: colorScheme.primary,
                      size: 30,
                    ),
            ),
            SizedBox(width: sereneTheme.spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile?.name ?? 'Usuario',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    l10n.editProfileTitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
