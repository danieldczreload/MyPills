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
import 'package:shared_preferences/shared_preferences.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockSyncEngine extends Mock implements SyncEngine {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthRepository mockAuthRepo;
  late MockSyncEngine mockSyncEngine;
  late TokenStorage tokenStorage;
  late SharedPreferences prefs;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    mockAuthRepo = MockAuthRepository();
    mockSyncEngine = MockSyncEngine();
    tokenStorage = TokenStorage();

    when(
      () => mockSyncEngine.flushOutbox(),
    ).thenAnswer((_) async => const Result.success(null));
    when(
      () => mockSyncEngine.syncProfile(any()),
    ).thenAnswer((_) async => const Result.success(null));
    when(
      () => mockSyncEngine.fetchAndRestoreProfiles(),
    ).thenAnswer((_) async => const Result.success(null));
  });

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        tokenStorageProvider.overrideWithValue(tokenStorage),
        authRepositoryProvider.overrideWithValue(mockAuthRepo),
        syncEngineProvider.overrideWithValue(mockSyncEngine),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('AuthNotifier Tests', () {
    test('initial build returns null when no token in storage', () async {
      final container = createContainer();
      final user = await container.read(authProvider.future);
      expect(user, isNull);
    });

    test('loginWithGoogle updates state on success', () async {
      const authUser = AuthUser(
        id: 'usr-123',
        email: 'test@example.com',
        name: 'Test User',
      );

      when(
        () => mockAuthRepo.loginWithGoogle(any()),
      ).thenAnswer((_) async => const Result.success(authUser));

      final container = createContainer();
      final result = await container
          .read(authProvider.notifier)
          .loginWithGoogle('valid-token');

      expect(result.isSuccess, isTrue);
      expect(container.read(authProvider).value, equals(authUser));
    });

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
