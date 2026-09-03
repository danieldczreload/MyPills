import 'package:flutter_test/flutter_test.dart';
import 'package:my_pills/features/schedules/data/mappers/dose_mapper.dart';
import 'package:my_pills/features/schedules/domain/entities/dose.dart';

void main() {
  test('DoseFields.of round-trips a dose', () {
    const dose = Dose(amount: 400, unit: 'mg', display: '400 mg');
    final fields = DoseFields.of(dose);
    expect(fields.toDose(), dose);
  });

  test('DoseFields.toDose returns null when amount or unit is missing', () {
    expect(const DoseFields().toDose(), isNull);
    expect(const DoseFields(amount: 5).toDose(), isNull);
  });
}
