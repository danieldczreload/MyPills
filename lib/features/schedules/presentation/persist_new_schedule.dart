import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_pills/app/providers.dart';
import 'package:my_pills/app/router.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/core/widgets/app_notification.dart';
import 'package:my_pills/features/medications/presentation/providers/medications_providers.dart';
import 'package:my_pills/features/notifications/presentation/providers/notification_providers.dart';
import 'package:my_pills/features/schedules/domain/entities/dose.dart';
import 'package:my_pills/features/schedules/domain/entities/schedule.dart';
import 'package:my_pills/features/schedules/presentation/dose_input_controller.dart';
import 'package:my_pills/features/schedules/presentation/schedule_failure_message.dart';
import 'package:my_pills/l10n/app_localizations.dart';

/// Reads the dose form and toasts a warning when it is invalid.
Dose? readScheduleDose(BuildContext context, DoseInputController input) {
  final result = input.read();
  if (result case FailureResult(:final failure)) {
    AppNotification.showWarning(
      context,
      scheduleFailureMessage(AppLocalizations.of(context), failure),
    );
    return null;
  }
  return result.valueOrNull;
}

/// Creates [schedule] for [profileId], then toasts and navigates to Today.
Future<void> persistNewSchedule({
  required WidgetRef ref,
  required BuildContext context,
  required Schedule schedule,
  required String profileId,
}) async {
  final l10n = AppLocalizations.of(context);
  final result = await ref
      .read(createScheduleUseCaseProvider(profileId))
      .call(schedule);

  if (!context.mounted) return;
  if (result case FailureResult(:final failure)) {
    AppNotification.showError(
      context,
      scheduleFailureMessage(l10n, failure),
    );
    return;
  }

  final connections =
      ref.read(calendarConnectionsProvider(profileId)).value ?? [];
  final hasConnectedCalendar = connections.any(
    (c) => c['connected'] == true || c['status'] == 'active',
  );

  if (schedule.notifyPush) {
    final meds = ref.read(medicationsStreamProvider).value?.valueOrNull ?? [];
    final medName =
        meds.where((m) => m.id == schedule.medicationId).firstOrNull?.name ??
        l10n.medicationFallbackName;
    unawaited(
      ref
          .read(notificationSchedulerProvider)
          .showTest(
            title: l10n.reminderScheduledTitle,
            body: l10n.reminderScheduledBody(medName),
          ),
    );
  }

  var calendarSyncFailed = false;
  if (schedule.notifyCalendar && hasConnectedCalendar) {
    await ref.read(syncEngineProvider).flushOutbox();
    if (!context.mounted) return;
    final syncResult = await ref
        .read(pkceCalendarServiceProvider)
        .syncCalendar(profileId: profileId);
    calendarSyncFailed = syncResult.isFailure;
  }

  if (!context.mounted) return;

  if (schedule.notifyCalendar && !hasConnectedCalendar) {
    AppNotification.showWarning(
      context,
      l10n.scheduleSavedConnectCalendar,
      actionLabel: l10n.scheduleSavedConnectAction,
      onAction: () => context.push(AppRoutes.settings),
    );
  } else if (calendarSyncFailed) {
    AppNotification.showWarning(
      context,
      l10n.scheduleSavedCalendarSyncFailed,
    );
  } else {
    AppNotification.showSuccess(
      context,
      schedule.notifyCalendar
          ? l10n.scheduleSavedCalendarSync
          : l10n.scheduleSaved,
    );
  }

  context.go(AppRoutes.today);
}
