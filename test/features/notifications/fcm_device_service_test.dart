import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_pills/core/network/api_client.dart';
import 'package:my_pills/features/notifications/data/services/fcm_device_service.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockDio extends Mock implements Dio {}

void main() {
  late MockApiClient mockApiClient;
  late MockDio mockDio;
  late FcmDeviceService service;

  setUp(() {
    mockApiClient = MockApiClient();
    mockDio = MockDio();
    when(() => mockApiClient.dio).thenReturn(mockDio);
    service = FcmDeviceService(mockApiClient);
  });

  group('FcmDeviceService', () {
    test('registerDevice returns success when API responds with 201', () async {
      when(
        () => mockDio.post<Map<String, dynamic>>(
          '/devices',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/devices'),
          statusCode: 201,
          data: {'success': true},
        ),
      );

      final result = await service.registerDevice(
        fcmToken: 'test-fcm-token',
        locale: 'es',
      );

      expect(result.isSuccess, isTrue);
    });

    test(
      'deregisterDevice returns success when API responds with 204',
      () async {
        when(
          () => mockDio.delete<void>('/devices/token-123'),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/devices/token-123'),
            statusCode: 204,
          ),
        );

        final result = await service.deregisterDevice('token-123');

        expect(result.isSuccess, isTrue);
      },
    );

    test('registerDevice returns Failure on DioException', () async {
      when(
        () => mockDio.post<Map<String, dynamic>>(
          '/devices',
          data: any(named: 'data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/devices'),
          type: DioExceptionType.connectionError,
        ),
      );

      final result = await service.registerDevice(fcmToken: 'test-token');

      expect(result.isFailure, isTrue);
    });
  });
}
