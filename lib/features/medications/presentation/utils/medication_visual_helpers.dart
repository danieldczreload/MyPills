import 'package:flutter/material.dart';
import 'package:my_pills/features/medications/domain/entities/medication.dart';
import 'package:my_pills/l10n/app_localizations.dart';

Color resolveMedicationColor(String token, ThemeData theme) {
  return switch (token) {
    'secondary' => theme.colorScheme.secondary,
    'tertiary' => theme.colorScheme.tertiary,
    _ => theme.colorScheme.primary,
  };
}

IconData medicationFormIcon(MedicationForm form) {
  return switch (form) {
    MedicationForm.pill => Icons.medication_rounded,
    MedicationForm.capsule => Icons.medication_liquid_rounded,
    MedicationForm.liquid => Icons.local_drink_rounded,
    MedicationForm.injection => Icons.vaccines_rounded,
    MedicationForm.drops => Icons.water_drop_rounded,
    MedicationForm.inhaler => Icons.air_rounded,
    MedicationForm.patch => Icons.fiber_manual_record_rounded,
    MedicationForm.other => Icons.help_outline_rounded,
  };
}

String medicationFormLabel(AppLocalizations l10n, MedicationForm form) {
  return switch (form) {
    MedicationForm.pill => l10n.medicationFormPill,
    MedicationForm.capsule => l10n.medicationFormCapsule,
    MedicationForm.liquid => l10n.medicationFormLiquid,
    MedicationForm.injection => l10n.medicationFormInjection,
    MedicationForm.drops => l10n.medicationFormDrops,
    MedicationForm.inhaler => l10n.medicationFormInhaler,
    MedicationForm.patch => l10n.medicationFormPatch,
    MedicationForm.other => l10n.medicationFormOther,
  };
}
