import 'package:flutter/material.dart';

import 'package:my_pills/core/theme/serene_theme.dart';

enum StatusChipTone { taken, pending, missed, systemError }

class StatusChip extends StatelessWidget {
  const StatusChip({
    required this.label,
    required this.tone,
    super.key,
  });

  final String label;
  final StatusChipTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final serene = theme.extension<SereneTheme>()!;
    final colors = _colors(theme.colorScheme);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: serene.spacing.md,
        vertical: serene.spacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: serene.radius.full,
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(color: colors.$2),
      ),
    );
  }

  (Color, Color) _colors(ColorScheme scheme) {
    return switch (tone) {
      StatusChipTone.taken => (
        scheme.secondary.withValues(alpha: 0.10),
        scheme.onSecondaryContainer,
      ),
      StatusChipTone.pending => (
        scheme.primary,
        scheme.onPrimary,
      ),
      StatusChipTone.missed => (
        scheme.tertiary.withValues(alpha: 0.20),
        scheme.onTertiaryContainer,
      ),
      StatusChipTone.systemError => (
        scheme.errorContainer,
        scheme.onErrorContainer,
      ),
    };
  }
}
