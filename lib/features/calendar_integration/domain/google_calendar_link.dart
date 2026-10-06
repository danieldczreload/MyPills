import 'package:my_pills/features/calendar_integration/domain/google_calendar_consent.dart';

/// What happened when the app tried to attach Google Calendar to a profile.
sealed class GoogleCalendarLinkOutcome {
  const GoogleCalendarLinkOutcome();
}

/// The backend accepted the server auth code.
class GoogleCalendarLinked extends GoogleCalendarLinkOutcome {
  const GoogleCalendarLinked();
}

/// No profile to attach. The Google dialog was not opened.
class GoogleCalendarLinkNeedsProfile extends GoogleCalendarLinkOutcome {
  const GoogleCalendarLinkNeedsProfile();
}

/// Consent did not produce a code. Login and settings stay as they were.
class GoogleCalendarLinkDeclined extends GoogleCalendarLinkOutcome {
  const GoogleCalendarLinkDeclined(this.reason);

  final CalendarServerAuthCodeReason reason;
}

/// The code was minted, but `POST /calendars/google/connect` failed.
class GoogleCalendarLinkFailed extends GoogleCalendarLinkOutcome {
  const GoogleCalendarLinkFailed(this.message);

  final String? message;
}

/// Exchanges a Calendar server auth code for the active profile.
///
/// Wired in `app/providers.dart`. Presentation does not see Google Sign-In.
typedef LinkGoogleCalendar =
    Future<GoogleCalendarLinkOutcome> Function({
      required String profileId,
      String? expectedEmail,
    });
