import 'package:flutter/material.dart';
import 'package:my_pills/core/theme/serene_theme.dart';
import 'package:my_pills/core/widgets/app_avatar.dart';
import 'package:my_pills/features/profile/domain/entities/user_profile.dart';

/// Serene Profile Selector Field.
/// Allows selecting which patient/family profile a medication reminder belongs to.
class ProfileSelectorField extends StatelessWidget {
  const ProfileSelectorField({
    required this.selectedProfileId,
    required this.profiles,
    required this.onSelected,
    super.key,
  });

  final String? selectedProfileId;
  final List<UserProfile> profiles;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final serene = theme.extension<SereneTheme>()!;
    final effectiveSelectedId =
        selectedProfileId ??
        (profiles.isNotEmpty ? profiles.first.id : 'default');

    if (profiles.isEmpty) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: profiles
            .map((profile) {
              final isSelected = profile.id == effectiveSelectedId;
              return Padding(
                padding: EdgeInsets.only(right: serene.spacing.sm),
                child: InkWell(
                  onTap: () => onSelected(profile.id),
                  borderRadius: serene.radius.full,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    padding: EdgeInsets.symmetric(
                      horizontal: serene.spacing.md,
                      vertical: serene.spacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primaryContainer.withValues(
                              alpha: 0.35,
                            )
                          : theme.colorScheme.surfaceContainerLowest,
                      borderRadius: serene.radius.full,
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant.withValues(
                                alpha: 0.4,
                              ),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.12,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppAvatar(
                          photoPath: profile.photoPath,
                          radius: 12,
                          fallbackIconSize: 14,
                          backgroundColor: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surfaceContainerHigh,
                          foregroundColor: isSelected
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        SizedBox(width: serene.spacing.sm),
                        Text(
                          profile.name.isNotEmpty ? profile.name : 'Usuario',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                        if (isSelected) ...[
                          SizedBox(width: serene.spacing.xs),
                          Icon(
                            Icons.check_circle_rounded,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}
