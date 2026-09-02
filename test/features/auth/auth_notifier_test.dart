import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_pills/app/providers.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/core/storage/token_storage.dart';
import 'package:my_pills/core/sync/sync_engine.dart';
import 'package:my_pills/features/auth/domain/entities/auth_user.dart';
import 'package:my_pills/features/auth/domain/repositories/auth_repository.dart';
import 'package:my_pills/features/auth/presentation/providers/auth_providers.dart';
import 'package:my_pills/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:my_pills/features/profile/presentation/providers/profile_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockSyncEngine extends Mock implements SyncEngine {}

class MockUserProfileRepository extends Mock implements UserProfileRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthRepository mockAuthRepo;
  late MockSyncEngine mockSyncEngine;
  late MockUserProfileRepository mockProfileRepo;
  late TokenStorage tokenStorage;
  late SharedPreferences prefs;

  const authUser = AuthUser(
    id: 'usr-123',
    email: 'test@example.com',
    name: 'Daniel',
    photoUrl: 'https://lh3.googleusercontent.com/a/photo',
  );

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    mockAuthRepo = MockAuthRepository();
    mockSyncEngine = MockSyncEngine();
    mockProfileRepo = MockUserProfileRepository();
    tokenStorage = TokenStorage();

    when(
      () => mockAuthRepo.loginWithGoogle(any()),
    ).thenAnswer((_) async => const Result.success(authUser));
    when(
      () => mockSyncEngine.flushOutbox(),
    ).thenAnswer((_) async => const Result.success(null));
    when(
      () => mockSyncEngine.syncProfile(any()),
    ).thenAnswer((_) async => const Result.success(null));
    when(
      () => mockSyncEngine.fetchAndRestoreProfiles(),
    ).thenAnswer((_) async => const Result.success(null));
    when(() => mockProfileRepo.getProfile()).thenReturn(null);
    when(() => mockProfileRepo.getProfiles()).thenReturn(const []);
  });

  ProviderContainer createContainer({bool autoDispose = true}) {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        tokenStorageProvider.overrideWithValue(tokenStorage),
        authRepositoryProvider.overrideWithValue(mockAuthRepo),
        syncEngineProvider.overrideWithValue(mockSyncEngine),
        userProfileRepositoryProvider.overrideWithValue(mockProfileRepo),
      ],
    );
    if (autoDispose) {
      addTearDown(container.dispose);
    }
    return container;
  }

  group('AuthNotifier Tests', () {
    test('initial build returns null when no token in storage', () async {
      final container = createContainer();
      final user = await container.read(authProvider.future);
      expect(user, isNull);
    });

    test('loginWithGoogle updates state on success', () async {
      final container = createContainer();
      final result = await container
          .read(authProvider.notifier)
          .loginWithGoogle('valid-token');

      expect(result.isSuccess, isTrue);
      expect(container.read(authProvider).value, equals(authUser));
    });

    test(
      'loginWithGoogle seeds empty profile name and photo prefs',
      () async {
        final container = createContainer();
        await container
            .read(authProvider.notifier)
            .loginWithGoogle(
              'valid-token',
            );

        expect(prefs.getString('profile.name'), 'Daniel');
        expect(
          prefs.getString('profile.photo_path'),
          'https://lh3.googleusercontent.com/a/photo',
        );
      },
    );

    test(
      'loginWithGoogle replaces placeholder Usuario profile name',
      () async {
        await prefs.setString('profile.name', 'Usuario');
        final container = createContainer();
        await container
            .read(authProvider.notifier)
            .loginWithGoogle(
              'valid-token',
            );

        expect(prefs.getString('profile.name'), 'Daniel');
      },
    );

    test(
      'loginWithGoogle does not overwrite an existing profile name',
      () async {
        await prefs.setString('profile.name', 'Existing');
        await prefs.setString('profile.photo_path', '/local/avatar.png');
        final container = createContainer();
        await container
            .read(authProvider.notifier)
            .loginWithGoogle(
              'valid-token',
            );

        expect(prefs.getString('profile.name'), 'Existing');
        expect(prefs.getString('profile.photo_path'), '/local/avatar.png');
      },
    );

    test(
      'disposing during post-login sync does not throw',
      () async {
        final flush = Completer<Result<void>>();
        when(
          () => mockSyncEngine.flushOutbox(),
        ).thenAnswer((_) => flush.future);

        final container = createContainer(autoDispose: false);
        await container
            .read(authProvider.notifier)
            .loginWithGoogle(
              'valid-token',
            );
        container.dispose();
        flush.complete(const Result.success(null));
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(const Duration(milliseconds: 20));
      },
    );

    test('logout resets auth state to null', () async {
      when(
        () => mockAuthRepo.logout(),
      ).thenAnswer((_) async => const Result.success(null));

      final container = createContainer();
      await container.read(authProvider.notifier).logout();

      expect(container.read(authProvider).value, isNull);
      verify(() => mockAuthRepo.logout()).called(1);
    });
  });
}
