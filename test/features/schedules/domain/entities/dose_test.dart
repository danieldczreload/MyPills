import 'package:flutter_test/flutter_test.dart';
import 'package:my_pills/core/errors/failure.dart';
import 'package:my_pills/features/schedules/domain/entities/dose.dart';

void main() {
  group('parseDose', () {
    test('parses a full dose object', () {
      final dose = parseDose({
        'amount': 400,
        'unit': 'mg',
        'display': '400 mg',
      });

      expect(dose, isNotNull);
      expect(dose!.amount, 400);
      expect(dose.unit, 'mg');
      expect(dose.display, '400 mg');
    });

    test('parses a decimal amount', () {
      final dose = parseDose({
        'amount': 2.5,
        'unit': 'ml',
        'display': '2.5 ml',
      });

      expect(dose, isNotNull);
      expect(dose!.amount, 2.5);
      expect(dose.unit, 'ml');
    });

    test('returns null when json is null', () {
      expect(parseDose(null), isNull);
    });

    test('returns null when json is not a map', () {
      expect(parseDose('400 mg'), isNull);
    });

    test('returns null when amount is missing', () {
      expect(parseDose({'unit': 'mg', 'display': '400 mg'}), isNull);
    });
  });

  group('Dose.fromJson', () {
    test('does not require display if amount and unit are present', () {
      final dose = Dose.fromJson({'amount': 5, 'unit': 'ml'});
      expect(dose.display, '5 ml');
    });
  });

  group('validateDose', () {
    test('returns doseRequired when null', () {
      expect(
        validateDose(null),
        const Failure.validation(code: ValidationCode.doseRequired),
      );
    });

    test('returns invalidDoseAmount when amount is not positive', () {
      expect(
        validateDose(const Dose(amount: 0, unit: 'mg', display: '0 mg')),
        const Failure.validation(code: ValidationCode.invalidDoseAmount),
      );
    });

    test('accepts a valid dose', () {
      expect(
        validateDose(const Dose(amount: 400, unit: 'mg', display: '400 mg')),
        isNull,
      );
    });
  });

  group('Dose.labeled', () {
    test('joins name and display', () {
      const dose = Dose(amount: 5, unit: 'ml', display: '5 ml');
      expect(dose.labeled('Ibuprofeno'), 'Ibuprofeno · 5 ml');
    });
  });
}
