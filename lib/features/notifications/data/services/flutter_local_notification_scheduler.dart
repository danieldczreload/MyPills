import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:my_pills/core/utils/log.dart';
import 'package:my_pills/features/notifications/data/services/notification_init.dart';
import 'package:my_pills/features/notifications/domain/services/notification_scheduler.dart';
import 'package:my_pills/features/tracker/domain/entities/dose_event.dart';
import 'package:timezone/timezone.dart' as tz;

class FlutterLocalNotificationScheduler implements NotificationScheduler {
  FlutterLocalNotificationScheduler(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  /// Last detail string set by [scheduleTestIn] — exposed so the diagnostic
  /// UI can show exactly what was scheduled (tz, when, mode) without
  /// requiring the user to read console logs.
  static String? lastTestDetail;

  static int _beforeId(int doseId) => doseId * 2;
  static int _exactId(int doseId) => doseId * 2 + 1;

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
        kMedicationChannelId,
        kMedicationChannelName,
        channelDescription: kMedicationChannelDescription,
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
      );

  static const NotificationDetails _details = NotificationDetails(
    android: _androidDetails,
  );

  /// Use `alarmClock` when exact alarms are allowed — it maps to
  /// `AlarmManager.setAlarmClock()`, the same path the system Clock app uses.
  /// On Pixel/Android 14+ this is the only mode that fires reliably in
  /// background; `setExactAndAllowWhileIdle` is silently throttled in some
  /// idle states even with `USE_EXACT_ALARM` granted.
  AndroidScheduleMode get _scheduleMode => exactAlarmsAllowed
      ? AndroidScheduleMode.alarmClock
      : AndroidScheduleMode.inexactAllowWhileIdle;

  @override
  Future<void> scheduleForDoseEvents(
    List<DoseEvent> doseEvents, {
    required int minutesBefore,
    required String Function(DoseEvent) titleBuilder,
    required String Function(DoseEvent) bodyBuilder,
  }) async {
    final now = DateTime.now();
    final mode = _scheduleMode;
    mlog(
      'mypills.notif',
      'scheduleForDoseEvents count=${doseEvents.length} '
          'minutesBefore=$minutesBefore mode=$mode tz=${tz.local.name}',
    );

    var scheduled = 0;
    var skipped = 0;
    var failed = 0;

    for (final dose in doseEvents) {
      if (dose.status != DoseStatus.pending) {
        skipped++;
        continue;
      }

      final exactTime = dose.scheduledAt;
      final beforeTime = exactTime.subtract(Duration(minutes: minutesBefore));
      final title = titleBuilder(dose);
      final body = bodyBuilder(dose);

      if (minutesBefore > 0 && beforeTime.isAfter(now)) {
        final ok = await _scheduleOne(
          id: _beforeId(dose.id),
          when: beforeTime,
          title: title,
          body: body,
          mode: mode,
        );
        ok ? scheduled++ : failed++;
      }

      if (exactTime.isAfter(now)) {
        final ok = await _scheduleOne(
          id: _exactId(dose.id),
          when: exactTime,
          title: title,
          body: body,
          mode: mode,
        );
        ok ? scheduled++ : failed++;
      } else {
        skipped++;
      }
    }

    mlog(
      'mypills.notif',
      'scheduleForDoseEvents done scheduled=$scheduled '
          'skipped=$skipped failed=$failed',
    );
  }

  Future<bool> _scheduleOne({
    required int id,
    required DateTime when,
    required String title,
    required String body,
    required AndroidScheduleMode mode,
  }) async {
    try {
      // Build the TZDateTime via UTC so a misconfigured tz.local (e.g. when
      // FlutterTimezone fails and tz.local stays UTC) doesn't shift the
      // absolute moment. Dart's DateTime knows the device timezone, so
      // when.toUtc() gives the correct absolute UTC instant.
      final tzWhen = tz.TZDateTime.from(when.toUtc(), tz.UTC);
      mlog(
        'mypills.notif',
        '  zonedSchedule id=$id when=$when tzWhen=$tzWhen mode=$mode',
      );
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzWhen,
        _details,
        androidScheduleMode: mode,
      );
      return true;
    } catch (e, st) {
      mlogError(
        'mypills.notif',
        'zonedSchedule id=$id failed',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  @override
  Future<void> cancelForDoseEvent(int doseEventId) async {
    await _plugin.cancel(_beforeId(doseEventId));
    await _plugin.cancel(_exactId(doseEventId));
  }

  /// Reserved id range used by diagnostic helpers ([scheduleTestIn] uses
  /// 999999). [cancelAll] preserves these so that pressing "Probar push en
  /// 1 min" then locking the screen — which fires [didChangeAppLifecycleState]
  /// → syncNotifications → cancelAll on resume — doesn't silently kill the
  /// test alarm before it fires.
  static const int _diagIdMin = 999000;
  static const int _diagIdMax = 999999;

  @override
  Future<void> cancelAll() async {
    try {
      final pending = await _plugin.pendingNotificationRequests();
      for (final p in pending) {
        if (p.id >= _diagIdMin && p.id <= _diagIdMax) continue;
        await _plugin.cancel(p.id);
      }
    } catch (e, st) {
      if (e is! Error) {
        mlogError(
          'mypills.notif',
          'cancelAll fallback to plugin.cancelAll',
          error: e,
          stackTrace: st,
        );
      }
      try {
        await _plugin.cancelAll();
      } catch (_) {}
    }
  }

  @override
  Future<int> pendingCount() async {
    try {
      final pending = await _plugin.pendingNotificationRequests();
      return pending.length;
    } catch (e) {
      mlog('mypills.notif', 'pendingCount failed: $e');
      return -1;
    }
  }

  /// Diagnostics: returns the actual list of pending notifications so the
  /// settings screen can prove (or disprove) that scheduling persisted.
  Future<List<({int id, String? title, String? body})>>
  pendingNotifications() async {
    try {
      final pending = await _plugin.pendingNotificationRequests();
      return pending
          .map((p) => (id: p.id, title: p.title, body: p.body))
          .toList(growable: false);
    } catch (e) {
      mlog('mypills.notif', 'pendingNotifications failed: $e');
      return const [];
    }
  }

  @override
  Future<void> showTest({required String title, required String body}) async {
    mlog('mypills.notif', 'showTest title="$title"');
    await _plugin.show(0, title, body, _details);
  }

  @override
  Future<void> scheduleTestIn({
    required Duration delay,
    required String title,
    required String body,
  }) async {
    final when = DateTime.now().add(delay);
    final mode = _scheduleMode;
    // Build via UTC so the absolute moment is correct even if tz.local is misconfigured.
    final tzWhen = tz.TZDateTime.from(when.toUtc(), tz.UTC);
    final detail =
        'when=$when\ntzWhen=$tzWhen\ntz.local=${tz.local.name}\nmode=$mode';
    mlog('mypills.notif', 'scheduleTestIn $detail');
    try {
      await _plugin.zonedSchedule(
        999999,
        title,
        body,
        tzWhen,
        _details,
        androidScheduleMode: mode,
      );
      lastTestDetail = '$detail\nresult=scheduled OK';
    } catch (e, st) {
      lastTestDetail = '$detail\nresult=ERROR $e';
      mlogError(
        'mypills.notif',
        'scheduleTestIn FAILED',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }
}
