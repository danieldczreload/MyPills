import 'package:flutter/material.dart';
import 'package:my_pills/core/errors/failure.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/features/schedules/domain/entities/dose.dart';

/// Owns the amount text field and selected catalog unit for a new schedule.
class DoseInputController {
  DoseInputController();

  final TextEditingController amount = TextEditingController();
  String? unitCode;

  void dispose() => amount.dispose();

  Result<Dose> read() {
    final text = amount.text.trim();
    if (text.isEmpty || unitCode == null || unitCode!.isEmpty) {
      return const Result.failure(
        Failure.validation(code: ValidationCode.doseRequired),
      );
    }
    if (_moreThanFourDecimals(text)) {
      return const Result.failure(
        Failure.validation(code: ValidationCode.invalidDoseAmount),
      );
    }
    final parsed = num.tryParse(text.replaceAll(',', '.'));
    if (parsed == null) {
      return const Result.failure(
        Failure.validation(code: ValidationCode.invalidDoseAmount),
      );
    }
    final dose = Dose.input(amount: parsed, unit: unitCode!);
    final failure = validateDose(dose);
    if (failure != null) return Result.failure(failure);
    return Result.success(dose);
  }
}

bool _moreThanFourDecimals(String raw) {
  final trimmed = raw.trim().replaceAll(',', '.');
  final dot = trimmed.indexOf('.');
  if (dot < 0) return false;
  return trimmed.substring(dot + 1).length > 4;
}
