import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_pills/app/providers.dart';
import 'package:my_pills/app/router.dart';
import 'package:my_pills/core/errors/failure.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/core/theme/serene_theme.dart';
import 'package:my_pills/core/widgets/app_avatar.dart';
import 'package:my_pills/core/widgets/app_notification.dart';
import 'package:my_pills/core/widgets/sanctuary_app_bar.dart';
import 'package:my_pills/features/auth/presentation/providers/auth_providers.dart';
import 'package:my_pills/features/calendar_integration/domain/calendar_connection.dart';
import 'package:my_pills/features/calendar_integration/domain/google_calendar_link.dart';
import 'package:my_pills/features/calendar_integration/presentation/google_calendar_link_messages.dart';
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
            l10n.settingsCloudCalendarSection,
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

  CalendarConnection? _connection(
    List<CalendarConnection> connections,
    CalendarProvider provider,
  ) {
    return connections
        .where((connection) => connection.provider == provider)
        .firstOrNull;
  }

  Future<void> _connect(CalendarProvider provider) async {
    if (provider == CalendarProvider.google) {
      await _connectGoogle();
      return;
    }
    await _connectViaBrowser(provider.wire);
  }

  Future<void> _connectGoogle() async {
    final l10n = AppLocalizations.of(context);
    final profile = ref.read(currentUserProfileProvider);
    final profileId = profile?.id ?? '';
    setState(() => _isLoading = true);
    final email = ref.read(authProvider).asData?.value?.email;
    final outcome = await linkGoogleCalendarForProfile(
      ref: ref,
      profileId: profileId,
      expectedEmail: email,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (outcome is GoogleCalendarLinked) {
      AppNotification.showSuccess(
        context,
        l10n.settingsCloudCalendarConnectedToast,
      );
      await _syncNow();
      return;
    }

    final message = googleCalendarLinkMessage(l10n, outcome);
    if (message == null || !mounted) return;
    if (outcome is GoogleCalendarLinkFailed) {
      AppNotification.showError(context, message);
      return;
    }
    AppNotification.showWarning(context, message);
  }

  Future<void> _connectViaBrowser(String provider) async {
    final l10n = AppLocalizations.of(context);
    final profile = ref.read(currentUserProfileProvider);
    if (profile == null) {
      AppNotification.showWarning(
        context,
        l10n.settingsCloudCalendarNoProfile,
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
            await launchUrl(uri);
          }
        } catch (e) {
          if (mounted) {
            AppNotification.showError(
              context,
              l10n.settingsCloudCalendarBrowserFailed('$e'),
            );
          }
        }
      } else {
        if (mounted) {
          AppNotification.showError(
            context,
            l10n.settingsCloudCalendarInvalidAuthUrl,
          );
        }
      }
    } else if (result case FailureResult(:final failure)) {
      final msg = switch (failure) {
        ServerFailure(:final message) =>
          message ?? l10n.settingsCloudCalendarAuthorizeFailed,
        _ => l10n.settingsCloudCalendarAuthorizeFailed,
      };
      if (mounted) {
        AppNotification.showError(
          context,
          l10n.settingsCloudCalendarConnectError(msg),
        );
      }
    }
  }

  Future<void> _disconnect(CalendarProvider provider) async {
    final l10n = AppLocalizations.of(context);
    final profile = ref.read(currentUserProfileProvider);
    if (profile == null) return;
    setState(() => _isLoading = true);
    final calendarService = ref.read(pkceCalendarServiceProvider);
    final result = await calendarService.disconnectCalendar(
      profileId: profile.id,
      provider: provider.wire,
    );
    if (!mounted) return;
    ref.invalidate(calendarConnectionsProvider(profile.id));
    setState(() => _isLoading = false);
    if (result case FailureResult(:final failure)) {
      AppNotification.showError(
        context,
        switch (failure) {
          ServerFailure(:final message) =>
            message ?? l10n.settingsCloudCalendarDisconnectFailed,
          _ => l10n.settingsCloudCalendarDisconnectFailed,
        },
      );
    }
  }

  Future<void> _syncNow() async {
    final l10n = AppLocalizations.of(context);
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
        message = _describeSkips(l10n, skipped);
      } else {
        message = l10n.settingsCloudCalendarSyncOk(created, updated);
      }
      AppNotification.showInfo(context, message);
    } else if (result case FailureResult(:final failure)) {
      AppNotification.showError(
        context,
        _describeSyncFailure(l10n, failure),
      );
    } else {
      AppNotification.showError(
        context,
        l10n.settingsCloudCalendarSyncFailed,
      );
    }
  }

  String _describeSyncFailure(AppLocalizations l10n, Failure failure) {
    if (failure is ServerFailure && failure.message != null) {
      return _messageForReason(l10n, failure.message!) ??
          l10n.settingsCloudCalendarSyncFailed;
    }
    return l10n.settingsCloudCalendarSyncFailed;
  }

  String _describeSkips(AppLocalizations l10n, List<String> reasons) {
    for (final reason in reasons) {
      final message = _messageForReason(l10n, reason);
      if (message != null) return message;
    }
    return l10n.settingsCloudCalendarSyncEmpty;
  }

  String? _messageForReason(AppLocalizations l10n, String reason) {
    return switch (reason) {
      'UPSERT_FAILED' => l10n.settingsCloudCalendarReasonUpsert,
      'REFRESH_FAILED' => l10n.settingsCloudCalendarReasonRefresh,
      'REAUTH_REQUIRED' => l10n.settingsCloudCalendarReasonReauth,
      'NO_MEDICATIONS' => l10n.settingsCloudCalendarReasonNoMedications,
      'NO_SCHEDULES' => l10n.settingsCloudCalendarReasonNoSchedules,
      'NO_UPCOMING_DOSE_EVENTS' => l10n.settingsCloudCalendarReasonNoDoses,
      _ => null,
    };
  }

  String _subtitleFor(CalendarConnection? connection, AppLocalizations l10n) {
    if (connection?.needsReauth ?? false) {
      return l10n.settingsCloudCalendarReauthRequired;
    }
    if (connection?.isActive ?? false) {
      return l10n.settingsCloudCalendarConnected;
    }
    return l10n.settingsCloudCalendarNotConnected;
  }

  Widget _trailingFor(
    CalendarConnection? connection,
    CalendarProvider provider,
    AppLocalizations l10n,
  ) {
    if (connection?.needsReauth ?? false) {
      return FilledButton.tonal(
        onPressed: _isLoading ? null : () => _connect(provider),
        child: Text(l10n.settingsCloudCalendarReconnect),
      );
    }
    if (connection?.isActive ?? false) {
      return OutlinedButton(
        onPressed: _isLoading ? null : () => _disconnect(provider),
        child: Text(l10n.settingsCloudCalendarDisconnect),
      );
    }
    return FilledButton.tonal(
      onPressed: _isLoading ? null : () => _connect(provider),
      child: Text(l10n.settingsCloudCalendarConnect),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final serene = theme.extension<SereneTheme>()!;
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(currentUserProfileProvider);
    final connections = profile == null
        ? const <CalendarConnection>[]
        : ref.watch(calendarConnectionsProvider(profile.id)).value ??
              const <CalendarConnection>[];
    final google = _connection(connections, CalendarProvider.google);
    final microsoft = _connection(connections, CalendarProvider.microsoft);
    final anyActive =
        (google?.isActive ?? false) || (microsoft?.isActive ?? false);

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
              l10n.settingsCloudCalendarDesc,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: serene.spacing.md),
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.event,
                color: theme.colorScheme.primary,
                size: serene.spacing.xl,
              ),
              title: Text(
                l10n.settingsCloudCalendarGoogle,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(_subtitleFor(google, l10n)),
              trailing: _trailingFor(google, CalendarProvider.google, l10n),
            ),
            const Divider(height: 1),
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.calendar_today,
                color: theme.colorScheme.primary,
                size: serene.spacing.xl,
              ),
              title: Text(
                l10n.settingsCloudCalendarMicrosoft,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(_subtitleFor(microsoft, l10n)),
              trailing: _trailingFor(
                microsoft,
                CalendarProvider.microsoft,
                l10n,
              ),
            ),
            if (anyActive) ...[
              SizedBox(height: serene.spacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _syncNow,
                  icon: Icon(Icons.sync_rounded, size: serene.spacing.xl),
                  label: Text(l10n.settingsCloudCalendarSyncNow),
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
