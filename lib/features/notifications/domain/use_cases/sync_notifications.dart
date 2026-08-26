import 'dart:developer' as developer;
import 'package:my_pills/core/utils/clock.dart';
import 'package:my_pills/core/utils/log.dart';
import 'package:my_pills/features/medications/domain/entities/medication.dart';
import 'package:my_pills/features/medications/domain/repositories/medication_repository.dart';
import 'package:my_pills/features/notifications/domain/entities/notification_preferences.dart';
import 'package:my_pills/features/notifications/domain/repositories/notification_preferences_repository.dart';
import 'package:my_pills/features/notifications/domain/services/notification_scheduler.dart';
import 'package:my_pills/features/schedules/domain/entities/schedule.dart';
import 'package:my_pills/features/schedules/domain/repositories/schedule_repository.dart';
import 'package:my_pills/features/tracker/domain/repositories/dose_event_repository.dart';

/// Snapshot of the most recent [SyncNotifications] run.
class SyncReport {
  SyncReport();

  DateTime? ranAt;
  NotificationPreferences? prefs;
  int dosesFound = 0;
  int pushScheduled = 0;
  bool pushSkipped = false;
  String? error;

  String get oneLine {
    final ts = ranAt?.toIso8601String() ?? 'never';
    final pp = prefs == null
        ? 'prefs=?'
        : 'push=${prefs!.pushNotificationsEnabled} '
              'min=${prefs!.reminderMinutesBefore}';
    final err = error == null ? '' : ' ERROR=$error';
    return '$ts | $pp | doses=$dosesFound push=$pushScheduled '
        '${pushSkipped ? "(skipped) " : ""}$err';
  }
}

class SyncNotifications {
  SyncNotifications({
    required NotificationScheduler scheduler,
    required NotificationPreferencesRepository prefsRepo,
    required DoseEventRepository doseRepo,
    required MedicationRepository medRepo,
    required Clock clock,
    ScheduleRepository? scheduleRepo,
  }) : _scheduler = scheduler,
       _prefsRepo = prefsRepo,
       _doseRepo = doseRepo,
       _medRepo = medRepo,
       _clock = clock,
       _scheduleRepo = scheduleRepo;

  final NotificationScheduler _scheduler;
  final NotificationPreferencesRepository _prefsRepo;
  final DoseEventRepository _doseRepo;
  final MedicationRepository _medRepo;
  final Clock _clock;
  final ScheduleRepository? _scheduleRepo;

  Future<void> _currentSync = Future.value();

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

      // Always clear previous local OS scheduler queue to prevent duplicate / outdated alarms.
      await _scheduler.cancelAll();

      if (!prefs.pushNotificationsEnabled) {
        report.pushSkipped = true;
        return;
      }

      final now = _clock();
      final end = now.add(const Duration(days: 14));

      final futureDoses = _doseRepo.getForDateRange(now, end);
      final futureMeds = _medRepo.getAll();
      final dosesResult = await futureDoses;
      final doses = dosesResult.valueOrNull;
      if (doses == null) {
        report.error = 'doseRepo.getForDateRange returned null/failure';
        mlog('mypills.sync', report.error!);
        return;
      }
      report.dosesFound = doses.length;

      final medsResult = await futureMeds;
      final meds = medsResult.valueOrNull;
      if (meds == null) {
        report.error = 'medRepo.getAll returned null/failure';
        mlog('mypills.sync', report.error!);
        return;
      }

      var pushDoses = doses;
      if (_scheduleRepo != null) {
        try {
          final schedRes = await _scheduleRepo.getAll();
          final schedules = schedRes.valueOrNull;
          if (schedules != null) {
            final disabledSchedIds = <int>{};
            for (final s in schedules) {
              final notifyPush = switch (s) {
                DailySchedule(:final notifyPush) => notifyPush,
                DailyIntervalSchedule(:final notifyPush) => notifyPush,
                SpecificDaysSchedule(:final notifyPush) => notifyPush,
              };
              if (!notifyPush) {
                disabledSchedIds.add(s.id);
              }
            }
            if (disabledSchedIds.isNotEmpty) {
              pushDoses = doses
                  .where((d) => !disabledSchedIds.contains(d.scheduleId))
                  .toList();
            }
          }
        } catch (_) {}
      }

      final medMap = {for (final m in meds) m.id: m};
      await _scheduler.scheduleForDoseEvents(
        pushDoses,
        minutesBefore: prefs.reminderMinutesBefore,
        titleBuilder: (dose) {
          final med = medMap[dose.medicationId] ?? fallbackMed;
          return 'Recordatorio: ${med.name}';
        },
        bodyBuilder: (dose) {
          final med = medMap[dose.medicationId] ?? fallbackMed;
          return 'Es hora de tomar tu dosis de ${med.name}';
        },
      );
      report.pushScheduled = pushDoses.length;

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

  static const Medication fallbackMed = Medication(
    id: 0,
    name: 'Medicación',
    form: MedicationForm.pill,
    category: '',
    colorToken: '',
  );
}
