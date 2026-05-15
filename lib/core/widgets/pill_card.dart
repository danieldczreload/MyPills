import 'package:flutter/material.dart';

import 'package:my_pills/core/theme/serene_theme.dart';
import 'package:my_pills/core/widgets/gradient_primary_button.dart';
import 'package:my_pills/core/widgets/status_chip.dart';

class PillCard extends StatelessWidget {
  const PillCard({
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    required this.tone,
    super.key,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.leading,
  });

  final String title;
  final String subtitle;
  final String statusLabel;
  final StatusChipTone tone;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final serene = theme.extension<SereneTheme>()!;

    return Container(
      padding: EdgeInsets.all(serene.spacing.cardPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: serene.radius.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (leading != null) ...[
                leading!,
                SizedBox(width: serene.spacing.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    SizedBox(height: serene.spacing.xs),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              StatusChip(label: statusLabel, tone: tone),
            ],
          ),
          if (primaryActionLabel != null || secondaryActionLabel != null) ...[
            SizedBox(height: serene.spacing.lg),
            Row(
              children: [
                if (primaryActionLabel != null)
                  Expanded(
                    child: GradientPrimaryButton(
                      label: primaryActionLabel!,
                      onPressed: onPrimaryAction,
                    ),
                  ),
                if (primaryActionLabel != null && secondaryActionLabel != null)
                  SizedBox(width: serene.spacing.sm),
                if (secondaryActionLabel != null)
                  TextButton(
                    onPressed: onSecondaryAction,
                    child: Text(secondaryActionLabel!),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
