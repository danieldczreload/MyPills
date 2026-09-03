import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_pills/core/db/app_database.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/core/sync/sync_engine.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:my_pills/features/profile/data/repositories/synced_profile_repository.dart';
import 'package:my_pills/features/profile/domain/entities/user_profile.dart';
import 'package:my_pills/features/profile/domain/repositories/user_profile_repository.dart';

import '../../../../helpers/sqlite_support.dart';

class MockLocalProfileRepository extends Mock
    implements UserProfileRepository {}

class MockSyncEngine extends Mock implements SyncEngine {}

void main() {
  if (!hasSqliteRuntime()) {
    test(
      'SyncedProfileRepository tests skipped without sqlite runtime',
      () {},
      skip: true,
    );
    return;
  }

  late AppDatabase db;
  late MockLocalProfileRepository mockLocalRepo;
  late MockSyncEngine mockSyncEngine;
  late SyncedProfileRepository repository;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    mockLocalRepo = MockLocalProfileRepository();
    mockSyncEngine = MockSyncEngine();

    when(
      () => mockSyncEngine.flushOutbox(),
    ).thenAnswer((_) async => const Result.success(null));
    when(() => mockLocalRepo.getProfileById(any())).thenReturn(null);

    repository = SyncedProfileRepository(
      localRepo: mockLocalRepo,
      db: db,
      syncEngine: mockSyncEngine,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('SyncedProfileRepository', () {
    final profile = UserProfile(
      name: 'Maria Gomez',
      birthDate: DateTime(1990, 5, 20),
      gender: 'female',
    );

    test('getProfile delegates to localRepo', () {
      when(() => mockLocalRepo.getProfile()).thenReturn(profile);
      expect(repository.getProfile(), equals(profile));
    });

    test('isOnboardingComplete delegates to localRepo', () {
      when(() => mockLocalRepo.isOnboardingComplete()).thenReturn(true);
      expect(repository.isOnboardingComplete(), isTrue);
    });

    test('saveProfile saves locally and enqueues outbox operation', () async {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('America/Mexico_City'));
      when(() => mockLocalRepo.saveProfile(profile)).thenAnswer((_) async {});

      await repository.saveProfile(profile);

      verify(() => mockLocalRepo.saveProfile(profile)).called(1);
      final outboxItems = await db.select(db.outboxTable).get();
      expect(outboxItems.length, equals(1));
      expect(outboxItems.first.entityType, equals('profile'));
      expect(outboxItems.first.action, equals('UPDATE'));
      final payload =
          jsonDecode(outboxItems.first.payloadJson) as Map<String, dynamic>;
      expect(payload['timezone'], 'America/Mexico_City');
      expect(payload['birthDate'], '1990-05-20');
      verify(() => mockSyncEngine.flushOutbox()).called(1);
    });
  });
}
