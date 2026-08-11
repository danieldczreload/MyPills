import 'dart:developer' as developer;
import 'package:my_pills/core/utils/log.dart';

import 'package:my_pills/core/utils/clock.dart';
import 'package:my_pills/features/medications/domain/entities/medication.dart';
import 'package:my_pills/features/medications/domain/repositories/medication_repository.dart';
import 'package:my_pills/features/notifications/domain/entities/notification_preferences.dart';
import 'package:my_pills/features/notifications/domain/repositories/notification_preferences_repository.dart';
import 'package:my_pills/features/notifications/domain/services/calendar_sync_service.dart';
import 'package:my_pills/features/notifications/domain/services/notification_scheduler.dart';
import 'package:my_pills/features/tracker/domain/repositories/dose_event_repository.dart';

/// Snapshot of the most recent [SyncNotifications] run. Surfaced in the
/// diagnostic UI so the user can tell exactly why notifications did or did
/// not fire — every silent return path in the previous version is now
/// captured here.
class SyncReport {
  SyncReport();

  DateTime? ranAt;
  NotificationPreferences? prefs;
  int dosesFound = 0;
  int pushScheduled = 0;
  bool pushSkipped = false;
  CalendarSyncReport? calendar;
  bool calendarSkipped = false;
  String? calendarSkipReason;
  String? error;

  String get oneLine {
    final ts = ranAt?.toIso8601String() ?? 'never';
    final pp = prefs == null
        ? 'prefs=?'
        : 'push=${prefs!.pushNotificationsEnabled} '
              'cal=${prefs!.calendarSyncEnabled} '
              'min=${prefs!.reminderMinutesBefore}';
    final calStr = calendar == null
        ? (calendarSkipped ? 'cal:skip(${calendarSkipReason ?? "?"})' : 'cal:-')
        : 'cal:created=${calendar!.created} failed=${calendar!.failed} '
              '${calendar!.permissionDenied ? "noperm " : ""}'
              '${calendar!.calendarMissing ? "missing " : ""}';
    final err = error == null ? '' : ' ERROR=$error';
    return '$ts | $pp | doses=$dosesFound push=$pushScheduled '
        '${pushSkipped ? "(skipped) " : ""}| $calStr$err';
  }
}

class SyncNotifications {
  SyncNotifications({
    required NotificationScheduler scheduler,
    required CalendarSyncService calendarSyncService,
    required NotificationPreferencesRepository prefsRepo,
    required DoseEventRepository doseRepo,
    required MedicationRepository medRepo,
    required Clock clock,
  }) : _scheduler = scheduler,
       _calendarSyncService = calendarSyncService,
       _prefsRepo = prefsRepo,
       _doseRepo = doseRepo,
       _medRepo = medRepo,
       _clock = clock;

  final NotificationScheduler _scheduler;
  final CalendarSyncService _calendarSyncService;
  final NotificationPreferencesRepository _prefsRepo;
  final DoseEventRepository _doseRepo;
  final MedicationRepository _medRepo;
  final Clock _clock;

  Future<void> _currentSync = Future.value();

  /// The result of the most recent sync run. `null` until [call] has run at
  /// least once.
  SyncReport? lastReport;

  Future<void> call() {
    _currentSync = _currentSync.then((_) => _doSync()).catchError((
      Object e,
      StackTrace st,
    ) {
      developer.log(
        'sync chain error: $e',
        name: 'mypills.sync',
        error: e,
        stackTrace: st,
      );
    });
    return _currentSync;
  }

  Future<void> _doSync() async {
    final report = SyncReport()..ranAt = _clock();
    lastReport = report;
    try {
      final prefs = _prefsRepo.load();
      report.prefs = prefs;
      developer.log(
        'sync start prefs push=${prefs.pushNotificationsEnabled} '
        'cal=${prefs.calendarSyncEnabled} '
        'minBefore=${prefs.reminderMinutesBefore} '
        'calId=${prefs.defaultCalendarId}',
        name: 'mypills.sync',
      );

      // Always wipe first so removed schedules disappear from the OS queue.
      await _scheduler.cancelAll();

      if (!prefs.pushNotificationsEnabled && !prefs.calendarSyncEnabled) {
        mlog('mypills.sync', 'both disabled — nothing to do');
        report.pushSkipped = true;
        report.calendarSkipped = true;
        report.calendarSkipReason = 'disabled';
        return;
      }

      final now = _clock();
      final end = now.add(const Duration(days: 14));

      final dosesResult = await _doseRepo.getForDateRange(now, end);
      final doses = dosesResult.valueOrNull;
      if (doses == null) {
        report.error = 'doseRepo.getForDateRange returned null/failure';
        mlog('mypills.sync', report.error!);
        return;
      }
      report.dosesFound = doses.length;
      mlog('mypills.sync', 'found ${doses.length} doses in window');

      final medsResult = await _medRepo.getAll();
      final meds = medsResult.valueOrNull;
      if (meds == null) {
        report.error = 'medRepo.getAll returned null/failure';
        mlog('mypills.sync', report.error!);
        return;
      }
      final medsMap = {for (final m in meds) m.id: m};

      // Push and calendar are isolated: a failure in one must not block the
      // other. Each step records its outcome on the report.
      if (prefs.pushNotificationsEnabled) {
        try {
          await _scheduler.scheduleForDoseEvents(
            doses,
            minutesBefore: prefs.reminderMinutesBefore,
            titleBuilder: (_) => 'Hora de tu medicación',
            bodyBuilder: (dose) {
              final med = medsMap[dose.medicationId] ?? _fallbackMed;
              return 'Es hora de tomar ${med.name}';
            },
          );
          report.pushScheduled = await _scheduler.pendingCount();
        } catch (e, st) {
          report.error =
              '${report.error == null ? '' : '${report.error!} | '}push: $e';
          developer.log(
            'push scheduling threw: $e',
            name: 'mypills.sync',
            error: e,
            stackTrace: st,
          );
        }
      } else {
        report.pushSkipped = true;
      }

      if (prefs.calendarSyncEnabled && prefs.defaultCalendarId != null) {
        try {
          report.calendar = await _calendarSyncService.syncDoseEventsToCalendar(
            doses,
            calendarId: prefs.defaultCalendarId!,
            reminderMinutesBefore: prefs.reminderMinutesBefore,
            titleBuilder: (dose) {
              final med = medsMap[dose.medicationId] ?? _fallbackMed;
              return 'Tomar ${med.name}';
            },
            notesBuilder: (_) =>
                'Recordatorio automático generado por MyPills.',
          );
        } catch (e, st) {
          report.error =
              '${report.error == null ? '' : '${report.error!} | '}cal: $e';
          developer.log(
            'calendar sync threw: $e',
            name: 'mypills.sync',
            error: e,
            stackTrace: st,
          );
        }
      } else {
        report.calendarSkipped = true;
        report.calendarSkipReason = !prefs.calendarSyncEnabled
            ? 'disabled'
            : 'no calendar selected';
      }

      mlog('mypills.sync', report.oneLine);
    } catch (e, st) {
      report.error = '$e';
      developer.log(
        'sync top-level threw: $e',
        name: 'mypills.sync',
        error: e,
        stackTrace: st,
      );
    }
  }

  static const Medication _fallbackMed = Medication(
    id: 0,
    name: 'Medicación',
    form: MedicationForm.pill,
    category: '',
    colorToken: '',
  );
}
