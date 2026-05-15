import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_pills/core/db/app_database.dart';
import 'package:my_pills/features/schedules/data/repositories/drift_schedule_repository.dart';
import 'package:my_pills/features/schedules/domain/entities/schedule.dart';

import '../../../../helpers/sqlite_support.dart';

final bool _sqliteAvailable = hasSqliteRuntime();

void main() {
  if (!_sqliteAvailable) {
    test(
      'drift schedule repository tests are skipped without sqlite runtime',
      () {},
      skip: 'libsqlite3.so is unavailable in this environment',
    );
    return;
  }

  late AppDatabase db;
  late DriftScheduleRepository repository;
  late int medicationId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repository = DriftScheduleRepository(db);
    medicationId = await db.medicationDao.insertMedication(
      MedicationsTableCompanion.insert(
        name: 'Aspirina',
        form: 'pill',
        category: 'Pain',
        colorToken: 'teal',
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'create persists and getById rehydrates DailyInterval schedule',
    () async {
      final input = Schedule.dailyInterval(
        id: 0,
        medicationId: medicationId,
        everyHours: 6,
        startAt: (hour: 8, minute: 0),
        endAt: (hour: 20, minute: 0),
        startDate: DateTime(2024, 6),
        endDate: DateTime(2024, 6, 30),
      );

      final created = await repository.create(input);
      final createdSchedule = created.valueOrNull;
      expect(createdSchedule, isNotNull);

      final loaded = await repository.getById(createdSchedule!.id);
      final loadedSchedule = loaded.valueOrNull;
      expect(loadedSchedule, isNotNull);
      expect(loadedSchedule, createdSchedule);
    },
  );

  test('watchAll emits updates after creating a schedule', () async {
    final stream = repository.watchAll();

    await repository.create(
      Schedule.daily(
        id: 0,
        medicationId: medicationId,
        timesOfDay: const [(hour: 9, minute: 0)],
        startDate: DateTime(2024, 7),
      ),
    );

    final event = await stream.firstWhere(
      (result) => result.valueOrNull?.isNotEmpty ?? false,
    );

    expect(event.valueOrNull, hasLength(1));
  });
}
