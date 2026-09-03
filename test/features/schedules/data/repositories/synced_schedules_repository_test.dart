import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_pills/core/db/app_database.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/core/sync/sync_engine.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:my_pills/features/schedules/data/repositories/synced_schedules_repository.dart';
import 'package:my_pills/features/schedules/domain/entities/dose.dart';
import 'package:my_pills/features/schedules/domain/entities/schedule.dart';
import 'package:my_pills/features/schedules/domain/repositories/schedule_repository.dart';

import '../../../../helpers/sqlite_support.dart';

class MockLocalScheduleRepository extends Mock implements ScheduleRepository {}

class MockSyncEngine extends Mock implements SyncEngine {}

void main() {
  if (!hasSqliteRuntime()) {
    test(
      'SyncedScheduleRepository tests skipped without sqlite runtime',
      () {},
      skip: true,
    );
    return;
  }

  late AppDatabase db;
  late MockLocalScheduleRepository mockLocalRepo;
  late MockSyncEngine mockSyncEngine;
  late SyncedScheduleRepository repository;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    mockLocalRepo = MockLocalScheduleRepository();
    mockSyncEngine = MockSyncEngine();

    when(
      () => mockSyncEngine.flushOutbox(),
    ).thenAnswer((_) async => const Result.success(null));

    repository = SyncedScheduleRepository(
      localRepo: mockLocalRepo,
      db: db,
      syncEngine: mockSyncEngine,
      profileId: 'profile-123',
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('SyncedScheduleRepository', () {
    final schedule = Schedule.daily(
      id: 1,
      medicationId: 10,
      timesOfDay: const [(hour: 8, minute: 0)],
      startDate: DateTime(2026),
      dose: const Dose(amount: 5, unit: 'ml', display: '5 ml'),
    );

    test('getAll delegates to localRepo', () async {
      when(
        () => mockLocalRepo.getAll(),
      ).thenAnswer((_) async => Result.success([schedule]));
      final result = await repository.getAll();
      expect(result.valueOrNull, equals([schedule]));
    });

    test('watchAll delegates to localRepo', () async {
      when(
        () => mockLocalRepo.watchAll(),
      ).thenAnswer((_) => Stream.value(Result.success([schedule])));
      final stream = repository.watchAll();
      expect(await stream.first, equals(Result.success([schedule])));
    });

    test('getById delegates to localRepo', () async {
      when(
        () => mockLocalRepo.getById(1),
      ).thenAnswer((_) async => Result.success(schedule));
      final result = await repository.getById(1);
      expect(result.valueOrNull, equals(schedule));
    });

    test('create inserts outbox operation and flushes outbox', () async {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('America/Mexico_City'));
      when(
        () => mockLocalRepo.create(schedule),
      ).thenAnswer((_) async => Result.success(schedule));

      final result = await repository.create(schedule);
      expect(result.isSuccess, isTrue);

      final outboxItems = await db.select(db.outboxTable).get();
      expect(outboxItems, hasLength(1));
      expect(outboxItems.single.entityType, equals('schedule'));
      expect(outboxItems.single.action, equals('CREATE'));
      final payload =
          jsonDecode(outboxItems.single.payloadJson) as Map<String, dynamic>;
      expect(payload['doseAmount'], 5);
      expect(payload['doseUnit'], 'ml');
      expect(payload['clientId'], outboxItems.single.clientId);
      expect(payload.containsKey('dosage'), isFalse);
      expect(payload['timezone'], 'America/Mexico_City');
      expect(payload['startDate'], '2026-01-01');
      expect(payload['timesOfDay'], [
        {'hour': 8, 'minute': 0},
      ]);
      verify(() => mockSyncEngine.flushOutbox()).called(1);
    });

    test('delete inserts outbox operation and flushes outbox', () async {
      when(
        () => mockLocalRepo.delete(1),
      ).thenAnswer((_) async => const Result.success(null));

      final result = await repository.delete(1);
      expect(result.isSuccess, isTrue);

      final outboxItems = await db.select(db.outboxTable).get();
      expect(outboxItems.length, equals(1));
      expect(outboxItems.first.entityType, equals('schedule'));
      expect(outboxItems.first.action, equals('DELETE'));
      verify(() => mockSyncEngine.flushOutbox()).called(1);
    });

    test(
      'cancelRecurring inserts CANCEL_RECURRING op and flushes outbox',
      () async {
        when(
          () => mockLocalRepo.cancelRecurring(
            scheduleId: 1,
          ),
        ).thenAnswer((_) async => const Result.success(null));

        final result = await repository.cancelRecurring(
          scheduleId: 1,
        );
        expect(result.isSuccess, isTrue);

        final outboxItems = await db.select(db.outboxTable).get();
        expect(outboxItems.length, equals(1));
        expect(outboxItems.first.entityType, equals('schedule'));
        expect(outboxItems.first.action, equals('CANCEL_RECURRING'));
        verify(() => mockSyncEngine.flushOutbox()).called(1);
      },
    );
  });
}
