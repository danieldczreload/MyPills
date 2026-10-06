import 'package:flutter_test/flutter_test.dart';
import 'package:my_pills/features/calendar_integration/domain/calendar_connection.dart';

void main() {
  group('CalendarConnection', () {
    test('active status is the only healthy link', () {
      final connection = CalendarConnection.tryFromJson({
        'provider': 'google',
        'status': 'active',
        'connected': true,
      });

      expect(connection?.isActive, isTrue);
      expect(connection?.needsReauth, isFalse);
    });

    test('reauth_required is not healthy even if connected', () {
      final connection = CalendarConnection.tryFromJson({
        'provider': 'google',
        'status': 'reauth_required',
        'connected': true,
      });

      expect(connection?.isActive, isFalse);
      expect(connection?.needsReauth, isTrue);
    });

    test('connected without a known status is not active', () {
      final connection = CalendarConnection.tryFromJson({
        'provider': 'google',
        'connected': true,
      });

      expect(connection?.status, CalendarLinkStatus.unknown);
      expect(connection?.isActive, isFalse);
    });

    test('outlook is the microsoft provider', () {
      final connection = CalendarConnection.tryFromJson({
        'provider': 'outlook',
        'status': 'active',
      });

      expect(connection?.provider, CalendarProvider.microsoft);
      expect(connection?.provider.wire, 'microsoft');
    });

    test('an unknown provider is dropped', () {
      expect(
        CalendarConnection.tryFromJson({
          'provider': 'caldav',
          'status': 'active',
        }),
        isNull,
      );
    });
  });
}
