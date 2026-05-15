import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_pills/core/db/app_database.dart';
import 'package:my_pills/core/errors/failure.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/features/tracker/data/repositories/drift_dose_event_repository.dart';
import 'package:my_pills/features/tracker/domain/entities/dose_event.dart';

import '../../../../helpers/sqlite_support.dart';

final bool _sqliteAvailable = hasSqliteRuntime();

void main() {
  if (!_sqliteAvailable) {
    test(
      'drift dose-event repository tests are skipped without sqlite runtime',
      () {},
      skip: 'libsqlite3.so is unavailable in this environment',
    );
    return;
  }

  late AppDatabase db;
  late DriftDoseEventRepository repository;
  late int medicationId;
  late int scheduleId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repository = DriftDoseEventRepository(db);

    medicationId = await db.medicationDao.insertMedication(
      MedicationsTableCompanion.insert(
        name: 'Vitamina C',
        form: 'pill',
        category: 'Supplements',
        colorToken: 'lime',
      ),
    );

    scheduleId = await db.scheduleDao.insertSchedule(
      SchedulesTableCompanion.insert(
        medicationId: medicationId,
        ruleType: 'daily',
        ruleJson: '{"timesOfDay":[{"hour":8,"minute":0}]}',
        startDateUtc: DateTime(2024, 6).toUtc(),
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('getForDate returns only events in the requested local day', () async {
    await db.doseEventsDao.insertDoseEvent(
      DoseEventsTableCompanion.insert(
        medicationId: medicationId,
        scheduleId: scheduleId,
        scheduledAtUtc: DateTime(2024, 6, 10, 8).toUtc(),
        status: DoseStatus.pending.name,
      ),
    );
    await db.doseEventsDao.insertDoseEvent(
      DoseEventsTableCompanion.insert(
        medicationId: medicationId,
        scheduleId: scheduleId,
        scheduledAtUtc: DateTime(2024, 6, 11, 8).toUtc(),
        status: DoseStatus.pending.name,
      ),
    );

    final result = await repository.getForDate(DateTime(2024, 6, 10));
    final events = result.valueOrNull;

    expect(events, isNotNull);
    expect(events, hasLength(1));
    expect(events!.single.scheduledAt.day, 10);
  });

  test('markTaken updates pending event status and takenAt', () async {
    final eventId = await db.doseEventsDao.insertDoseEvent(
      DoseEventsTableCompanion.insert(
        medicationId: medicationId,
        scheduleId: scheduleId,
        scheduledAtUtc: DateTime(2024, 6, 12, 8).toUtc(),
        status: DoseStatus.pending.name,
      ),
    );
    final takenAt = DateTime(2024, 6, 12, 8, 30);

    final markResult = await repository.markTaken(eventId, takenAt);
    final dayEvents = await repository.getForDate(DateTime(2024, 6, 12));

    expect(markResult.isSuccess, isTrue);
    final event = dayEvents.valueOrNull!.single;
    expect(event.status, DoseStatus.taken);
    expect(event.takenAt, takenAt);
  });

  test('markMissed returns notFound for non-pending event', () async {
    final eventId = await db.doseEventsDao.insertDoseEvent(
      DoseEventsTableCompanion.insert(
        medicationId: medicationId,
        scheduleId: scheduleId,
        scheduledAtUtc: DateTime(2024, 6, 13, 8).toUtc(),
        status: DoseStatus.taken.name,
      ),
    );

    final result = await repository.markMissed(eventId);

    expect(result, const Result<void>.failure(Failure.notFound()));
  });

  test(
    'reconcilePendingForSchedule manages pending reconciliation',
    () async {
      await db.doseEventsDao.insertDoseEvent(
        DoseEventsTableCompanion.insert(
          medicationId: medicationId,
          scheduleId: scheduleId,
          scheduledAtUtc: DateTime(2024, 6, 14, 8).toUtc(),
          status: DoseStatus.pending.name,
        ),
      );

      final preservedTakenId = await db.doseEventsDao.insertDoseEvent(
        DoseEventsTableCompanion.insert(
          medicationId: medicationId,
          scheduleId: scheduleId,
          scheduledAtUtc: DateTime(2024, 6, 14, 20).toUtc(),
          status: DoseStatus.taken.name,
          takenAtUtc: drift.Value(DateTime(2024, 6, 14, 20, 5).toUtc()),
        ),
      );

      final reconcile = await repository.reconcilePendingForSchedule(
        medicationId: medicationId,
        scheduleId: scheduleId,
        rangeStartUtc: DateTime(2024, 6, 14).toUtc(),
        rangeEndExclusiveUtc: DateTime(2024, 6, 15).toUtc(),
        expectedScheduledAt: [
          DateTime(2024, 6, 14, 20),
          DateTime(2024, 6, 14, 22),
        ],
      );

      expect(reconcile, const Result<void>.success(null));

      final rows = await db.doseEventsDao.getInUtcRange(
        DateTime(2024, 6, 14).toUtc(),
        DateTime(2024, 6, 15).toUtc(),
      );

      expect(rows, hasLength(2));
      expect(
        rows.map((r) => r.scheduledAtUtc.toLocal()),
        [DateTime(2024, 6, 14, 20), DateTime(2024, 6, 14, 22)],
      );
      expect(
        rows.where((r) => r.status == DoseStatus.taken.name),
        hasLength(1),
      );
      expect(
        rows.where((r) => r.status == DoseStatus.pending.name),
        hasLength(1),
      );
      expect(rows.any((r) => r.id == preservedTakenId), isTrue);
    },
  );
}
