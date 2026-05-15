import 'package:my_pills/features/tracker/domain/entities/dose_event.dart';

class CalendarSyncReport {
  const CalendarSyncReport({
    required this.created,
    required this.skipped,
    required this.failed,
    required this.permissionDenied,
    required this.calendarMissing,
    this.errors = const [],
  });

  final int created;
  final int skipped;
  final int failed;
  final bool permissionDenied;
  final bool calendarMissing;
  final List<String> errors;

  bool get isHealthy => !permissionDenied && !calendarMissing && failed == 0;
}

abstract interface class CalendarSyncService {
  /// Synchronizes the provided list of [DoseEvent]s to the specified calendar.
  /// Returns a [CalendarSyncReport] so callers can react to permission /
  /// calendar-not-found failures instead of silently swallowing them.
  Future<CalendarSyncReport> syncDoseEventsToCalendar(
    List<DoseEvent> events, {
    required String calendarId,
    required int reminderMinutesBefore,
    required String Function(DoseEvent dose) titleBuilder,
    required String Function(DoseEvent dose) notesBuilder,
  });

  /// Removes all events synced by this app from the specified calendar.
  Future<void> removeAllCalendarEvents(String calendarId);

  /// Cancels a specific dose event from the calendar.
  Future<void> cancelForDoseEvent(
    int doseEventId, {
    required String calendarId,
  });
}
