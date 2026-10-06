import 'package:google_sign_in/google_sign_in.dart';
import 'package:my_pills/core/config/env_config.dart';
import 'package:my_pills/core/errors/failure.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/features/calendar_integration/data/services/pkce_calendar_service.dart';
import 'package:my_pills/features/calendar_integration/domain/google_calendar_consent.dart';
import 'package:my_pills/features/calendar_integration/domain/google_calendar_link.dart';

/// Adapts the shared [GoogleSignIn] instance to the consent port.
GoogleCalendarConsent googleCalendarConsent(GoogleSignIn googleSignIn) {
  return GoogleCalendarConsent(
    calendarGranted: () => googleSignIn.canAccessScopes(
      const [EnvConfig.googleCalendarScope],
    ),
    serverAuthCode: () => googleSignIn.currentUser?.serverAuthCode,
    email: () => googleSignIn.currentUser?.email,
    disconnect: () async {
      await googleSignIn.disconnect();
    },
    signIn: () async => (await googleSignIn.signIn()) != null,
  );
}

/// Mints a Calendar code and exchanges it. Does not touch auth state.
///
/// A local `'default'` id is not a server profile. Sending it would create
/// a patient with a placeholder birth date.
Future<GoogleCalendarLinkOutcome> linkGoogleCalendar({
  required GoogleCalendarConsent consent,
  required PkceCalendarService calendars,
  required String profileId,
  String? expectedEmail,
}) async {
  if (profileId.isEmpty || profileId == 'default') {
    return const GoogleCalendarLinkNeedsProfile();
  }

  final codeResult = await resolveCalendarServerAuthCode(
    consent,
    expectedEmail: expectedEmail,
  );
  switch (codeResult) {
    case CalendarServerAuthCodeUnavailable(:final reason):
      return GoogleCalendarLinkDeclined(reason);
    case CalendarServerAuthCodeReady(:final code):
      final result = await calendars.connectWithServerAuthCode(
        profileId: profileId,
        code: code,
      );
      return switch (result) {
        Success() => const GoogleCalendarLinked(),
        FailureResult(:final failure) => GoogleCalendarLinkFailed(
          failure is ServerFailure ? failure.message : null,
        ),
      };
  }
}
