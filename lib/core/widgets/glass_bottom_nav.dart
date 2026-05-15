import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:my_pills/core/theme/serene_theme.dart';

class GlassBottomNav extends StatelessWidget {
  const GlassBottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.items,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<({IconData icon, IconData selectedIcon, String label})> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final serene = theme.extension<SereneTheme>()!;

    return SafeArea(
      top: false,
      minimum: EdgeInsets.fromLTRB(
        serene.spacing.lg,
        serene.spacing.sm,
        serene.spacing.lg,
        serene.spacing.lg,
      ),
      child: ClipRRect(
        borderRadius: serene.radius.xl,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: serene.glassBlur,
            sigmaY: serene.glassBlur,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest.withValues(
                alpha: serene.glassOpacity,
              ),
              borderRadius: serene.radius.xl,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: serene.spacing.sm,
                vertical: serene.spacing.sm,
              ),
              child: Row(
                children: [
                  for (var i = 0; i < items.length; i++)
                    Expanded(
                      child: _NavItem(
                        isActive: i == currentIndex,
                        icon: items[i].icon,
                        selectedIcon: items[i].selectedIcon,
                        label: items[i].label,
                        onTap: () => onTap(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.isActive,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.onTap,
  });

  final bool isActive;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final serene = theme.extension<SereneTheme>()!;

    return SizedBox(
      height: 56,
      child: InkWell(
        borderRadius: serene.radius.md,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: serene.spacing.md,
            vertical: serene.spacing.xs,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            color: isActive
                ? theme.colorScheme.primary.withValues(alpha: 0.08)
                : Colors.transparent,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isActive ? selectedIcon : icon,
                size: 20,
                color: isActive
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 4),
              Text(
                label.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
