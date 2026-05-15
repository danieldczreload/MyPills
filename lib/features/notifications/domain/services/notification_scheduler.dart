import 'package:my_pills/features/tracker/domain/entities/dose_event.dart';

/// Service to schedule and cancel push notifications.
abstract class NotificationScheduler {
  /// Schedules notifications for each future pending [DoseEvent].
  ///
  /// When [minutesBefore] > 0, two notifications are scheduled per dose:
  /// one anticipated and one at the exact dose time. When 0, only the
  /// exact-time notification is scheduled.
  Future<void> scheduleForDoseEvents(
    List<DoseEvent> doseEvents, {
    required int minutesBefore,
    required String Function(DoseEvent) titleBuilder,
    required String Function(DoseEvent) bodyBuilder,
  });

  /// Cancels notifications associated with [doseEventId].
  Future<void> cancelForDoseEvent(int doseEventId);

  /// Cancels all pending notifications.
  Future<void> cancelAll();

  /// Diagnostics: count of pending notifications currently registered with
  /// the OS. Returns -1 if the platform doesn't support introspection.
  Future<int> pendingCount();

  /// Diagnostics: list of pending notifications (id, title, body).
  Future<List<({int id, String? title, String? body})>> pendingNotifications();

  /// Diagnostics: show an immediate notification used by the settings screen
  /// to verify channel + permissions end-to-end. Throws on failure so the UI
  /// can surface the error.
  Future<void> showTest({required String title, required String body});

  /// Diagnostics: schedule a notification [delay] from now using the same
  /// `zonedSchedule` path as real doses. Lets us isolate scheduler/timezone
  /// bugs from the sync use case. Throws on failure.
  Future<void> scheduleTestIn({
    required Duration delay,
    required String title,
    required String body,
  });
}
