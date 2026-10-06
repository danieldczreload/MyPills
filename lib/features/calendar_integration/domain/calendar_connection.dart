/// Cloud calendar vendor as stored by `GET /calendars`.
enum CalendarProvider {
  google,
  microsoft;

  /// Wire value used in `/calendars/{provider}`.
  String get wire => switch (this) {
    CalendarProvider.google => 'google',
    CalendarProvider.microsoft => 'microsoft',
  };

  static CalendarProvider? tryParse(String? raw) {
    return switch (raw) {
      'google' => CalendarProvider.google,
      'microsoft' || 'outlook' => CalendarProvider.microsoft,
      _ => null,
    };
  }
}

/// Health of a backend calendar row.
///
/// Only [active] can sync. Anything else, including a missing or unexpected
/// status, is not a usable link.
enum CalendarLinkStatus {
  active,
  reauthRequired,
  unknown;

  static CalendarLinkStatus parse(String? raw) {
    return switch (raw) {
      'active' => CalendarLinkStatus.active,
      'reauth_required' => CalendarLinkStatus.reauthRequired,
      _ => CalendarLinkStatus.unknown,
    };
  }
}

/// One cloud calendar link from `GET /calendars`.
class CalendarConnection {
  const CalendarConnection({
    required this.provider,
    required this.status,
  });

  /// Null when [json] has no known provider. Those rows are dropped.
  static CalendarConnection? tryFromJson(Map<String, dynamic> json) {
    final provider = CalendarProvider.tryParse(json['provider'] as String?);
    if (provider == null) return null;
    return CalendarConnection(
      provider: provider,
      status: CalendarLinkStatus.parse(json['status'] as String?),
    );
  }

  final CalendarProvider provider;
  final CalendarLinkStatus status;

  /// Backend can sync this provider without a new OAuth grant.
  bool get isActive => status == CalendarLinkStatus.active;

  bool get needsReauth => status == CalendarLinkStatus.reauthRequired;
}
