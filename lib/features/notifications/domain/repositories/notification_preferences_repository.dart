import 'package:my_pills/features/notifications/domain/entities/notification_preferences.dart';

/// Repository to manage notification preferences.
abstract class NotificationPreferencesRepository {
  /// Loads the current preferences.
  NotificationPreferences load();

  /// Saves the given preferences.
  Future<void> save(NotificationPreferences prefs);
}
