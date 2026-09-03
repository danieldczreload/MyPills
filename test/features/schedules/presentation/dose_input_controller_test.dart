import 'package:flutter_test/flutter_test.dart';
import 'package:my_pills/core/errors/failure.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/features/schedules/domain/entities/dose.dart';
import 'package:my_pills/features/schedules/presentation/dose_input_controller.dart';

void main() {
  late DoseInputController controller;

  setUp(() {
    controller = DoseInputController();
  });

  tearDown(() => controller.dispose());

  test('returns doseRequired when amount or unit is missing', () {
    final result = controller.read();
    expect(
      result,
      const Result<Dose>.failure(
        Failure.validation(code: ValidationCode.doseRequired),
      ),
    );
  });

  test('returns invalidDoseAmount when more than 4 decimals', () {
    controller
      ..amount.text = '1.12345'
      ..unitCode = 'ml';
    final result = controller.read();
    expect(
      result,
      const Result<Dose>.failure(
        Failure.validation(code: ValidationCode.invalidDoseAmount),
      ),
    );
  });

  test('builds a Dose from valid input', () {
    controller
      ..amount.text = '2,5'
      ..unitCode = 'ml';
    final result = controller.read();
    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull?.amount, 2.5);
    expect(result.valueOrNull?.unit, 'ml');
    expect(result.valueOrNull?.display, '2.5 ml');
  });
}
