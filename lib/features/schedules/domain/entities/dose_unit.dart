/// An entry from `GET /api/v1/dose-units`.
class DoseUnit {
  const DoseUnit({
    required this.code,
    required this.symbol,
    required this.name,
    required this.kind,
    required this.suggestedForForms,
  });

  factory DoseUnit.fromJson(Map<String, dynamic> json) {
    return DoseUnit(
      code: json['code'] as String,
      symbol: json['symbol'] as String? ?? json['code'] as String,
      name: json['name'] as String? ?? json['code'] as String,
      kind: json['kind'] as String? ?? 'special',
      suggestedForForms:
          (json['suggestedForForms'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList(growable: false) ??
          const [],
    );
  }

  /// Canonical value sent as `doseUnit` on POST schedule.
  final String code;

  /// Short label for the picker (`mg`, `ml`, `µg` is never sent — use `mcg`).
  final String symbol;

  /// Human-readable name (`milligram`).
  final String name;

  /// Grouping: `mass` | `volume` | `household` | `special` | `count`.
  final String kind;

  /// Medication forms this unit is suggested for (`pill`, `liquid`, …).
  final List<String> suggestedForForms;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DoseUnit &&
          code == other.code &&
          symbol == other.symbol &&
          name == other.name &&
          kind == other.kind;

  @override
  int get hashCode => Object.hash(code, symbol, name, kind);
}

/// Forms used to pre-filter catalog suggestions for a medication form.
List<String> suggestedFormAliases(String formName) {
  return switch (formName) {
    'pill' => const ['pill', 'tablet', 'capsule'],
    'capsule' => const ['capsule', 'pill', 'tablet'],
    'liquid' => const ['liquid', 'syrup', 'drops'],
    'drops' => const ['drops', 'liquid', 'syrup'],
    'injection' => const ['injection'],
    'inhaler' => const ['inhaler', 'puff'],
    'patch' => const ['patch'],
    _ => const <String>[],
  };
}

/// Suggested units first, then the rest of the catalog. Never hides units —
/// the user can pick any code.
List<DoseUnit> unitsOrderedForForm(List<DoseUnit> units, String formName) {
  final aliases = suggestedFormAliases(formName).toSet();
  if (aliases.isEmpty) return units;
  final suggested = <DoseUnit>[];
  final rest = <DoseUnit>[];
  for (final unit in units) {
    if (unit.suggestedForForms.any(aliases.contains)) {
      suggested.add(unit);
    } else {
      rest.add(unit);
    }
  }
  return [...suggested, ...rest];
}
