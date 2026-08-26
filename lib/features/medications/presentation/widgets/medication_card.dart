import 'package:flutter/material.dart';
import 'package:my_pills/core/theme/serene_theme.dart';
import 'package:my_pills/features/medications/domain/entities/medication.dart';
import 'package:my_pills/features/medications/presentation/utils/medication_visual_helpers.dart';
import 'package:my_pills/l10n/app_localizations.dart';

/// Card representing a single medication in the list screen.
///
/// Follows DESIGN.md card spec: surfaceContainerLowest, radius.lg, no hard borders.
/// The left accent bar is tinted using the medication's colorToken.
///
/// Delete is handled at the list level via [Dismissible] — swipe right to reveal
/// the destructive action, keeping this widget fully focused on display + edit tap.
class MedicationCard extends StatelessWidget {
  const MedicationCard({
    required this.medication,
    required this.onTap,
    super.key,
  });

  final Medication medication;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final serene = theme.extension<SereneTheme>()!;
    final l10n = AppLocalizations.of(context);

    final accentColor = resolveMedicationColor(medication.colorToken, theme);
    final formIcon = medicationFormIcon(medication.form);
    final formLabel = medicationFormLabel(l10n, medication.form);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: serene.radius.lg,
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: serene.radius.lg,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Accent bar — medication color token
                Container(width: 4, color: accentColor),
                // Form icon
                Padding(
                  padding: EdgeInsets.all(serene.spacing.lg),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: serene.radius.md,
                    ),
                    child: Icon(formIcon, color: accentColor, size: 26),
                  ),
                ),
                // Name + category + form chip
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: serene.spacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          medication.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: serene.spacing.xs),
                        Text(
                          medication.category,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: serene.spacing.xs),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: serene.spacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.10),
                            borderRadius: serene.radius.full,
                          ),
                          child: Text(
                            formLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: accentColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Trailing chevron — visual affordance for tap-to-edit
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: serene.spacing.md),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
