import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_pills/core/db/app_database.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/core/sync/sync_engine.dart';
import 'package:my_pills/features/medications/data/repositories/synced_medications_repository.dart';
import 'package:my_pills/features/medications/domain/entities/medication.dart';
import 'package:my_pills/features/medications/domain/repositories/medication_repository.dart';

import '../../../../helpers/sqlite_support.dart';

class MockLocalMedicationRepository extends Mock
    implements MedicationRepository {}

class MockSyncEngine extends Mock implements SyncEngine {}

void main() {
  if (!hasSqliteRuntime()) {
    test(
      'SyncedMedicationRepository tests skipped without sqlite runtime',
      () {},
      skip: true,
    );
    return;
  }

  late AppDatabase db;
  late MockLocalMedicationRepository mockLocalRepo;
  late MockSyncEngine mockSyncEngine;
  late SyncedMedicationRepository repository;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    mockLocalRepo = MockLocalMedicationRepository();
    mockSyncEngine = MockSyncEngine();

    when(
      () => mockSyncEngine.flushOutbox(),
    ).thenAnswer((_) async => const Result.success(null));

    repository = SyncedMedicationRepository(
      localRepo: mockLocalRepo,
      db: db,
      syncEngine: mockSyncEngine,
      profileId: 'profile-123',
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('SyncedMedicationRepository', () {
    const med = Medication(
      id: 1,
      name: 'Paracetamol',
      form: MedicationForm.pill,
      category: 'Analgesia',
      colorToken: 'sky',
      notes: 'Tomar con agua',
    );

    test('getAll delegates to localRepo', () async {
      when(
        () => mockLocalRepo.getAll(),
      ).thenAnswer((_) async => const Result.success([med]));
      final result = await repository.getAll();
      expect(result.valueOrNull, equals([med]));
    });

    test('watchAll delegates to localRepo', () async {
      when(
        () => mockLocalRepo.watchAll(),
      ).thenAnswer((_) => Stream.value(const Result.success([med])));
      final stream = repository.watchAll();
      expect(await stream.first, equals(const Result.success([med])));
    });

    test('getById delegates to localRepo', () async {
      when(
        () => mockLocalRepo.getById(1),
      ).thenAnswer((_) async => const Result.success(med));
      final result = await repository.getById(1);
      expect(result.valueOrNull, equals(med));
    });

    test('add inserts outbox operation and triggers flushOutbox', () async {
      when(
        () => mockLocalRepo.add(med),
      ).thenAnswer((_) async => const Result.success(med));

      final result = await repository.add(med);
      expect(result.isSuccess, isTrue);

      final outboxItems = await db.select(db.outboxTable).get();
      expect(outboxItems.length, equals(1));
      expect(outboxItems.first.entityType, equals('medication'));
      expect(outboxItems.first.action, equals('CREATE'));
      expect(outboxItems.first.profileId, equals('profile-123'));
      verify(() => mockSyncEngine.flushOutbox()).called(1);
    });

    test('update inserts outbox operation and triggers flushOutbox', () async {
      when(
        () => mockLocalRepo.update(med),
      ).thenAnswer((_) async => const Result.success(med));

      final result = await repository.update(med);
      expect(result.isSuccess, isTrue);

      final outboxItems = await db.select(db.outboxTable).get();
      expect(outboxItems.length, equals(1));
      expect(outboxItems.first.entityType, equals('medication'));
      expect(outboxItems.first.action, equals('UPDATE'));
      verify(() => mockSyncEngine.flushOutbox()).called(1);
    });

    test('delete inserts outbox operation and triggers flushOutbox', () async {
      when(
        () => mockLocalRepo.delete(1),
      ).thenAnswer((_) async => const Result.success(null));

      final result = await repository.delete(1);
      expect(result.isSuccess, isTrue);

      final outboxItems = await db.select(db.outboxTable).get();
      expect(outboxItems.length, equals(1));
      expect(outboxItems.first.entityType, equals('medication'));
      expect(outboxItems.first.action, equals('DELETE'));
      verify(() => mockSyncEngine.flushOutbox()).called(1);
    });
  });
}
