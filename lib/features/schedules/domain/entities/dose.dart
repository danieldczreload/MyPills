import 'package:my_pills/core/errors/failure.dart';

/// Amount + canonical unit + server-formatted label for a single intake.
///
/// [amount] is a JSON number (int or double). [unit] is a catalog `code`
/// (`mg`, `ml`, `tablet`, …). [display] is ready for UI — lists and today
/// use this field, they do not concatenate amount+unit.
class Dose {
  const Dose({
    required this.amount,
    required this.unit,
    required this.display,
  });

  /// Local placeholder [display] used until sync returns the server label.
  factory Dose.input({required num amount, required String unit}) {
    final canonical = canonicalizeDoseAmount(amount);
    return Dose(
      amount: canonical,
      unit: unit,
      display: '${formatDoseAmount(canonical)} $unit',
    );
  }

  factory Dose.fromJson(Map<String, dynamic> json) {
    final amount = json['amount'];
    if (amount is! num) {
      throw FormatException(
        'Dose.amount must be a number, got ${amount.runtimeType}',
      );
    }
    final unit = json['unit'];
    if (unit is! String || unit.isEmpty) {
      throw FormatException('Dose.unit must be a non-empty string');
    }
    final displayRaw = json['display'];
    final display = displayRaw is String && displayRaw.isNotEmpty
        ? displayRaw
        : '${formatDoseAmount(amount)} $unit';
    return Dose(amount: amount, unit: unit, display: display);
  }

  final num amount;
  final String unit;
  final String display;

  Map<String, dynamic> toJson() => {
    'amount': amount,
    'unit': unit,
    'display': display,
  };

  /// Today / list title: `Ibuprofeno · 5 ml`, or just the name if no display.
  String labeled(String medicationName) {
    if (display.isEmpty) return medicationName;
    return '$medicationName · $display';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Dose &&
          amount == other.amount &&
          unit == other.unit &&
          display == other.display;

  @override
  int get hashCode => Object.hash(amount, unit, display);

  @override
  String toString() => 'Dose(amount: $amount, unit: $unit, display: $display)';
}

/// Parses a nullable `dose` JSON object. Returns null for null, missing, or
/// malformed payloads — never throws for those cases.
Dose? parseDose(Object? json) {
  if (json is! Map<dynamic, dynamic>) return null;
  try {
    return Dose.fromJson(Map<String, dynamic>.from(json));
  } on FormatException {
    return null;
  }
}

num canonicalizeDoseAmount(num amount) {
  if (amount is int) return amount;
  if (amount == amount.roundToDouble()) return amount.round();
  return amount;
}

String formatDoseAmount(num amount) {
  return canonicalizeDoseAmount(amount).toString();
}

int decimalPlacesOf(num amount) {
  final text = amount.toString();
  if (text.contains('e') || text.contains('E')) {
    final fixed = amount.toStringAsFixed(8).replaceFirst(RegExp(r'\.?0+$'), '');
    final i = fixed.indexOf('.');
    return i < 0 ? 0 : fixed.length - i - 1;
  }
  final i = text.indexOf('.');
  return i < 0 ? 0 : text.length - i - 1;
}

/// Shared create-path rules. Null [dose] is valid on synced legacy rows;
/// new schedules must pass a non-null [Dose].
Failure? validateDose(Dose? dose) {
  if (dose == null) {
    return const Failure.validation(code: ValidationCode.doseRequired);
  }
  if (dose.amount <= 0 || decimalPlacesOf(dose.amount) > 4) {
    return const Failure.validation(code: ValidationCode.invalidDoseAmount);
  }
  if (dose.unit.trim().isEmpty) {
    return const Failure.validation(code: ValidationCode.invalidDoseUnit);
  }
  return null;
}
