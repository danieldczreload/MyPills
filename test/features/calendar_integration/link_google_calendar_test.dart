import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_pills/core/errors/failure.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/features/calendar_integration/data/link_google_calendar.dart';
import 'package:my_pills/features/calendar_integration/data/services/pkce_calendar_service.dart';
import 'package:my_pills/features/calendar_integration/domain/google_calendar_consent.dart';
import 'package:my_pills/features/calendar_integration/domain/google_calendar_link.dart';

class MockPkceCalendarService extends Mock implements PkceCalendarService {}

void main() {
  late MockPkceCalendarService calendars;

  setUp(() {
    calendars = MockPkceCalendarService();
  });

  GoogleCalendarConsent granted(String code) {
    return GoogleCalendarConsent(
      calendarGranted: () async => true,
      serverAuthCode: () => code,
      email: () => 'patient@example.com',
      disconnect: () async {},
      signIn: () async => true,
    );
  }

  test('does not open Google when the profile id is still local', () async {
    var signedIn = false;
    final outcome = await linkGoogleCalendar(
      consent: GoogleCalendarConsent(
        calendarGranted: () async => true,
        serverAuthCode: () => 'code',
        email: () => 'patient@example.com',
        disconnect: () async {},
        signIn: () async {
          signedIn = true;
          return true;
        },
      ),
      calendars: calendars,
      profileId: 'default',
    );

    expect(outcome, isA<GoogleCalendarLinkNeedsProfile>());
    expect(signedIn, isFalse);
    verifyNever(
      () => calendars.connectWithServerAuthCode(
        profileId: any(named: 'profileId'),
        code: any(named: 'code'),
      ),
    );
  });

  test('exchanges a code that already includes Calendar', () async {
    when(
      () => calendars.connectWithServerAuthCode(
        profileId: 'prof-1',
        code: 'server-auth-code',
      ),
    ).thenAnswer((_) async => const Result.success(true));

    final outcome = await linkGoogleCalendar(
      consent: granted('server-auth-code'),
      calendars: calendars,
      profileId: 'prof-1',
      expectedEmail: 'patient@example.com',
    );

    expect(outcome, isA<GoogleCalendarLinked>());
  });

  test('a declined consent does not call the backend', () async {
    final outcome = await linkGoogleCalendar(
      consent: GoogleCalendarConsent(
        calendarGranted: () async => false,
        serverAuthCode: () => 'stale',
        email: () => 'patient@example.com',
        disconnect: () async {},
        signIn: () async => false,
      ),
      calendars: calendars,
      profileId: 'prof-1',
    );

    expect(outcome, isA<GoogleCalendarLinkDeclined>());
    expect(
      (outcome as GoogleCalendarLinkDeclined).reason,
      CalendarServerAuthCodeReason.cancelled,
    );
    verifyNever(
      () => calendars.connectWithServerAuthCode(
        profileId: any(named: 'profileId'),
        code: any(named: 'code'),
      ),
    );
  });

  test('a failed exchange keeps the server message', () async {
    when(
      () => calendars.connectWithServerAuthCode(
        profileId: 'prof-1',
        code: 'server-auth-code',
      ),
    ).thenAnswer(
      (_) async => const Result.failure(
        Failure.server(statusCode: 400, message: 'bad code'),
      ),
    );

    final outcome = await linkGoogleCalendar(
      consent: granted('server-auth-code'),
      calendars: calendars,
      profileId: 'prof-1',
    );

    expect(outcome, isA<GoogleCalendarLinkFailed>());
    expect((outcome as GoogleCalendarLinkFailed).message, 'bad code');
  });
}
