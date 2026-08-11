import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_pills/core/network/api_client.dart';
import 'package:my_pills/core/storage/token_storage.dart';

import 'package:my_pills/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:my_pills/features/auth/domain/entities/auth_user.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockDio extends Mock implements Dio {}

class MockTokenStorage extends Mock implements TokenStorage {}

void main() {
  late MockApiClient mockApiClient;
  late MockDio mockDio;
  late MockTokenStorage mockTokenStorage;
  late AuthRepositoryImpl repository;

  setUp(() {
    mockApiClient = MockApiClient();
    mockDio = MockDio();
    mockTokenStorage = MockTokenStorage();

    when(() => mockApiClient.dio).thenReturn(mockDio);
    when(
      () => mockTokenStorage.saveTokens(
        accessToken: any(named: 'accessToken'),
        refreshToken: any(named: 'refreshToken'),
      ),
    ).thenAnswer((_) async {});
    when(() => mockTokenStorage.clearTokens()).thenAnswer((_) async {});

    repository = AuthRepositoryImpl(
      apiClient: mockApiClient,
      tokenStorage: mockTokenStorage,
    );
  });

  group('AuthRepositoryImpl', () {
    test('login returns success and saves tokens on 200 OK', () async {
      when(
        () => mockDio.post<Map<String, dynamic>>(
          '/auth/login',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          statusCode: 200,
          requestOptions: RequestOptions(path: '/auth/login'),
          data: {
            'accessToken': 'acc_123',
            'refreshToken': 'ref_456',
            'user': {
              'id': 'usr_1',
              'email': 'user@example.com',
              'name': 'Test User',
            },
          },
        ),
      );

      final result = await repository.login(
        email: 'user@example.com',
        password: 'password123',
      );

      expect(result.isSuccess, isTrue);
      expect(
        result.valueOrNull,
        equals(
          const AuthUser(
            id: 'usr_1',
            email: 'user@example.com',
            name: 'Test User',
          ),
        ),
      );
      verify(
        () => mockTokenStorage.saveTokens(
          accessToken: 'acc_123',
          refreshToken: 'ref_456',
        ),
      ).called(1);
    });

    test('logout clears token storage', () async {
      when(() => mockDio.post<dynamic>('/auth/logout')).thenAnswer(
        (_) async => Response(
          statusCode: 200,
          requestOptions: RequestOptions(path: '/auth/logout'),
        ),
      );

      final result = await repository.logout();

      expect(result.isSuccess, isTrue);
      verify(() => mockTokenStorage.clearTokens()).called(1);
    });
  });
}
