import 'package:flutter_test/flutter_test.dart';
import 'package:my_pills/core/db/app_database.dart';
import 'package:my_pills/features/medications/data/mappers/medication_mapper.dart';
import 'package:my_pills/features/medications/domain/entities/medication.dart';

void main() {
  group('MedicationMapper', () {
    test('toMedicationEntity maps row to domain entity', () {
      const row = MedicationsTableData(
        id: 7,
        name: 'Paracetamol',
        form: 'pill',
        category: 'Pain',
        colorToken: 'sky',
        notes: 'Take with food',
      );

      final entity = toMedicationEntity(row);

      expect(entity.id, 7);
      expect(entity.name, 'Paracetamol');
      expect(entity.form, MedicationForm.pill);
      expect(entity.category, 'Pain');
      expect(entity.colorToken, 'sky');
      expect(entity.notes, 'Take with food');
    });

    test('toMedicationEntity maps null notes to null', () {
      const row = MedicationsTableData(
        id: 1,
        name: 'Ibuprofen',
        form: 'capsule',
        category: 'Pain',
        colorToken: 'green',
      );

      final entity = toMedicationEntity(row);

      expect(entity.notes, isNull);
    });

    test('toMedicationInsertCompanion maps entity to companion', () {
      const entity = Medication(
        id: 0,
        name: 'Aspirin',
        form: MedicationForm.liquid,
        category: 'Heart',
        colorToken: 'red',
        notes: 'Before bed',
      );

      final companion = toMedicationInsertCompanion(entity);

      expect(companion.name.value, 'Aspirin');
      expect(companion.form.value, 'liquid');
      expect(companion.category.value, 'Heart');
      expect(companion.colorToken.value, 'red');
      expect(companion.notes.value, 'Before bed');
    });

    test('toMedicationInsertCompanion maps null notes to Value(null)', () {
      const entity = Medication(
        id: 0,
        name: 'Vitamin D',
        form: MedicationForm.pill,
        category: 'Supplements',
        colorToken: 'amber',
      );

      final companion = toMedicationInsertCompanion(entity);

      expect(companion.notes.present, isTrue);
      expect(companion.notes.value, isNull);
    });

    test('toMedicationRow maps entity back to data row', () {
      const entity = Medication(
        id: 5,
        name: 'Amoxicillin',
        form: MedicationForm.drops,
        category: 'Antibiotic',
        colorToken: 'teal',
        notes: '10 days course',
      );

      final row = toMedicationRow(entity);

      expect(row.id, 5);
      expect(row.name, 'Amoxicillin');
      expect(row.form, 'drops');
      expect(row.category, 'Antibiotic');
      expect(row.colorToken, 'teal');
      expect(row.notes, '10 days course');
    });
  });
}
