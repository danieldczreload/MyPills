import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_pills/core/network/api_client.dart';
import 'package:my_pills/features/calendar_integration/data/services/pkce_calendar_service.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockDio extends Mock implements Dio {}

void main() {
  late MockApiClient mockApiClient;
  late MockDio mockDio;
  late PkceCalendarService service;

  setUp(() {
    mockApiClient = MockApiClient();
    mockDio = MockDio();
    when(() => mockApiClient.dio).thenReturn(mockDio);
    service = PkceCalendarService(mockApiClient);
  });

  group('PKCE generation', () {
    test('generateCodeVerifier produces valid non-empty string', () {
      final verifier = service.generateCodeVerifier();
      expect(verifier, isNotEmpty);
      expect(verifier.length, greaterThanOrEqualTo(43));
    });

    test('generateCodeChallenge produces valid non-empty challenge', () {
      final verifier = service.generateCodeVerifier();
      final challenge = service.generateCodeChallenge(verifier);
      expect(challenge, isNotEmpty);
      expect(challenge, isNot(equals(verifier)));
    });
  });

  group('PkceCalendarService API calls', () {
    test('initiateAuthorization returns PkceAuthorizeResult on 200', () async {
      when(
        () => mockDio.post<Map<String, dynamic>>(
          '/calendars/google/authorize',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/calendars/google/authorize'),
          statusCode: 200,
          data: {
            'state': 'state_123',
            'authorizationUrl': 'https://accounts.google.com/o/oauth2/v2/auth',
          },
        ),
      );

      final result = await service.initiateAuthorization(
        profileId: 'prof_1',
        provider: 'google',
      );

      expect(result.isSuccess, isTrue);
      final value = result.valueOrNull!;
      expect(value.state, 'state_123');
      expect(value.authorizationUrl, contains('accounts.google.com'));
      expect(value.codeVerifier, isNotEmpty);
    });

    test('connectCalendar returns connected status on 200', () async {
      when(
        () => mockDio.post<Map<String, dynamic>>(
          '/calendars/google/connect',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/calendars/google/connect'),
          statusCode: 200,
          data: {'connected': true},
        ),
      );

      final result = await service.connectCalendar(
        profileId: 'prof_1',
        provider: 'google',
        code: 'code_abc',
        state: 'state_123',
        codeVerifier: 'verifier_xyz',
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isTrue);
    });

    test('syncCalendar returns success on 200', () async {
      when(
        () => mockDio.post<Map<String, dynamic>>(
          '/calendars/sync',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/calendars/sync'),
          statusCode: 200,
          data: <String, dynamic>{},
        ),
      );

      final result = await service.syncCalendar(profileId: 'prof_1');
      expect(result.isSuccess, isTrue);
    });

    test('getConnections returns list of provider maps on 200', () async {
      when(
        () => mockDio.get<dynamic>(
          '/calendars',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/calendars'),
          statusCode: 200,
          data: [
            {'provider': 'google', 'connected': true, 'status': 'active'},
          ],
        ),
      );

      final result = await service.getConnections(profileId: 'prof_1');
      expect(result.isSuccess, isTrue);
      final list = result.valueOrNull!;
      expect(list.length, 1);
      expect(list.first['provider'], 'google');
    });

    test('disconnectCalendar returns success on 204', () async {
      when(
        () => mockDio.delete<void>(
          '/calendars/google',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/calendars/google'),
          statusCode: 204,
        ),
      );

      final result = await service.disconnectCalendar(
        profileId: 'prof_1',
        provider: 'google',
      );
      expect(result.isSuccess, isTrue);
    });
  });
}
