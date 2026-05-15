import 'package:flutter/material.dart';
import 'package:my_pills/core/theme/serene_theme.dart';
import 'package:my_pills/core/widgets/gradient_primary_button.dart';

class TimelineCard extends StatelessWidget {
  const TimelineCard({
    required this.title,
    required this.subtitle,
    required this.timeLabel,
    required this.isFocus,
    required this.chipColor,
    required this.chipTextColor,
    required this.trailingIcon,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.onTrailingIconPressed,
    super.key,
  });

  final String title;
  final String subtitle;
  final String timeLabel; // E.g. "Taken • 8:00 AM"
  final bool isFocus;
  final Color chipColor;
  final Color chipTextColor;
  final IconData? trailingIcon;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onTrailingIconPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final serene = theme.extension<SereneTheme>()!;

    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(serene.spacing.lg),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            borderRadius: serene.radius.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: serene.spacing.md,
                      vertical: serene.spacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: chipColor,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      timeLabel,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: chipTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (trailingIcon != null)
                    IconButton(
                      onPressed: onTrailingIconPressed,
                      icon: Icon(trailingIcon, size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: theme.colorScheme.surfaceContainerHigh,
                        foregroundColor: theme.colorScheme.onSurface,
                      ),
                    ),
                ],
              ),
              SizedBox(height: serene.spacing.sm),
              Text(title, style: theme.textTheme.titleMedium),
              SizedBox(height: serene.spacing.xs),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (primaryActionLabel != null && onPrimaryAction != null) ...[
                SizedBox(height: serene.spacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: GradientPrimaryButton(
                    label: primaryActionLabel!,
                    onPressed: onPrimaryAction,
                    icon:
                        Icons.check_circle_outline, // Optional based on design
                  ),
                ),
              ],
            ],
          ),
        ),
        if (isFocus)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(serene.radius.lg.topLeft.x),
                  bottomLeft: Radius.circular(serene.radius.lg.bottomLeft.x),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
