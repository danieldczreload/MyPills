import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_pills/app/providers.dart';
import 'package:my_pills/core/theme/serene_theme.dart';
import 'package:my_pills/core/widgets/soft_dropdown_field.dart';
import 'package:my_pills/core/widgets/soft_input_field.dart';
import 'package:my_pills/features/medications/domain/entities/medication.dart';
import 'package:my_pills/features/schedules/domain/entities/dose_unit.dart';
import 'package:my_pills/features/schedules/presentation/dose_input_controller.dart';
import 'package:my_pills/l10n/app_localizations.dart';

/// Amount + catalog-unit picker. Owns catalog load and default unit.
class DosePicker extends ConsumerStatefulWidget {
  const DosePicker({
    required this.controller,
    required this.medicationForm,
    super.key,
  });

  final DoseInputController controller;
  final MedicationForm medicationForm;

  @override
  ConsumerState<DosePicker> createState() => _DosePickerState();
}

class _DosePickerState extends ConsumerState<DosePicker> {
  @override
  void initState() {
    super.initState();
    _assignDefault(ref.read(doseUnitsProvider).value, rebuild: false);
  }

  @override
  void didUpdateWidget(DosePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.medicationForm != widget.medicationForm) {
      widget.controller.unitCode = null;
      _assignDefault(ref.read(doseUnitsProvider).value, rebuild: true);
    }
  }

  void _assignDefault(List<DoseUnit>? units, {required bool rebuild}) {
    if (units == null || units.isEmpty) return;
    final ordered = unitsOrderedForForm(units, widget.medicationForm.name);
    if (ordered.isEmpty) return;
    final current = widget.controller.unitCode;
    if (current != null && ordered.any((u) => u.code == current)) return;
    widget.controller.unitCode = ordered.first.code;
    if (rebuild && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final serene = theme.extension<SereneTheme>()!;
    final unitsAsync = ref.watch(doseUnitsProvider);
    ref.listen(doseUnitsProvider, (previous, next) {
      _assignDefault(next.value, rebuild: true);
    });
    final ordered = unitsOrderedForForm(
      unitsAsync.value ?? const <DoseUnit>[],
      widget.medicationForm.name,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.doseSectionTitle,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        SizedBox(height: serene.spacing.xs),
        Text(
          l10n.doseSectionSubtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: serene.spacing.md),
        if (unitsAsync.isLoading)
          const Center(child: CircularProgressIndicator())
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SoftInputField(
                  controller: widget.controller.amount,
                  labelText: l10n.doseAmountLabel,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[0-9.,]')),
                  ],
                ),
              ),
              SizedBox(width: serene.spacing.md),
              Expanded(
                child: SoftDropdownField<String>(
                  value: widget.controller.unitCode,
                  labelText: l10n.doseUnitLabel,
                  items: ordered
                      .map(
                        (unit) => DropdownMenuItem(
                          value: unit.code,
                          child: Text(unit.symbol),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (code) {
                    setState(() => widget.controller.unitCode = code);
                  },
                ),
              ),
            ],
          ),
      ],
    );
  }
}
