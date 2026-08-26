/// Single source of truth for personal customization.
///
/// To release as a generic public app: set [userName] to null and
/// [showPersonalMessage] to false — the greeting screen will show only the
/// time-of-day salutation and the daily quote, with no personal content.
abstract final class PersonalConfig {
  static const bool showPersonalMessage = false;
  static const List<String> personalMessageLines = <String>[];
}
