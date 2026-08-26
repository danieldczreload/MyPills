import 'package:flutter/material.dart';
import 'package:my_pills/core/theme/serene_theme.dart';
import 'package:my_pills/core/widgets/app_avatar.dart';
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
    this.profileName,
    this.profilePhotoPath,
    this.category,
    this.formLabel,
    this.accentColor,
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
  final String? profileName;
  final String? profilePhotoPath;
  final String? category;
  final String? formLabel;
  final Color? accentColor;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onTrailingIconPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final serene = theme.extension<SereneTheme>()!;
    final effectiveAccent = accentColor ?? theme.colorScheme.primary;

    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(serene.spacing.lg),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            borderRadius: serene.radius.lg,
            boxShadow: [
              BoxShadow(
                color: effectiveAccent.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
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
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                SizedBox(height: serene.spacing.xs),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              SizedBox(height: serene.spacing.sm),
              // Category tag and Form chip
              Wrap(
                spacing: serene.spacing.xs,
                runSpacing: serene.spacing.xs,
                children: [
                  if (profileName != null && profileName!.isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: serene.spacing.sm,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer.withValues(
                          alpha: 0.45,
                        ),
                        borderRadius: serene.radius.full,
                        border: Border.all(
                          color: theme.colorScheme.secondary.withValues(
                            alpha: 0.3,
                          ),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppAvatar(
                            photoPath: profilePhotoPath,
                            radius: 7,
                            fallbackIconSize: 8,
                            fallbackIcon: Icons.person_rounded,
                            backgroundColor: theme.colorScheme.secondary,
                            foregroundColor: theme.colorScheme.onSecondary,
                          ),
                          SizedBox(width: serene.spacing.xs),
                          Text(
                            profileName!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.secondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (category != null && category!.isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: serene.spacing.sm,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: effectiveAccent.withValues(alpha: 0.12),
                        borderRadius: serene.radius.full,
                        border: Border.all(
                          color: effectiveAccent.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.label_outline_rounded,
                            size: 12,
                            color: effectiveAccent,
                          ),
                          SizedBox(width: serene.spacing.xs),
                          Text(
                            category!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: effectiveAccent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (formLabel != null && formLabel!.isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: serene.spacing.sm,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHigh,
                        borderRadius: serene.radius.full,
                      ),
                      child: Text(
                        formLabel!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              if (primaryActionLabel != null && onPrimaryAction != null) ...[
                SizedBox(height: serene.spacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: GradientPrimaryButton(
                    label: primaryActionLabel!,
                    onPressed: onPrimaryAction,
                    icon: Icons.check_circle_outline,
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
                color: effectiveAccent,
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
