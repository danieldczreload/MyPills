import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_pills/core/theme/app_theme.dart';
import 'package:my_pills/features/medications/domain/entities/medication.dart';
import 'package:my_pills/features/medications/presentation/utils/medication_visual_helpers.dart';
import 'package:my_pills/l10n/app_localizations.dart';

void main() {
  group('medication_visual_helpers', () {
    test('resolveMedicationColor returns primary/secondary/tertiary', () {
      final theme = AppTheme.light();

      expect(
        resolveMedicationColor('primary', theme),
        theme.colorScheme.primary,
      );
      expect(
        resolveMedicationColor('secondary', theme),
        theme.colorScheme.secondary,
      );
      expect(
        resolveMedicationColor('tertiary', theme),
        theme.colorScheme.tertiary,
      );
      expect(
        resolveMedicationColor('unknown', theme),
        theme.colorScheme.primary,
      );
    });

    test('medicationFormIcon maps all MedicationForm enum values', () {
      for (final form in MedicationForm.values) {
        final icon = medicationFormIcon(form);
        expect(icon, isA<IconData>());
      }
    });

    testWidgets('medicationFormLabel maps localized form names', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('es'),
          home: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              for (final form in MedicationForm.values) {
                final label = medicationFormLabel(l10n, form);
                expect(label, isNotEmpty);
              }
              return const Placeholder();
            },
          ),
        ),
      );
    });
  });
}
