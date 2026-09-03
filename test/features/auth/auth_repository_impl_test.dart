import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_pills/core/network/api_client.dart';
import 'package:my_pills/core/network/http_error_body.dart';
import 'package:my_pills/core/storage/token_storage.dart';

import 'package:my_pills/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:my_pills/features/auth/domain/entities/auth_user.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockDio extends Mock implements Dio {}

class MockTokenStorage extends Mock implements TokenStorage {}

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

String _jwt(Map<String, Object?> payload) {
  String b64(String input) =>
      base64Url.encode(utf8.encode(input)).replaceAll('=', '');
  return '${b64('{"alg":"none"}')}.${b64(jsonEncode(payload))}.sig';
}

TokenStorage _memoryTokenStorage() {
  final store = <String, String>{};
  final mock = MockFlutterSecureStorage();
  when(() => mock.read(key: any(named: 'key'))).thenAnswer((invocation) async {
    final key = invocation.namedArguments[#key] as String;
    return store[key];
  });
  when(
    () => mock.write(
      key: any(named: 'key'),
      value: any(named: 'value'),
    ),
  ).thenAnswer((invocation) async {
    final key = invocation.namedArguments[#key] as String;
    final value = invocation.namedArguments[#value] as String;
    store[key] = value;
  });
  when(() => mock.delete(key: any(named: 'key'))).thenAnswer((
    invocation,
  ) async {
    final key = invocation.namedArguments[#key] as String;
    store.remove(key);
  });
  return TokenStorage(secureStorage: mock);
}

void main() {
  late MockApiClient mockApiClient;
  late MockDio mockDio;
  late MockTokenStorage mockTokenStorage;
  late AuthRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(Options());
  });

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
    when(
      () => mockTokenStorage.saveAuthProfile(
        displayName: any(named: 'displayName'),
        photoUrl: any(named: 'photoUrl'),
      ),
    ).thenAnswer((_) async {});
    when(() => mockTokenStorage.getDisplayName()).thenAnswer((_) async => null);
    when(() => mockTokenStorage.getPhotoUrl()).thenAnswer((_) async => null);
    when(
      () => mockTokenStorage.getRefreshToken(),
    ).thenAnswer((_) async => 'ref_456');

    repository = AuthRepositoryImpl(
      apiClient: mockApiClient,
      tokenStorage: mockTokenStorage,
    );
  });

  void stubGoogleLoginAndMe({Map<String, dynamic>? me}) {
    when(
      () => mockDio.post<Map<String, dynamic>>(
        '/auth/google',
        data: any(named: 'data'),
        options: any(named: 'options'),
      ),
    ).thenAnswer(
      (_) async => Response(
        statusCode: 200,
        requestOptions: RequestOptions(path: '/auth/google'),
        data: {
          'token': 'acc_123',
          'refreshToken': 'ref_456',
        },
      ),
    );
    when(() => mockDio.get<Map<String, dynamic>>('/me')).thenAnswer(
      (_) async => Response(
        statusCode: 200,
        requestOptions: RequestOptions(path: '/me'),
        data:
            me ??
            {
              'id': 'usr_1',
              'email': 'user@example.com',
            },
      ),
    );
  }

  group('AuthRepositoryImpl', () {
    test(
      'loginWithGoogle returns success and saves tokens on 200 OK',
      () async {
        stubGoogleLoginAndMe(
          me: {
            'id': 'usr_1',
            'email': 'user@example.com',
            'name': 'Test User',
          },
        );

        final result = await repository.loginWithGoogle(
          'valid-user@example.com',
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
      },
    );

    test(
      'loginWithGoogle keeps Google photo when /me omits photoUrl',
      () async {
        stubGoogleLoginAndMe();

        final result = await repository.loginWithGoogle(
          'valid-user@example.com',
          displayName: 'Daniel',
          photoUrl: 'https://lh3.googleusercontent.com/a/photo',
        );

        expect(result.isSuccess, isTrue);
        expect(result.valueOrNull!.name, 'Daniel');
        expect(
          result.valueOrNull!.photoUrl,
          'https://lh3.googleusercontent.com/a/photo',
        );
        verify(
          () => mockTokenStorage.saveAuthProfile(
            displayName: 'Daniel',
            photoUrl: 'https://lh3.googleusercontent.com/a/photo',
          ),
        ).called(1);
      },
    );

    test(
      'loginWithGoogle fills name and photo from ID token when args omitted',
      () async {
        stubGoogleLoginAndMe();
        final token = _jwt({
          'email': 'user@example.com',
          'name': 'Daniel Delcid',
          'picture': 'https://lh3.googleusercontent.com/a/jwt-photo',
        });

        final result = await repository.loginWithGoogle(token);

        expect(result.isSuccess, isTrue);
        expect(result.valueOrNull!.name, 'Daniel Delcid');
        expect(
          result.valueOrNull!.photoUrl,
          'https://lh3.googleusercontent.com/a/jwt-photo',
        );
      },
    );

    test(
      'login claims persist, restore on getCurrentUser, and clear on logout',
      () async {
        final storage = _memoryTokenStorage();
        final loggingIn = AuthRepositoryImpl(
          apiClient: mockApiClient,
          tokenStorage: storage,
        );
        stubGoogleLoginAndMe();
        when(
          () => mockDio.post<dynamic>(
            '/auth/logout',
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            statusCode: 200,
            requestOptions: RequestOptions(path: '/auth/logout'),
          ),
        );

        final login = await loggingIn.loginWithGoogle(
          'valid-user@example.com',
          displayName: 'Daniel',
          photoUrl: 'https://lh3.googleusercontent.com/a/photo',
        );

        expect(login.isSuccess, isTrue);
        expect(login.valueOrNull!.name, 'Daniel');
        expect(
          login.valueOrNull!.photoUrl,
          'https://lh3.googleusercontent.com/a/photo',
        );
        expect(await storage.getDisplayName(), 'Daniel');
        expect(
          await storage.getPhotoUrl(),
          'https://lh3.googleusercontent.com/a/photo',
        );

        final restoredRepo = AuthRepositoryImpl(
          apiClient: mockApiClient,
          tokenStorage: storage,
        );
        final restored = await restoredRepo.getCurrentUser();

        expect(restored.isSuccess, isTrue);
        expect(restored.valueOrNull!.name, 'Daniel');
        expect(
          restored.valueOrNull!.photoUrl,
          'https://lh3.googleusercontent.com/a/photo',
        );

        final logout = await restoredRepo.logout();
        expect(logout.isSuccess, isTrue);
        expect(await storage.getDisplayName(), isNull);
        expect(await storage.getPhotoUrl(), isNull);

        final afterLogout = await restoredRepo.getCurrentUser();
        expect(afterLogout.isSuccess, isTrue);
        expect(afterLogout.valueOrNull!.name, 'user');
        expect(afterLogout.valueOrNull!.photoUrl, isNull);
      },
    );

    test('logout sends refreshToken and clears token storage', () async {
      when(
        () => mockDio.post<dynamic>(
          '/auth/logout',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          statusCode: 204,
          requestOptions: RequestOptions(path: '/auth/logout'),
        ),
      );

      final result = await repository.logout();

      expect(result.isSuccess, isTrue);
      verify(
        () => mockDio.post<dynamic>(
          '/auth/logout',
          data: {'refreshToken': 'ref_456'},
          options: any(named: 'options'),
        ),
      ).called(1);
      verify(() => mockTokenStorage.clearTokens()).called(1);
    });

    test('logout still succeeds when remote logout returns 404', () async {
      when(
        () => mockDio.post<dynamic>(
          '/auth/logout',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => throw DioException(
          requestOptions: RequestOptions(
            path: '/auth/logout',
            extra: {kHttpBestEffortExtra: true},
          ),
          response: Response(
            requestOptions: RequestOptions(path: '/auth/logout'),
            statusCode: 404,
            data: '<html><title>No route found</title></html>',
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      final result = await repository.logout();

      expect(result.isSuccess, isTrue);
      verify(() => mockTokenStorage.clearTokens()).called(1);
    });
  });
}
