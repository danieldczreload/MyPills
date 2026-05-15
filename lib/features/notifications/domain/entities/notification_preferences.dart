import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_preferences.freezed.dart';
part 'notification_preferences.g.dart';

/// User preferences for notifications.
@freezed
abstract class NotificationPreferences with _$NotificationPreferences {
  const factory NotificationPreferences({
    @Default(true) bool inAppBannersEnabled,
    @Default(true) bool pushNotificationsEnabled,
    @Default(true) bool calendarSyncEnabled,
    @Default(0) int reminderMinutesBefore, // 0 = exact time
    String? defaultCalendarId, // Added for Phase 2
  }) = _NotificationPreferences;

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) =>
      _$NotificationPreferencesFromJson(json);
}
