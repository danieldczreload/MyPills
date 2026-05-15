import 'package:flutter/material.dart';

import 'package:my_pills/core/theme/serene_theme.dart';

class GradientPrimaryButton extends StatelessWidget {
  const GradientPrimaryButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.isExpanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final serene = theme.extension<SereneTheme>()!;

    final child = DecoratedBox(
      decoration: BoxDecoration(
        gradient: serene.signatureGradient,
        borderRadius: serene.radius.xl,
        boxShadow: serene.ambientShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: serene.radius.xl,
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: serene.spacing.xl,
              vertical: serene.spacing.md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: theme.colorScheme.onPrimary),
                  SizedBox(width: serene.spacing.sm),
                ],
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!isExpanded) {
      return child;
    }

    return SizedBox(width: double.infinity, child: child);
  }
}
