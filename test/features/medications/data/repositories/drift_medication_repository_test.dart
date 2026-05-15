import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_pills/core/db/app_database.dart';
import 'package:my_pills/core/errors/failure.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/features/medications/data/repositories/drift_medication_repository.dart';
import 'package:my_pills/features/medications/domain/entities/medication.dart';

import '../../../../helpers/sqlite_support.dart';

final bool _sqliteAvailable = hasSqliteRuntime();

void main() {
  if (!_sqliteAvailable) {
    test(
      'drift medication repository tests are skipped without sqlite runtime',
      () {},
      skip: 'libsqlite3.so is unavailable in this environment',
    );
    return;
  }

  late AppDatabase db;
  late DriftMedicationRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = DriftMedicationRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('add persists medication and returns assigned id', () async {
    final result = await repository.add(
      const Medication(
        id: 0,
        name: 'Paracetamol',
        form: MedicationForm.pill,
        category: 'Pain',
        colorToken: 'sky',
      ),
    );

    final medication = result.valueOrNull;
    expect(medication, isNotNull);
    expect(medication!.id, greaterThan(0));
    expect(medication.name, 'Paracetamol');
  });

  test('getAll returns medications sorted by name', () async {
    await repository.add(
      const Medication(
        id: 0,
        name: 'ZetaMed',
        form: MedicationForm.pill,
        category: 'Category',
        colorToken: 'blue',
      ),
    );
    await repository.add(
      const Medication(
        id: 0,
        name: 'AlphaMed',
        form: MedicationForm.capsule,
        category: 'Category',
        colorToken: 'green',
      ),
    );

    final result = await repository.getAll();
    final items = result.valueOrNull;

    expect(items, isNotNull);
    expect(items!.map((m) => m.name).toList(growable: false), [
      'AlphaMed',
      'ZetaMed',
    ]);
  });

  test('update returns notFound when id does not exist', () async {
    final result = await repository.update(
      const Medication(
        id: 999,
        name: 'Unknown',
        form: MedicationForm.liquid,
        category: 'Category',
        colorToken: 'amber',
      ),
    );

    expect(result, const Result<Medication>.failure(Failure.notFound()));
  });

  test('delete removes existing medication', () async {
    final created = await repository.add(
      const Medication(
        id: 0,
        name: 'Ibuprofen',
        form: MedicationForm.pill,
        category: 'Pain',
        colorToken: 'orange',
      ),
    );

    final id = created.valueOrNull!.id;
    final deleteResult = await repository.delete(id);
    final lookup = await repository.getById(id);

    expect(deleteResult.isSuccess, isTrue);
    expect(lookup, const Result<Medication>.failure(Failure.notFound()));
  });
}
