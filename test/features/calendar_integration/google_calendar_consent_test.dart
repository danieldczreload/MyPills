import 'package:flutter_test/flutter_test.dart';
import 'package:my_pills/features/calendar_integration/domain/google_calendar_consent.dart';

void main() {
  group('resolveCalendarServerAuthCode', () {
    test('uses the current code when Calendar is already granted', () async {
      var disconnected = false;
      final result = await resolveCalendarServerAuthCode(
        _consent(
          granted: () => true,
          code: () => 'already-granted',
          disconnect: () async => disconnected = true,
        ),
      );

      expect(result, isA<CalendarServerAuthCodeReady>());
      expect(
        (result as CalendarServerAuthCodeReady).code,
        'already-granted',
      );
      expect(disconnected, isFalse);
    });

    test(
      'drops an email-only grant and uses the code from one new sign-in',
      () async {
        var granted = false;
        var code = 'stale-email-only';
        var signIns = 0;
        final result = await resolveCalendarServerAuthCode(
          _consent(
            granted: () => granted,
            code: () => code,
            signIn: () async {
              signIns++;
              granted = true;
              code = 'fresh-with-calendar';
              return true;
            },
          ),
        );

        expect(
          (result as CalendarServerAuthCodeReady).code,
          'fresh-with-calendar',
        );
        expect(signIns, 1);
      },
    );

    test('one refused sign-in is denied and does not retry', () async {
      var signIns = 0;
      final result = await resolveCalendarServerAuthCode(
        _consent(
          granted: () => false,
          code: () => 'stale-email-only',
          signIn: () async {
            signIns++;
            return true;
          },
        ),
      );

      expect(
        (result as CalendarServerAuthCodeUnavailable).reason,
        CalendarServerAuthCodeReason.denied,
      );
      expect(signIns, 1);
    });

    test('cancelled refresh does not fail the caller', () async {
      final result = await resolveCalendarServerAuthCode(
        _consent(
          granted: () => false,
          signIn: () async => false,
        ),
      );

      expect(
        (result as CalendarServerAuthCodeUnavailable).reason,
        CalendarServerAuthCodeReason.cancelled,
      );
    });

    test(
      'rejects a refreshed sign-in for a different Google account',
      () async {
        var email = 'patient@example.com';
        final result = await resolveCalendarServerAuthCode(
          _consent(
            granted: () => false,
            email: () => email,
            signIn: () async {
              email = 'other@example.com';
              return true;
            },
          ),
          expectedEmail: 'patient@example.com',
        );

        expect(
          (result as CalendarServerAuthCodeUnavailable).reason,
          CalendarServerAuthCodeReason.mismatchedAccount,
        );
      },
    );

    test('a blank current email is not the expected account', () async {
      final result = await resolveCalendarServerAuthCode(
        _consent(
          granted: () => true,
          email: () => '  ',
          code: () => 'stale',
          signIn: () async => true,
        ),
        expectedEmail: 'patient@example.com',
      );

      expect(
        (result as CalendarServerAuthCodeUnavailable).reason,
        CalendarServerAuthCodeReason.mismatchedAccount,
      );
    });

    test('a blank code after the fresh sign-in is missing', () async {
      final result = await resolveCalendarServerAuthCode(
        _consent(
          granted: () => true,
          code: () => '  ',
          signIn: () async => true,
        ),
      );

      expect(
        (result as CalendarServerAuthCodeUnavailable).reason,
        CalendarServerAuthCodeReason.missing,
      );
    });

    test('a plugin failure is not reported as denied consent', () async {
      final result = await resolveCalendarServerAuthCode(
        _consent(
          granted: () => throw Exception('plugin'),
        ),
      );

      expect(
        (result as CalendarServerAuthCodeUnavailable).reason,
        CalendarServerAuthCodeReason.failed,
      );
    });
  });
}

GoogleCalendarConsent _consent({
  required bool Function() granted,
  String? Function()? code,
  String? Function()? email,
  Future<void> Function()? disconnect,
  Future<bool> Function()? signIn,
}) {
  return GoogleCalendarConsent(
    calendarGranted: () async => granted(),
    serverAuthCode: code ?? () => 'code',
    email: email ?? () => 'patient@example.com',
    disconnect: disconnect ?? () async {},
    signIn: signIn ?? () async => true,
  );
}
