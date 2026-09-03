import 'package:drift/drift.dart';
import 'package:my_pills/features/schedules/domain/entities/dose.dart';

/// Physical layout of [Dose] on Drift rows (schedule + dose event).
class DoseFields {
  const DoseFields({this.amount, this.unit, this.display});

  factory DoseFields.of(Dose? dose) => DoseFields(
    amount: dose?.amount.toDouble(),
    unit: dose?.unit,
    display: dose?.display,
  );

  final double? amount;
  final String? unit;
  final String? display;

  Value<double?> get amountValue => Value(amount);
  Value<String?> get unitValue => Value(unit);
  Value<String?> get displayValue => Value(display);

  Dose? toDose() {
    if (amount == null || unit == null || unit!.isEmpty) return null;
    final canonical = canonicalizeDoseAmount(amount!);
    return Dose(
      amount: canonical,
      unit: unit!,
      display: (display != null && display!.isNotEmpty)
          ? display!
          : '${formatDoseAmount(canonical)} ${unit!}',
    );
  }
}
