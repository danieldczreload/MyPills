import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_pills/core/network/api_client.dart';
import 'package:my_pills/features/notifications/data/services/remote_notification_preferences_service.dart';
import 'package:my_pills/features/notifications/domain/entities/notification_preferences.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockDio extends Mock implements Dio {}

void main() {
  late MockApiClient mockApiClient;
  late MockDio mockDio;
  late RemoteNotificationPreferencesService service;

  setUp(() {
    mockApiClient = MockApiClient();
    mockDio = MockDio();
    when(() => mockApiClient.dio).thenReturn(mockDio);
    service = RemoteNotificationPreferencesService(mockApiClient);
  });

  group('RemoteNotificationPreferencesService', () {
    test('getPreferences returns mapped entity on 200 response', () async {
      when(
        () => mockDio.get<Map<String, dynamic>>('/notifications/preferences'),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/notifications/preferences'),
          statusCode: 200,
          data: {
            'doseRemindersEnabled': true,
            'inAppBannersEnabled': false,
            'reminderMinutesBefore': 10,
          },
        ),
      );

      final result = await service.getPreferences();

      expect(result.isSuccess, isTrue);
      final prefs = result.valueOrNull!;
      expect(prefs.pushNotificationsEnabled, isTrue);
      expect(prefs.inAppBannersEnabled, isFalse);
      expect(prefs.reminderMinutesBefore, equals(10));
    });

    test(
      'updatePreferences sends correct payload and returns success',
      () async {
        when(
          () => mockDio.patch<Map<String, dynamic>>(
            '/notifications/preferences',
            data: any(named: 'data'),
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/notifications/preferences'),
            statusCode: 200,
            data: {'doseRemindersEnabled': true},
          ),
        );

        const prefs = NotificationPreferences(
          reminderMinutesBefore: 15,
        );

        final result = await service.updatePreferences(prefs);

        expect(result.isSuccess, isTrue);
        verify(
          () => mockDio.patch<Map<String, dynamic>>(
            '/notifications/preferences',
            data: {
              'doseRemindersEnabled': true,
              'inAppBannersEnabled': true,
              'reminderMinutesBefore': 15,
            },
          ),
        ).called(1);
      },
    );

    test('updatePreferences returns failure on network error', () async {
      when(
        () => mockDio.patch<Map<String, dynamic>>(
          '/notifications/preferences',
          data: any(named: 'data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/notifications/preferences'),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      const prefs = NotificationPreferences();
      final result = await service.updatePreferences(prefs);

      expect(result.isFailure, isTrue);
    });
  });
}
