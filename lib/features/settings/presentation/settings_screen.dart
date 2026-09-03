import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_pills/app/providers.dart';
import 'package:my_pills/app/router.dart';
import 'package:my_pills/core/auth/app_google_sign_in.dart';
import 'package:my_pills/core/config/env_config.dart';
import 'package:my_pills/core/errors/failure.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/core/theme/serene_theme.dart';
import 'package:my_pills/core/widgets/app_avatar.dart';
import 'package:my_pills/core/widgets/app_notification.dart';
import 'package:my_pills/core/widgets/sanctuary_app_bar.dart';
import 'package:my_pills/features/auth/presentation/providers/auth_providers.dart';
import 'package:my_pills/features/notifications/presentation/providers/notification_providers.dart';
import 'package:my_pills/features/profile/presentation/providers/profile_providers.dart';
import 'package:my_pills/features/profile/presentation/widgets/profile_switch_sheet.dart';
import 'package:my_pills/l10n/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _hasNotificationPermission = false;

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
      await ref
          .read(notificationPreferencesProvider.notifier)
          .updatePreferences(
            (p) => p.copyWith(pushNotificationsEnabled: true),
          );
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
          SizedBox(height: sereneTheme.spacing.md),
          const _CloudAccountCard(),
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
                const Divider(height: 1),
                Padding(
                  padding: EdgeInsets.all(sereneTheme.spacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(
                          Icons.notifications_active_outlined,
                          size: 18,
                        ),
                        label: const Text('Probar notificación ahora'),
                        onPressed: () async {
                          await ref
                              .read(notificationSchedulerProvider)
                              .showTest(
                                title: '🔔 Notificación de prueba',
                                body:
                                    '¡Tus recordatorios de MyPills están funcionando correctamente!',
                              );
                          if (context.mounted) {
                            AppNotification.showSuccess(
                              context,
                              'Notificación de prueba enviada',
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

          // Cloud Calendars Section (Google & Microsoft OAuth PKCE)
          Text(
            'Calendarios en la Nube (Google / Outlook)',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: sereneTheme.spacing.sm),
          const _CloudCalendarCard(),
        ],
      ),
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

    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: sereneTheme.radius.lg,
      clipBehavior: Clip.antiAlias,
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
    final profile = ref.watch(currentUserProfileProvider);
    final allProfiles = ref.watch(allProfilesProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sereneTheme = theme.extension<SereneTheme>()!;

    return InkWell(
      onTap: () => showProfileSwitchSheet(context),
      borderRadius: sereneTheme.radius.lg,
      child: Container(
        padding: EdgeInsets.all(sereneTheme.spacing.md),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: sereneTheme.radius.lg,
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            AppAvatar(
              photoPath: profile?.photoPath,
              radius: 30,
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
                    '${allProfiles.length} perfil(es) · Toca para cambiar o agregar',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.unfold_more_rounded,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _CloudCalendarCard extends ConsumerStatefulWidget {
  const _CloudCalendarCard();

  @override
  ConsumerState<_CloudCalendarCard> createState() => _CloudCalendarCardState();
}

class _CloudCalendarCardState extends ConsumerState<_CloudCalendarCard> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _connections = [];

  @override
  void initState() {
    super.initState();
    _fetchConnections();
  }

  Future<void> _fetchConnections() async {
    final profile = ref.read(currentUserProfileProvider);
    if (profile == null) return;
    final calendarService = ref.read(pkceCalendarServiceProvider);
    final result = await calendarService.getConnections(profileId: profile.id);
    if (result case Success(:final value)) {
      if (mounted) {
        setState(() => _connections = value);
      }
    }
  }

  bool _isConnected(String provider) {
    return _connections.any(
      (c) =>
          c['provider'] == provider &&
          (c['connected'] == true || c['status'] == 'active'),
    );
  }

  Future<void> _connect(String provider) async {
    if (provider == 'google') {
      await _connectGoogle();
      return;
    }
    await _connectViaBrowser(provider);
  }

  /// Google Calendar uses the native google_sign_in flow: the SDK requests
  /// the calendar scope and returns a serverAuthCode that the backend
  /// exchanges for tokens (browser redirect flows are rejected by Google on
  /// Android clients).
  Future<void> _connectGoogle() async {
    final profile = ref.read(currentUserProfileProvider);
    if (profile == null) {
      AppNotification.showWarning(
        context,
        'No hay un perfil activo seleccionado',
      );
      return;
    }

    String? message;
    setState(() => _isLoading = true);
    try {
      // Drop the login-only grant. signOut() + silent sign-in reuses the
      // original email/profile token (no calendar scope) and Google Calendar
      // then returns 403 ACCESS_TOKEN_SCOPE_INSUFFICIENT.
      await appGoogleSignIn.disconnect();
      final account = await appGoogleSignIn.signIn();
      if (!mounted) return;

      if (account == null) {
        // User cancelled the Google sign-in dialog.
        setState(() => _isLoading = false);
        return;
      }

      final granted = await appGoogleSignIn.requestScopes(
        [EnvConfig.googleCalendarScope],
      );
      if (!mounted) return;
      if (!granted) {
        setState(() => _isLoading = false);
        AppNotification.showWarning(
          context,
          'Se necesita permiso de Google Calendar para sincronizar.',
        );
        return;
      }

      final serverAuthCode =
          account.serverAuthCode ?? appGoogleSignIn.currentUser?.serverAuthCode;
      if (serverAuthCode == null || serverAuthCode.isEmpty) {
        setState(() => _isLoading = false);
        AppNotification.showError(
          context,
          'No se obtuvo autorización de Google. Intenta de nuevo.',
        );
        return;
      }

      final calendarService = ref.read(pkceCalendarServiceProvider);
      final result = await calendarService.connectWithServerAuthCode(
        profileId: profile.id,
        code: serverAuthCode,
      );
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result case FailureResult(:final failure)) {
        message = switch (failure) {
          ServerFailure(:final message) => message ?? 'Error del servidor',
          _ => 'Fallo al conectar Google Calendar',
        };
      } else {
        await _fetchConnections();
        if (!mounted) return;
        AppNotification.showSuccess(
          context,
          'Google Calendar conectado',
        );
        await _syncNow();
        return;
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      message = 'Error al conectar: $e';
    }

    if (message != null && mounted) {
      AppNotification.showError(context, message);
    }
  }

  Future<void> _connectViaBrowser(String provider) async {
    final profile = ref.read(currentUserProfileProvider);
    if (profile == null) {
      AppNotification.showWarning(
        context,
        'No hay un perfil activo seleccionado',
      );
      return;
    }
    setState(() => _isLoading = true);
    final calendarService = ref.read(pkceCalendarServiceProvider);
    final result = await calendarService.initiateAuthorization(
      profileId: profile.id,
      provider: provider,
    );
    setState(() => _isLoading = false);

    if (result case Success(:final value)) {
      final uri = Uri.tryParse(value.authorizationUrl);
      if (uri != null) {
        try {
          final launched = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
          if (!launched) {
            await launchUrl(uri, mode: LaunchMode.platformDefault);
          }
        } catch (e) {
          if (mounted) {
            AppNotification.showError(
              context,
              'No se pudo abrir el navegador: $e',
            );
          }
        }
      } else {
        if (mounted) {
          AppNotification.showError(
            context,
            'URL de autorización inválida',
          );
        }
      }
    } else if (result case FailureResult(:final failure)) {
      final msg = switch (failure) {
        ServerFailure(:final message) => message ?? 'Error del servidor',
        _ => 'Fallo al autorizar',
      };
      if (mounted) {
        AppNotification.showError(
          context,
          'Error al conectar: $msg',
        );
      }
    }
  }

  Future<void> _disconnect(String provider) async {
    final profile = ref.read(currentUserProfileProvider);
    if (profile == null) return;
    setState(() => _isLoading = true);
    final calendarService = ref.read(pkceCalendarServiceProvider);
    await calendarService.disconnectCalendar(
      profileId: profile.id,
      provider: provider,
    );
    await _fetchConnections();
    setState(() => _isLoading = false);
  }

  Future<void> _syncNow() async {
    final profile = ref.read(currentUserProfileProvider);
    if (profile == null) return;
    setState(() => _isLoading = true);
    final calendarService = ref.read(pkceCalendarServiceProvider);
    final result = await calendarService.syncCalendar(profileId: profile.id);
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result case Success(:final value)) {
      final created = (value['eventsCreated'] as num?)?.toInt() ?? 0;
      final updated = (value['eventsUpdated'] as num?)?.toInt() ?? 0;
      final skipped = (value['skipped'] as List<dynamic>? ?? const [])
          .map((s) => s is Map<String, dynamic> ? s['reason'] as String? : null)
          .whereType<String>()
          .toList();

      final String message;
      if (created == 0 && updated == 0) {
        message = _describeSkips(skipped);
      } else {
        message =
            'Sincronización exitosa: $created creados, $updated actualizados';
      }
      AppNotification.showInfo(context, message);
    } else if (result case FailureResult(:final failure)) {
      AppNotification.showError(
        context,
        _describeSyncFailure(failure),
      );
    } else {
      AppNotification.showError(
        context,
        'No se pudo sincronizar el calendario en la nube',
      );
    }
  }

  String _describeSyncFailure(Failure failure) {
    if (failure is ServerFailure && failure.message != null) {
      return _messageForReason(failure.message!) ??
          'No se pudo sincronizar el calendario en la nube';
    }
    return 'No se pudo sincronizar el calendario en la nube';
  }

  String _describeSkips(List<String> reasons) {
    for (final reason in reasons) {
      final message = _messageForReason(reason);
      if (message != null) return message;
    }
    return 'Sincronización completada: no hay eventos por crear';
  }

  String? _messageForReason(String reason) {
    return switch (reason) {
      'UPSERT_FAILED' =>
        'Google no autorizó el calendario. Desconecta y vuelve a conectar aceptando el permiso.',
      'REFRESH_FAILED' =>
        'No se pudo sincronizar con el proveedor de calendario',
      'REAUTH_REQUIRED' =>
        'Reautoriza la conexión de calendario e intenta de nuevo',
      'NO_MEDICATIONS' =>
        'Sin medicamentos registrados: no hay eventos que sincronizar',
      'NO_SCHEDULES' => 'Sin horarios activos: no hay eventos que sincronizar',
      'NO_UPCOMING_DOSE_EVENTS' =>
        'No hay dosis próximas en los siguientes 14 días',
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final serene = theme.extension<SereneTheme>()!;
    final googleConnected = _isConnected('google');
    final microsoftConnected = _isConnected('microsoft');

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: serene.radius.lg,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.all(serene.spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sincroniza tus dosis automáticamente con tu cuenta de Google Calendar o Microsoft Outlook.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: serene.spacing.md),
            // Google Calendar
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event, color: Colors.blue),
              title: const Text(
                'Google Calendar',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(googleConnected ? 'Conectado' : 'No conectado'),
              trailing: googleConnected
                  ? OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => _disconnect('google'),
                      child: const Text('Desconectar'),
                    )
                  : FilledButton.tonal(
                      onPressed: _isLoading ? null : () => _connect('google'),
                      child: const Text('Conectar'),
                    ),
            ),
            const Divider(height: 1),
            // Microsoft Outlook
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today, color: Colors.indigo),
              title: const Text(
                'Microsoft Outlook',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(microsoftConnected ? 'Conectado' : 'No conectado'),
              trailing: microsoftConnected
                  ? OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => _disconnect('microsoft'),
                      child: const Text('Desconectar'),
                    )
                  : FilledButton.tonal(
                      onPressed: _isLoading
                          ? null
                          : () => _connect('microsoft'),
                      child: const Text('Conectar'),
                    ),
            ),
            if (googleConnected || microsoftConnected) ...[
              SizedBox(height: serene.spacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _syncNow,
                  icon: const Icon(Icons.sync_rounded, size: 18),
                  label: const Text('Sincronizar eventos ahora'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CloudAccountCard extends ConsumerWidget {
  const _CloudAccountCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authProvider);
    final user = authAsync.asData?.value;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final serene = theme.extension<SereneTheme>()!;
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: EdgeInsets.all(serene.spacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: serene.radius.lg,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: user != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AppAvatar(
                      photoPath: user.photoUrl,
                      radius: 22,
                      fallbackIcon: Icons.cloud_done_rounded,
                      backgroundColor: colorScheme.secondaryContainer,
                      foregroundColor: colorScheme.secondary,
                    ),
                    SizedBox(width: serene.spacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name ?? l10n.settingsCloudSyncSection,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            user.email,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: serene.spacing.md),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final syncEngine = ref.read(syncEngineProvider);
                          await syncEngine.flushOutbox();
                          final prefs = ref.read(sharedPreferencesProvider);
                          final profileId = prefs.getString(
                            'active_profile_id',
                          );
                          if (profileId != null) {
                            await syncEngine.syncProfile(profileId);
                          }
                          if (context.mounted) {
                            AppNotification.showSuccess(
                              context,
                              l10n.settingsCloudSyncSuccess,
                            );
                          }
                        },
                        icon: const Icon(Icons.sync_rounded, size: 18),
                        label: Text(l10n.settingsCloudSyncSyncButton),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: serene.radius.lg,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: serene.spacing.sm),
                    TextButton(
                      onPressed: () async {
                        await ref.read(authProvider.notifier).logout();
                        ref.invalidate(currentUserProfileProvider);
                        ref.invalidate(allProfilesProvider);
                        if (context.mounted) {
                          AppNotification.showInfo(
                            context,
                            l10n.settingsCloudSyncLoggedOut,
                          );
                          context.go(AppRoutes.login);
                        }
                      },
                      child: Text(
                        l10n.settingsCloudSyncLogoutButton,
                        style: TextStyle(color: colorScheme.error),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Icon(
                  Icons.cloud_off_rounded,
                  color: colorScheme.onSurfaceVariant,
                  size: 24,
                ),
                SizedBox(width: serene.spacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.settingsCloudSyncLocalMode,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        l10n.settingsCloudSyncLocalModeDesc,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: serene.spacing.sm),
                FilledButton.tonal(
                  onPressed: () => context.push(AppRoutes.login),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: serene.radius.lg,
                    ),
                  ),
                  child: Text(l10n.settingsCloudSyncConnectButton),
                ),
              ],
            ),
    );
  }
}
