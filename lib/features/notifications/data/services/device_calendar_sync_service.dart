import 'dart:developer' as developer;
import 'dart:convert';
import 'package:my_pills/core/utils/log.dart';

import 'package:device_calendar/device_calendar.dart';
import 'package:my_pills/features/notifications/domain/services/calendar_sync_service.dart';
import 'package:my_pills/features/tracker/domain/entities/dose_event.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

class DeviceCalendarSyncService implements CalendarSyncService {
  DeviceCalendarSyncService(this._calendarPlugin, this._prefs);

  final DeviceCalendarPlugin _calendarPlugin;
  final SharedPreferences _prefs;

  String _getMapKey(String calendarId) => 'calendar_event_mapping_$calendarId';

  Map<String, String> _getMapping(String calendarId) {
    final str = _prefs.getString(_getMapKey(calendarId));
    if (str == null) return {};
    try {
      return Map<String, String>.from(jsonDecode(str) as Map);
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveMapping(
    String calendarId,
    Map<String, String> mapping,
  ) async {
    await _prefs.setString(_getMapKey(calendarId), jsonEncode(mapping));
  }

  Future<bool> _ensurePermissions() async {
    final has = await _calendarPlugin.hasPermissions();
    if (has.isSuccess && (has.data ?? false)) return true;
    final req = await _calendarPlugin.requestPermissions();
    return req.isSuccess && (req.data ?? false);
  }

  Future<bool> _calendarExists(String calendarId) async {
    final res = await _calendarPlugin.retrieveCalendars();
    if (!res.isSuccess || res.data == null) return false;
    return res.data!.any((c) => c.id == calendarId);
  }

  @override
  Future<CalendarSyncReport> syncDoseEventsToCalendar(
    List<DoseEvent> events, {
    required String calendarId,
    required int reminderMinutesBefore,
    required String Function(DoseEvent dose) titleBuilder,
    required String Function(DoseEvent dose) notesBuilder,
  }) async {
    developer.log(
      'syncDoseEventsToCalendar count=${events.length} calendarId=$calendarId',
      name: 'mypills.cal',
    );

    if (!await _ensurePermissions()) {
      mlog('mypills.cal', 'aborted: permission denied');
      return const CalendarSyncReport(
        created: 0,
        skipped: 0,
        failed: 0,
        permissionDenied: true,
        calendarMissing: false,
      );
    }

    if (!await _calendarExists(calendarId)) {
      developer.log(
        'aborted: calendar $calendarId not found — clearing mapping',
        name: 'mypills.cal',
      );
      await _prefs.remove(_getMapKey(calendarId));
      return const CalendarSyncReport(
        created: 0,
        skipped: 0,
        failed: 0,
        permissionDenied: false,
        calendarMissing: true,
      );
    }

    final mapping = _getMapping(calendarId);
    final errors = <String>[];
    var created = 0;
    var skipped = 0;
    var failed = 0;

    // Prune orphans: any mapping entry whose dose is no longer in `events`
    // (deleted schedule/medication). The reconciliation window is the same
    // 14-day horizon used by SyncNotifications, so any DB-resident dose is
    // present here; missing means the dose was deleted.
    final liveDoseIds = events.map((e) => e.id.toString()).toSet();
    final orphans = mapping.keys
        .where((k) => !liveDoseIds.contains(k))
        .toList();
    for (final orphanDoseId in orphans) {
      final eventId = mapping[orphanDoseId]!;
      try {
        await _calendarPlugin.deleteEvent(calendarId, eventId);
      } catch (e) {
        developer.log(
          'orphan deleteEvent $eventId failed: $e',
          name: 'mypills.cal',
        );
      }
      mapping.remove(orphanDoseId);
    }
    if (orphans.isNotEmpty) {
      developer.log('pruned ${orphans.length} orphan event(s)', name: 'mypills.cal');
    }

    for (final dose in events) {
      if (dose.status == DoseStatus.taken || dose.status == DoseStatus.missed) {
        await cancelForDoseEvent(
          dose.id,
          calendarId: calendarId,
          mapping: mapping,
        );
        skipped++;
        continue;
      }

      // Use UTC for absolute moment — robust against a misconfigured tz.local.
      final startTz = tz.TZDateTime.from(dose.scheduledAt.toUtc(), tz.UTC);
      final endTz = startTz.add(const Duration(minutes: 15));

      final event = Event(calendarId, title: titleBuilder(dose))
        ..description = notesBuilder(dose)
        ..start = startTz
        ..end = endTz
        ..reminders = [Reminder(minutes: reminderMinutesBefore)];

      final existingEventId = mapping[dose.id.toString()];
      if (existingEventId != null) {
        event.eventId = existingEventId;
      }

      try {
        final result = await _calendarPlugin.createOrUpdateEvent(event);
        if (result?.isSuccess == true && result?.data != null) {
          mapping[dose.id.toString()] = result!.data!;
          created++;
        } else {
          final msg =
              result?.errors.map((e) => e.errorMessage).join(', ') ??
              'null result';
          errors.add('dose ${dose.id}: $msg');
          failed++;
          developer.log(
            'createOrUpdateEvent dose=${dose.id} failed: $msg',
            name: 'mypills.cal',
          );
        }
      } catch (e, st) {
        errors.add('dose ${dose.id}: $e');
        failed++;
        developer.log(
          'createOrUpdateEvent dose=${dose.id} threw: $e',
          name: 'mypills.cal',
          error: e,
          stackTrace: st,
        );
      }
    }

    await _saveMapping(calendarId, mapping);
    developer.log(
      'sync done created=$created skipped=$skipped failed=$failed',
      name: 'mypills.cal',
    );
    return CalendarSyncReport(
      created: created,
      skipped: skipped,
      failed: failed,
      permissionDenied: false,
      calendarMissing: false,
      errors: errors,
    );
  }

  @override
  Future<void> removeAllCalendarEvents(String calendarId) async {
    final mapping = _getMapping(calendarId);
    for (final eventId in mapping.values) {
      try {
        await _calendarPlugin.deleteEvent(calendarId, eventId);
      } catch (e) {
        developer.log(
          'deleteEvent $eventId failed: $e',
          name: 'mypills.cal',
        );
      }
    }
    await _prefs.remove(_getMapKey(calendarId));
  }

  @override
  Future<void> cancelForDoseEvent(
    int doseEventId, {
    required String calendarId,
    Map<String, String>? mapping,
  }) async {
    final map = mapping ?? _getMapping(calendarId);
    final eventId = map[doseEventId.toString()];
    if (eventId != null) {
      try {
        await _calendarPlugin.deleteEvent(calendarId, eventId);
      } catch (e) {
        developer.log(
          'deleteEvent $eventId failed: $e',
          name: 'mypills.cal',
        );
      }
      map.remove(doseEventId.toString());
      if (mapping == null) {
        await _saveMapping(calendarId, map);
      }
    }
  }
}
