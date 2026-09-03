import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:my_pills/app/providers.dart';
import 'package:my_pills/app/router.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/core/theme/serene_theme.dart';
import 'package:my_pills/core/widgets/app_notification.dart';
import 'package:my_pills/features/schedules/domain/entities/schedule.dart';
import 'package:my_pills/l10n/app_localizations.dart';

class MedicationSchedulesSheet extends ConsumerWidget {
  const MedicationSchedulesSheet({
    required this.medicationId,
    required this.medicationName,
    super.key,
  });

  final int medicationId;
  final String medicationName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final serene = theme.extension<SereneTheme>()!;
    final schedulesAsync = ref.watch(
      schedulesForMedicationProvider(medicationId),
    );

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        serene.spacing.lg,
        serene.spacing.lg,
        serene.spacing.lg,
        serene.spacing.lg + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: serene.spacing.lg),
          Text(
            l10n.activeSchedulesTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: serene.spacing.xs),
          Text(
            medicationName,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: serene.spacing.xl),
          schedulesAsync.when(
            data: (result) {
              if (result case FailureResult()) {
                return Text(l10n.errorUnexpected);
              }
              final schedules = result.valueOrNull!;
              if (schedules.isEmpty) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: serene.spacing.xl),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.schedule_outlined,
                          size: 48,
                          color: theme.colorScheme.outlineVariant,
                        ),
                        SizedBox(height: serene.spacing.md),
                        Text(
                          l10n.noSchedulesYet,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return Column(
                children: schedules
                    .map(
                      (s) => Padding(
                        padding: EdgeInsets.only(bottom: serene.spacing.md),
                        child: _ScheduleItem(
                          schedule: s,
                          onCancelAlerts: () => unawaited(
                            _cancelScheduleAlerts(context, ref, s),
                          ),
                          onDelete: () =>
                              unawaited(_deleteSchedule(context, ref, s)),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Text(l10n.errorUnexpected),
          ),
          SizedBox(height: serene.spacing.lg),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                await context.push(
                  AppRoutes.schedulerDaily,
                  extra: medicationId,
                );
              },
              icon: const Icon(Icons.add),
              label: Text(l10n.addScheduleButton),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: theme.extension<SereneTheme>()!.radius.md,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelScheduleAlerts(
    BuildContext context,
    WidgetRef ref,
    Schedule schedule,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.cancelRecurringTitle),
        content: Text(l10n.cancelRecurringConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.primary,
            ),
            child: Text(l10n.cancelRecurringButton),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final result = await ref
        .read(cancelRecurringNotificationsUseCaseProvider)
        .call(
          scheduleId: schedule.id,
        );
    if (!context.mounted) return;
    if (result case FailureResult()) {
      AppNotification.showError(
        context,
        l10n.errorUnexpected,
      );
      return;
    }
    AppNotification.showSuccess(
      context,
      l10n.recurringAlertsCancelledMessage,
    );
  }

  Future<void> _deleteSchedule(
    BuildContext context,
    WidgetRef ref,
    Schedule schedule,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteScheduleTitle),
        content: Text(l10n.deleteScheduleConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(l10n.deleteButton),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final result = await ref
        .read(deleteScheduleUseCaseProvider)
        .call(schedule.id);
    if (!context.mounted) return;
    if (result case FailureResult()) {
      AppNotification.showError(
        context,
        l10n.errorUnexpected,
      );
      return;
    }
    AppNotification.showSuccess(
      context,
      l10n.scheduleDeletedMessage,
    );
  }
}

class _ScheduleItem extends StatelessWidget {
  const _ScheduleItem({
    required this.schedule,
    required this.onCancelAlerts,
    required this.onDelete,
  });

  final Schedule schedule;
  final VoidCallback onCancelAlerts;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final serene = theme.extension<SereneTheme>()!;
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: EdgeInsets.all(serene.spacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: serene.radius.lg,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: serene.radius.md,
            ),
            child: Icon(
              _iconFor(schedule),
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          SizedBox(width: serene.spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _typeLabel(schedule),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (schedule.dose != null &&
                        schedule.dose!.display.isNotEmpty)
                      schedule.dose!.display,
                    _timesLabel(schedule),
                  ].join(' · '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (schedule.endDate != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Hasta ${DateFormat.yMMMd('es').format(schedule.endDate!)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            shape: RoundedRectangleBorder(borderRadius: serene.radius.md),
            color: theme.colorScheme.surfaceContainerHighest,
            onSelected: (value) {
              if (value == 'cancel_alerts') {
                onCancelAlerts();
              } else if (value == 'delete') {
                onDelete();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'cancel_alerts',
                child: Row(
                  children: [
                    Icon(
                      Icons.notifications_off_outlined,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    SizedBox(width: serene.spacing.sm),
                    Text(l10n.cancelRecurringButton),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: theme.colorScheme.error,
                    ),
                    SizedBox(width: serene.spacing.sm),
                    Text(
                      l10n.deleteButton,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _iconFor(Schedule schedule) => switch (schedule) {
    DailySchedule() => Icons.calendar_today_outlined,
    DailyIntervalSchedule() => Icons.replay_outlined,
    SpecificDaysSchedule() => Icons.event_repeat_outlined,
  };

  String _typeLabel(Schedule schedule) => switch (schedule) {
    DailySchedule() => 'Diario',
    DailyIntervalSchedule(:final everyHours) => 'Cada $everyHours horas',
    SpecificDaysSchedule(:final daysOfWeek) => _daysLabel(daysOfWeek),
  };

  String _daysLabel(List<int> days) {
    const names = ['', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return days.map((d) => names[d]).join(', ');
  }

  String _timesLabel(Schedule schedule) {
    final times = switch (schedule) {
      DailySchedule(:final timesOfDay) => timesOfDay,
      DailyIntervalSchedule(:final startAt) => [startAt],
      SpecificDaysSchedule(:final timesOfDay) => timesOfDay,
    };
    return times
        .map((t) {
          final h = t.hour.toString().padLeft(2, '0');
          final m = t.minute.toString().padLeft(2, '0');
          return '$h:$m';
        })
        .join(', ');
  }
}
