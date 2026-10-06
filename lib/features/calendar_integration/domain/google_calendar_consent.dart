import 'package:my_pills/core/utils/log.dart';

/// Why a Calendar server auth code could not be minted.
enum CalendarServerAuthCodeReason {
  /// The refreshed sign-in did not include the Calendar scope.
  denied,

  /// Sign-in succeeded, but Google did not return a code.
  missing,

  /// The user dismissed the Google account dialog.
  cancelled,

  /// The refreshed sign-in was a different Google account than expected.
  mismatchedAccount,

  /// The plugin failed. This is not a denied consent.
  failed,
}

/// A server auth code that is safe to exchange for Calendar, or why not.
sealed class CalendarServerAuthCodeResult {
  const CalendarServerAuthCodeResult();
}

/// [code] was minted while the Calendar scope was already granted.
class CalendarServerAuthCodeReady extends CalendarServerAuthCodeResult {
  const CalendarServerAuthCodeReady(this.code);

  final String code;
}

/// Do not exchange whatever code the last sign-in happened to hold.
class CalendarServerAuthCodeUnavailable extends CalendarServerAuthCodeResult {
  const CalendarServerAuthCodeUnavailable(this.reason);

  final CalendarServerAuthCodeReason reason;
}

/// Google Sign-In operations used to mint a Calendar server auth code.
///
/// Callbacks keep the decision testable without the plugin. The shared
/// Google Sign-In instance already requests the Calendar scope, so one fresh
/// sign-in is enough. Incremental `requestScopes` does not refresh
/// `serverAuthCode` and is not used.
class GoogleCalendarConsent {
  const GoogleCalendarConsent({
    required this.calendarGranted,
    required this.serverAuthCode,
    required this.email,
    required this.disconnect,
    required this.signIn,
  });

  final Future<bool> Function() calendarGranted;
  final String? Function() serverAuthCode;
  final String? Function() email;
  final Future<void> Function() disconnect;
  final Future<bool> Function() signIn;
}

/// Returns a code that includes Calendar, or why not to send one.
///
/// A code from an email-only grant must not be exchanged: the backend would
/// store a refresh token that Google later rejects with
/// `ACCESS_TOKEN_SCOPE_INSUFFICIENT`. When the current grant lacks Calendar,
/// or belongs to another account, the old grant is dropped and sign-in runs
/// once. `signOut` plus a silent sign-in reuses the old token and is not
/// enough.
///
/// Never throws. Callers decide how to tell the user.
Future<CalendarServerAuthCodeResult> resolveCalendarServerAuthCode(
  GoogleCalendarConsent consent, {
  String? expectedEmail,
}) async {
  try {
    if (await consent.calendarGranted() &&
        _sameGoogleAccount(consent.email(), expectedEmail)) {
      final current = _readyOrMissing(consent);
      if (current is CalendarServerAuthCodeReady) return current;
    }

    await consent.disconnect();
    if (!await consent.signIn()) {
      return const CalendarServerAuthCodeUnavailable(
        CalendarServerAuthCodeReason.cancelled,
      );
    }
    if (!_sameGoogleAccount(consent.email(), expectedEmail)) {
      return const CalendarServerAuthCodeUnavailable(
        CalendarServerAuthCodeReason.mismatchedAccount,
      );
    }
    if (!await consent.calendarGranted()) {
      return const CalendarServerAuthCodeUnavailable(
        CalendarServerAuthCodeReason.denied,
      );
    }
    return _readyOrMissing(consent);
  } on Exception catch (e) {
    mlog('mypills.calendar', 'Google Calendar code unavailable: $e');
    return const CalendarServerAuthCodeUnavailable(
      CalendarServerAuthCodeReason.failed,
    );
  }
}

CalendarServerAuthCodeResult _readyOrMissing(GoogleCalendarConsent consent) {
  final code = consent.serverAuthCode()?.trim();
  if (code == null || code.isEmpty) {
    return const CalendarServerAuthCodeUnavailable(
      CalendarServerAuthCodeReason.missing,
    );
  }
  return CalendarServerAuthCodeReady(code);
}

/// [expected] null or blank skips the check. A blank [actual] is not a match.
bool _sameGoogleAccount(String? actual, String? expected) {
  final expectedEmail = expected?.trim().toLowerCase();
  if (expectedEmail == null || expectedEmail.isEmpty) return true;
  final actualEmail = actual?.trim().toLowerCase();
  if (actualEmail == null || actualEmail.isEmpty) return false;
  return actualEmail == expectedEmail;
}
