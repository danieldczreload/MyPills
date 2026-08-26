import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_pills/core/db/app_database.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/core/sync/sync_engine.dart';
import 'package:my_pills/features/tracker/data/repositories/synced_dose_events_repository.dart';
import 'package:my_pills/features/tracker/domain/repositories/dose_event_repository.dart';

import '../../../../helpers/sqlite_support.dart';

class MockLocalDoseEventRepository extends Mock
    implements DoseEventRepository {}

class MockSyncEngine extends Mock implements SyncEngine {}

void main() {
  if (!hasSqliteRuntime()) {
    test(
      'SyncedDoseEventRepository tests skipped without sqlite runtime',
      () {},
      skip: true,
    );
    return;
  }

  late AppDatabase db;
  late MockLocalDoseEventRepository mockLocalRepo;
  late MockSyncEngine mockSyncEngine;
  late SyncedDoseEventRepository repository;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    mockLocalRepo = MockLocalDoseEventRepository();
    mockSyncEngine = MockSyncEngine();

    when(
      () => mockSyncEngine.flushOutbox(),
    ).thenAnswer((_) async => const Result.success(null));

    // Seed local medication and schedule in DB for foreign key resolution
    await db
        .into(db.medicationsTable)
        .insert(
          MedicationsTableCompanion.insert(
            id: const Value(10),
            name: 'Test Med',
            form: 'pill',
            category: 'General',
            colorToken: 'sky',
            clientId: const Value('med-client-1'),
          ),
        );

    await db
        .into(db.schedulesTable)
        .insert(
          SchedulesTableCompanion.insert(
            id: const Value(20),
            medicationId: 10,
            ruleType: 'daily',
            ruleJson: '{}',
            startDateUtc: DateTime.now().toUtc(),
            clientId: const Value('sched-client-1'),
          ),
        );

    await db
        .into(db.doseEventsTable)
        .insert(
          DoseEventsTableCompanion.insert(
            id: const Value(1),
            medicationId: 10,
            scheduleId: 20,
            scheduledAtUtc: DateTime.now().toUtc(),
            status: 'pending',
            clientId: const Value('dose-client-1'),
          ),
        );

    repository = SyncedDoseEventRepository(
      localRepo: mockLocalRepo,
      db: db,
      syncEngine: mockSyncEngine,
      profileId: 'profile-123',
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('SyncedDoseEventRepository', () {
    final now = DateTime.now();

    test('markTaken inserts outbox op and flushes', () async {
      when(
        () => mockLocalRepo.markTaken(1, any()),
      ).thenAnswer((_) async => const Result.success(null));

      final result = await repository.markTaken(1, now);
      expect(result.isSuccess, isTrue);

      final outboxItems = await db.select(db.outboxTable).get();
      expect(outboxItems.length, equals(1));
      expect(outboxItems.first.entityType, equals('dose_event'));
      expect(outboxItems.first.action, equals('UPDATE'));
      verify(() => mockSyncEngine.flushOutbox()).called(1);
    });

    test('markMissed inserts outbox op and flushes', () async {
      when(
        () => mockLocalRepo.markMissed(1),
      ).thenAnswer((_) async => const Result.success(null));

      final result = await repository.markMissed(1);
      expect(result.isSuccess, isTrue);

      final outboxItems = await db.select(db.outboxTable).get();
      expect(outboxItems.length, equals(1));
      expect(outboxItems.first.entityType, equals('dose_event'));
      expect(outboxItems.first.action, equals('UPDATE'));
      verify(() => mockSyncEngine.flushOutbox()).called(1);
    });

    test('delete inserts outbox op and flushes', () async {
      when(
        () => mockLocalRepo.delete(1),
      ).thenAnswer((_) async => const Result.success(null));

      final result = await repository.delete(1);
      expect(result.isSuccess, isTrue);

      final outboxItems = await db.select(db.outboxTable).get();
      expect(outboxItems.length, equals(1));
      expect(outboxItems.first.entityType, equals('dose_event'));
      expect(outboxItems.first.action, equals('DELETE'));
      verify(() => mockSyncEngine.flushOutbox()).called(1);
    });
  });
}
