import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_pills/app/providers.dart';
import 'package:my_pills/features/calendar_integration/domain/calendar_connection.dart';
import 'package:my_pills/features/calendar_integration/domain/google_calendar_consent.dart';
import 'package:my_pills/features/calendar_integration/domain/google_calendar_link.dart';
import 'package:my_pills/l10n/app_localizations.dart';

/// Localized name of a connected calendar vendor.
String calendarProviderLabel(
  AppLocalizations l10n,
  CalendarProvider provider,
) {
  return switch (provider) {
    CalendarProvider.google => l10n.settingsCloudCalendarGoogle,
    CalendarProvider.microsoft => l10n.settingsCloudCalendarMicrosoft,
  };
}

/// Null when there is nothing to tell the user (linked, or they cancelled).
String? googleCalendarLinkMessage(
  AppLocalizations l10n,
  GoogleCalendarLinkOutcome outcome,
) {
  return switch (outcome) {
    GoogleCalendarLinked() => null,
    GoogleCalendarLinkNeedsProfile() => l10n.settingsCloudCalendarNoProfile,
    GoogleCalendarLinkDeclined(:final reason) => switch (reason) {
      CalendarServerAuthCodeReason.cancelled => null,
      CalendarServerAuthCodeReason.denied =>
        l10n.settingsCloudCalendarScopeDenied,
      CalendarServerAuthCodeReason.missing =>
        l10n.settingsCloudCalendarAuthMissing,
      CalendarServerAuthCodeReason.mismatchedAccount =>
        l10n.settingsCloudCalendarMismatchedAccount,
      CalendarServerAuthCodeReason.failed =>
        l10n.settingsCloudCalendarLinkFailed,
    },
    GoogleCalendarLinkFailed(:final message) =>
      message ?? l10n.settingsCloudCalendarConnectFailed,
  };
}

/// Links Google Calendar for [profileId] and refreshes the connection list
/// only when the backend accepted the code.
Future<GoogleCalendarLinkOutcome> linkGoogleCalendarForProfile({
  required WidgetRef ref,
  required String profileId,
  String? expectedEmail,
}) async {
  final outcome = await ref.read(linkGoogleCalendarProvider)(
    profileId: profileId,
    expectedEmail: expectedEmail,
  );
  if (outcome is GoogleCalendarLinked && ref.context.mounted) {
    ref.invalidate(calendarConnectionsProvider(profileId));
  }
  return outcome;
}
