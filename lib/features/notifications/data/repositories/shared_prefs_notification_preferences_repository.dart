import 'dart:convert';

import 'package:my_pills/features/notifications/domain/entities/notification_preferences.dart';
import 'package:my_pills/features/notifications/domain/repositories/notification_preferences_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Implementation of [NotificationPreferencesRepository] using [SharedPreferences].
class SharedPrefsNotificationPreferencesRepository
    implements NotificationPreferencesRepository {
  SharedPrefsNotificationPreferencesRepository(this._prefs);

  final SharedPreferences _prefs;
  static const String _prefsKey = 'my_pills.notification_preferences';

  @override
  NotificationPreferences load() {
    final jsonStr = _prefs.getString(_prefsKey);
    if (jsonStr != null) {
      try {
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;
        return NotificationPreferences.fromJson(json);
      } catch (e) {
        // If parsing fails (e.g. migration issue), return defaults
      }
    }
    return const NotificationPreferences();
  }

  @override
  Future<void> save(NotificationPreferences prefs) async {
    final jsonStr = jsonEncode(prefs.toJson());
    await _prefs.setString(_prefsKey, jsonStr);
  }
}
