import 'package:flutter/material.dart';
import 'package:my_pills/core/theme/serene_theme.dart';
import 'package:my_pills/l10n/app_localizations.dart';

class TaxonomySegmentedControl extends StatelessWidget {
  const TaxonomySegmentedControl({
    required this.selectedIndex,
    required this.onChanged,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final serene = theme.extension<SereneTheme>()!;

    return Container(
      padding: EdgeInsets.all(serene.spacing.xs),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: serene.radius.full,
      ),
      child: Row(
        children: [
          _Segment(
            label: l10n.segmentCategories,
            isSelected: selectedIndex == 0,
            onTap: () => onChanged(0),
          ),
          _Segment(
            label: l10n.segmentDiseases,
            isSelected: selectedIndex == 1,
            onTap: () => onChanged(1),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final serene = theme.extension<SereneTheme>()!;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: serene.spacing.md),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.surfaceContainerLowest
                : Colors.transparent,
            borderRadius: serene.radius.full,
            boxShadow: isSelected ? serene.ambientShadow : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelLarge?.copyWith(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
