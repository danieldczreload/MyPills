import 'package:flutter_test/flutter_test.dart';
import 'package:my_pills/core/db/app_database.dart';
import 'package:my_pills/features/tracker/data/mappers/dose_event_mapper.dart';
import 'package:my_pills/features/tracker/domain/entities/dose_event.dart';

void main() {
  group('DoseEventMapper', () {
    test('toDoseEventEntity maps pending row to entity', () {
      final row = DoseEventsTableData(
        id: 1,
        medicationId: 10,
        scheduleId: 100,
        scheduledAtUtc: DateTime(2024, 6, 10, 8).toUtc(),
        status: 'pending',
        profileId: 'default',
        syncStatus: 'synced',
        isTombstone: false,
      );

      final entity = toDoseEventEntity(row);

      expect(entity.id, 1);
      expect(entity.medicationId, 10);
      expect(entity.scheduleId, 100);
      expect(entity.scheduledAt, DateTime(2024, 6, 10, 8));
      expect(entity.status, DoseStatus.pending);
      expect(entity.takenAt, isNull);
    });

    test('toDoseEventEntity maps taken row with takenAt to entity', () {
      final row = DoseEventsTableData(
        id: 2,
        medicationId: 20,
        scheduleId: 200,
        scheduledAtUtc: DateTime(2024, 6, 10, 14).toUtc(),
        status: 'taken',
        takenAtUtc: DateTime(2024, 6, 10, 14, 5).toUtc(),
        profileId: 'default',
        syncStatus: 'synced',
        isTombstone: false,
      );

      final entity = toDoseEventEntity(row);

      expect(entity.status, DoseStatus.taken);
      expect(entity.takenAt, DateTime(2024, 6, 10, 14, 5));
    });

    test('toDoseEventEntity maps missed row to entity', () {
      final row = DoseEventsTableData(
        id: 3,
        medicationId: 30,
        scheduleId: 300,
        scheduledAtUtc: DateTime(2024, 6, 10, 20).toUtc(),
        status: 'missed',
        profileId: 'default',
        syncStatus: 'synced',
        isTombstone: false,
      );

      final entity = toDoseEventEntity(row);

      expect(entity.status, DoseStatus.missed);
    });

    test('toDoseEventInsertCompanion maps entity to companion', () {
      final event = DoseEvent(
        id: 0,
        medicationId: 10,
        scheduleId: 100,
        scheduledAt: DateTime(2024, 6, 10, 8),
        status: DoseStatus.pending,
      );

      final companion = toDoseEventInsertCompanion(event);

      expect(companion.medicationId.value, 10);
      expect(companion.scheduleId.value, 100);
      expect(
        companion.scheduledAtUtc.value,
        DateTime(2024, 6, 10, 8).toUtc(),
      );
      expect(companion.status.value, 'pending');
      expect(companion.takenAtUtc.present, isTrue);
      expect(companion.takenAtUtc.value, isNull);
    });

    test('toDoseEventInsertCompanion maps taken event with takenAt', () {
      final event = DoseEvent(
        id: 1,
        medicationId: 20,
        scheduleId: 200,
        scheduledAt: DateTime(2024, 6, 10, 14),
        status: DoseStatus.taken,
        takenAt: DateTime(2024, 6, 10, 14, 5),
      );

      final companion = toDoseEventInsertCompanion(event);

      expect(companion.status.value, 'taken');
      expect(companion.takenAtUtc.value, DateTime(2024, 6, 10, 14, 5).toUtc());
    });
  });
}
