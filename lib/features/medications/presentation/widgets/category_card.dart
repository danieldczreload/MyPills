import 'package:flutter/material.dart';
import 'package:my_pills/core/theme/serene_theme.dart';
import 'package:my_pills/l10n/app_localizations.dart';

class CategoryCard extends StatelessWidget {
  const CategoryCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.itemCount,
    this.onTap,
    super.key,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final int itemCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final serene = theme.extension<SereneTheme>()!;
    final l10n = AppLocalizations.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: serene.radius.lg,
        child: _buildCard(context, theme, serene, l10n),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    ThemeData theme,
    SereneTheme serene,
    AppLocalizations l10n,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: serene.radius.lg,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.10),
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
              // Accent bar — category color
              Container(width: 4, color: color),
              // Icon
              Padding(
                padding: EdgeInsets.all(serene.spacing.lg),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: serene.radius.md,
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
              ),
              // Title + description
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: serene.spacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: serene.spacing.xs),
                      Text(
                        description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              // Count badge + chevron
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: serene.spacing.lg,
                  vertical: serene.spacing.lg,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: serene.spacing.sm,
                        vertical: serene.spacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.10),
                        borderRadius: serene.radius.full,
                      ),
                      child: Text(
                        l10n.itemsCount(itemCount),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(height: serene.spacing.xs),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
