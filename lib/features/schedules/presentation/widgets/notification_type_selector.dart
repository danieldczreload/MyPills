import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_pills/app/providers.dart';
import 'package:my_pills/app/router.dart';
import 'package:my_pills/core/theme/serene_theme.dart';
import 'package:my_pills/features/profile/presentation/providers/profile_providers.dart';

/// Serene Selector for choosing reminder delivery methods per schedule (Push and/or Calendar).
class NotificationTypeSelector extends ConsumerWidget {
  const NotificationTypeSelector({
    required this.notifyPush,
    required this.notifyCalendar,
    required this.onPushChanged,
    required this.onCalendarChanged,
    super.key,
  });

  final bool notifyPush;
  final bool notifyCalendar;
  final ValueChanged<bool> onPushChanged;
  final ValueChanged<bool> onCalendarChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final serene = theme.extension<SereneTheme>()!;
    final profile = ref.watch(currentUserProfileProvider);
    final profileId = profile?.id ?? 'default';
    final connectionsAsync = ref.watch(calendarConnectionsProvider(profileId));
    final connections = connectionsAsync.value ?? [];
    final hasConnectedCalendar = connections.any(
      (c) => c['connected'] == true || c['status'] == 'active',
    );
    final connectedProviderName = connections
        .where((c) => c['connected'] == true || c['status'] == 'active')
        .map((c) => c['provider'] == 'google' ? 'Google Calendar' : 'Outlook')
        .join(', ');

    return Container(
      padding: EdgeInsets.all(serene.spacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: serene.radius.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notifications_none_rounded,
                color: theme.colorScheme.primary,
                size: 22,
              ),
              SizedBox(width: serene.spacing.sm),
              Text(
                'Método de Recordatorio',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: serene.spacing.xs),
          Text(
            'Elige cómo deseas que te avisemos para tomar este medicamento.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: serene.spacing.md),
          // Push notifications option
          Container(
            padding: EdgeInsets.all(serene.spacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              borderRadius: serene.radius.md,
              border: Border.all(
                color: notifyPush
                    ? theme.colorScheme.primary.withValues(alpha: 0.3)
                    : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                width: notifyPush ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(serene.spacing.sm),
                  decoration: BoxDecoration(
                    color: notifyPush
                        ? theme.colorScheme.primaryContainer.withValues(
                            alpha: 0.4,
                          )
                        : theme.colorScheme.surfaceContainerHigh,
                    borderRadius: serene.radius.sm,
                  ),
                  child: Icon(
                    Icons.alarm_rounded,
                    color: notifyPush
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
                SizedBox(width: serene.spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notificación / Alarma del móvil',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Alerta sonora y aviso en pantalla.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: notifyPush,
                  onChanged: onPushChanged,
                  activeTrackColor: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
          SizedBox(height: serene.spacing.sm),
          // Calendar integration option
          Container(
            padding: EdgeInsets.all(serene.spacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              borderRadius: serene.radius.md,
              border: Border.all(
                color: notifyCalendar
                    ? theme.colorScheme.secondary.withValues(alpha: 0.3)
                    : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                width: notifyCalendar ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(serene.spacing.sm),
                      decoration: BoxDecoration(
                        color: notifyCalendar
                            ? theme.colorScheme.secondaryContainer.withValues(
                                alpha: 0.4,
                              )
                            : theme.colorScheme.surfaceContainerHigh,
                        borderRadius: serene.radius.sm,
                      ),
                      child: Icon(
                        Icons.calendar_month_rounded,
                        color: notifyCalendar
                            ? theme.colorScheme.secondary
                            : theme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: serene.spacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sincronizar con Calendario',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Crea eventos en Google Calendar u Outlook.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: notifyCalendar,
                      onChanged: (val) {
                        onCalendarChanged(val);
                        if (val && !hasConnectedCalendar) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Aviso: No tienes ningún calendario conectado aún.',
                              ),
                              action: SnackBarAction(
                                label: 'Conectar',
                                onPressed: () =>
                                    context.push(AppRoutes.settings),
                              ),
                            ),
                          );
                        }
                      },
                      activeTrackColor: theme.colorScheme.secondary,
                    ),
                  ],
                ),
                if (notifyCalendar) ...[
                  SizedBox(height: serene.spacing.sm),
                  if (hasConnectedCalendar)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: serene.spacing.sm,
                        vertical: serene.spacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(
                          alpha: 0.3,
                        ),
                        borderRadius: serene.radius.sm,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                          SizedBox(width: serene.spacing.xs),
                          Text(
                            'Vinculado con $connectedProviderName',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: EdgeInsets.all(serene.spacing.sm),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer.withValues(
                          alpha: 0.2,
                        ),
                        borderRadius: serene.radius.sm,
                        border: Border.all(
                          color: theme.colorScheme.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 16,
                            color: theme.colorScheme.error,
                          ),
                          SizedBox(width: serene.spacing.xs),
                          Expanded(
                            child: Text(
                              'Sin cuenta de calendario conectada.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () => context.push(AppRoutes.settings),
                            child: const Text('Conectar'),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
