import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_pills/core/storage/token_storage.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage mockSecureStorage;
  late TokenStorage tokenStorage;

  setUp(() {
    mockSecureStorage = MockFlutterSecureStorage();
    tokenStorage = TokenStorage(secureStorage: mockSecureStorage);
    when(
      () => mockSecureStorage.read(key: any(named: 'key')),
    ).thenAnswer((_) async => null);
  });

  group('TokenStorage', () {
    test('saveTokens stores access and refresh tokens securely', () async {
      when(
        () => mockSecureStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      await tokenStorage.saveTokens(
        accessToken: 'access_123',
        refreshToken: 'refresh_456',
      );

      verify(
        () => mockSecureStorage.write(
          key: 'mypills_access_token',
          value: 'access_123',
        ),
      ).called(1);
      verify(
        () => mockSecureStorage.write(
          key: 'mypills_refresh_token',
          value: 'refresh_456',
        ),
      ).called(1);
      expect(await tokenStorage.getAccessToken(), equals('access_123'));
    });

    test(
      'clearTokens removes access and refresh tokens from storage',
      () async {
        when(
          () => mockSecureStorage.delete(key: any(named: 'key')),
        ).thenAnswer((_) async {});

        await tokenStorage.clearTokens();

        verify(
          () => mockSecureStorage.delete(key: 'mypills_access_token'),
        ).called(1);
        verify(
          () => mockSecureStorage.delete(key: 'mypills_refresh_token'),
        ).called(1);
        expect(await tokenStorage.getAccessToken(), isNull);
      },
    );
  });
}
