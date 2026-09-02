import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_pills/core/storage/token_storage.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void _bindMemoryStore(
  MockFlutterSecureStorage mock,
  Map<String, String> store,
) {
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
}

void main() {
  late MockFlutterSecureStorage mockSecureStorage;
  late Map<String, String> store;
  late TokenStorage tokenStorage;

  setUp(() {
    mockSecureStorage = MockFlutterSecureStorage();
    store = <String, String>{};
    _bindMemoryStore(mockSecureStorage, store);
    tokenStorage = TokenStorage(secureStorage: mockSecureStorage);
  });

  group('TokenStorage', () {
    test('saveTokens stores access and refresh tokens securely', () async {
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

    test('saveAuthProfile persists display name and photo url', () async {
      await tokenStorage.saveAuthProfile(
        displayName: 'Daniel',
        photoUrl: 'https://lh3.googleusercontent.com/a/photo',
      );

      expect(await tokenStorage.getDisplayName(), 'Daniel');
      expect(
        await tokenStorage.getPhotoUrl(),
        'https://lh3.googleusercontent.com/a/photo',
      );
      expect(store['mypills_auth_display_name'], 'Daniel');
      expect(
        store['mypills_auth_photo_url'],
        'https://lh3.googleusercontent.com/a/photo',
      );
    });

    test('saveAuthProfile deletes empty display claims', () async {
      store['mypills_auth_display_name'] = 'Daniel';
      store['mypills_auth_photo_url'] = 'https://example.com/a.png';

      await tokenStorage.saveAuthProfile();

      expect(await tokenStorage.getDisplayName(), isNull);
      expect(await tokenStorage.getPhotoUrl(), isNull);
      expect(store.containsKey('mypills_auth_display_name'), isFalse);
      expect(store.containsKey('mypills_auth_photo_url'), isFalse);
    });

    test(
      'clearTokens removes access, refresh, and display claims',
      () async {
        await tokenStorage.saveTokens(
          accessToken: 'access_123',
          refreshToken: 'refresh_456',
        );
        await tokenStorage.saveAuthProfile(
          displayName: 'Daniel',
          photoUrl: 'https://example.com/a.png',
        );

        await tokenStorage.clearTokens();

        expect(await tokenStorage.getAccessToken(), isNull);
        expect(await tokenStorage.getRefreshToken(), isNull);
        expect(await tokenStorage.getDisplayName(), isNull);
        expect(await tokenStorage.getPhotoUrl(), isNull);
        verify(
          () => mockSecureStorage.delete(key: 'mypills_access_token'),
        ).called(1);
        verify(
          () => mockSecureStorage.delete(key: 'mypills_refresh_token'),
        ).called(1);
        verify(
          () => mockSecureStorage.delete(key: 'mypills_auth_display_name'),
        ).called(1);
        verify(
          () => mockSecureStorage.delete(key: 'mypills_auth_photo_url'),
        ).called(1);
      },
    );
  });
}
