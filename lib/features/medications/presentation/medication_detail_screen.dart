import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:my_pills/app/providers.dart';
import 'package:my_pills/app/router.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/core/theme/serene_theme.dart';
import 'package:my_pills/features/medications/domain/entities/medication.dart';
import 'package:my_pills/features/medications/presentation/utils/medication_visual_helpers.dart';
import 'package:my_pills/features/schedules/domain/entities/schedule.dart';
import 'package:my_pills/l10n/app_localizations.dart';

class MedicationDetailScreen extends ConsumerWidget {
  const MedicationDetailScreen({required this.medication, super.key});

  final Medication medication;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final serene = theme.extension<SereneTheme>()!;
    final accentColor = resolveMedicationColor(medication.colorToken, theme);

    final schedulesAsync = ref.watch(
      schedulesForMedicationProvider(medication.id),
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () => context.push(
              AppRoutes.editMedication,
              extra: medication,
            ),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: Text(l10n.editMedicationStepLabel),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // ── Medication header ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                serene.spacing.lg,
                serene.spacing.md,
                serene.spacing.lg,
                serene.spacing.xl,
              ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: serene.radius.lg,
                    ),
                    child: Icon(
                      medicationFormIcon(medication.form),
                      color: accentColor,
                      size: 32,
                    ),
                  ),
                  SizedBox(width: serene.spacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medication.name,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: serene.spacing.xs),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: accentColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: serene.spacing.xs),
                            Text(
                              medication.category,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        if (medication.notes != null &&
                            medication.notes!.isNotEmpty) ...[
                          SizedBox(height: serene.spacing.xs),
                          Text(
                            medication.notes!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Divider ───────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Divider(
              height: 1,
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),

          // ── Schedules section header ──────────────────────────────────────
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              serene.spacing.lg,
              serene.spacing.xl,
              serene.spacing.lg,
              serene.spacing.md,
            ),
            sliver: SliverToBoxAdapter(
              child: Text(
                l10n.activeSchedulesTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // ── Schedules list ────────────────────────────────────────────────
          schedulesAsync.when(
            data: (result) {
              if (result case FailureResult()) {
                return SliverToBoxAdapter(child: Text(l10n.errorUnexpected));
              }
              final schedules = result.valueOrNull!;
              if (schedules.isEmpty) {
                return SliverPadding(
                  padding: EdgeInsets.symmetric(
                    horizontal: serene.spacing.lg,
                    vertical: serene.spacing.xl,
                  ),
                  sliver: SliverToBoxAdapter(
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
                  ),
                );
              }
              return SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: serene.spacing.lg),
                sliver: SliverList.separated(
                  itemCount: schedules.length,
                  separatorBuilder: (_, _) =>
                      SizedBox(height: serene.spacing.md),
                  itemBuilder: (context, index) => _ScheduleCard(
                    schedule: schedules[index],
                    onCancelAlerts: () => unawaited(
                      _cancelScheduleAlerts(
                        context,
                        ref,
                        schedules[index],
                        l10n,
                      ),
                    ),
                    onDelete: () => unawaited(
                      _deleteSchedule(context, ref, schedules[index], l10n),
                    ),
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(serene.spacing.lg),
                child: Text(l10n.errorUnexpected),
              ),
            ),
          ),

          // ── Add schedule button ───────────────────────────────────────────
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              serene.spacing.lg,
              serene.spacing.xl,
              serene.spacing.lg,
              serene.spacing.xxxxl + MediaQuery.paddingOf(context).bottom,
            ),
            sliver: SliverToBoxAdapter(
              child: OutlinedButton.icon(
                onPressed: () => context.push(
                  AppRoutes.schedulerDaily,
                  extra: medication.id,
                ),
                icon: const Icon(Icons.add),
                label: Text(l10n.addScheduleButton),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: serene.radius.md,
                  ),
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
    AppLocalizations l10n,
  ) async {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorUnexpected)),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.recurringAlertsCancelledMessage)),
    );
  }

  Future<void> _deleteSchedule(
    BuildContext context,
    WidgetRef ref,
    Schedule schedule,
    AppLocalizations l10n,
  ) async {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorUnexpected)),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.scheduleDeletedMessage)),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
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
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _timesLabel(schedule),
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
