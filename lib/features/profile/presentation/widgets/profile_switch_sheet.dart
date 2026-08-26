import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_pills/app/router.dart';
import 'package:my_pills/core/theme/serene_theme.dart';
import 'package:my_pills/core/widgets/app_avatar.dart';
import 'package:my_pills/features/profile/presentation/providers/profile_providers.dart';
import 'package:my_pills/features/profile/presentation/widgets/user_profile_form.dart';
import 'package:my_pills/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';

/// Shows the bottom sheet to switch between family / patient profiles.
Future<void> showProfileSwitchSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const ProfileSwitchSheet(),
  );
}

class ProfileSwitchSheet extends ConsumerWidget {
  const ProfileSwitchSheet({super.key});

  static const _uuid = Uuid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final serene = theme.extension<SereneTheme>()!;
    final l10n = AppLocalizations.of(context);
    final currentProfile = ref.watch(currentUserProfileProvider);
    final profiles = ref.watch(allProfilesProvider);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(serene.radius.xl.topLeft.x),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        serene.spacing.lg,
        serene.spacing.md,
        serene.spacing.lg,
        serene.spacing.xxl + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: serene.spacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Perfiles de Paciente',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          SizedBox(height: serene.spacing.xs),
          Text(
            'Selecciona el perfil para ver y gestionar sus medicamentos y dosis:',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: serene.spacing.md),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: profiles.length,
              separatorBuilder: (_, __) => SizedBox(height: serene.spacing.xs),
              itemBuilder: (context, index) {
                final p = profiles[index];
                final isSelected = p.id == currentProfile?.id;

                return InkWell(
                  onTap: () async {
                    await ref
                        .read(currentUserProfileProvider.notifier)
                        .switchProfile(p.id);
                    if (context.mounted) Navigator.pop(context);
                  },
                  borderRadius: serene.radius.lg,
                  child: Container(
                    padding: EdgeInsets.all(serene.spacing.md),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primaryContainer.withValues(
                              alpha: 0.3,
                            )
                          : theme.colorScheme.surfaceContainerLow,
                      borderRadius: serene.radius.lg,
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant.withValues(
                                alpha: 0.2,
                              ),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        AppAvatar(
                          photoPath: p.photoPath,
                          radius: 22,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          foregroundColor: theme.colorScheme.primary,
                        ),
                        SizedBox(width: serene.spacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                '${p.age} años · ${p.gender == "male" ? "Masculino" : (p.gender == "female" ? "Femenino" : "Otro")}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle_rounded,
                            color: theme.colorScheme.primary,
                          )
                        else
                          Icon(
                            Icons.radio_button_unchecked_rounded,
                            color: theme.colorScheme.outlineVariant,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: serene.spacing.lg),
          // Action Buttons: Add profile & Edit current
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    context.push(AppRoutes.editProfile);
                  },
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Editar actual'),
                ),
              ),
              SizedBox(width: serene.spacing.sm),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _openAddProfileModal(context, ref, l10n),
                  icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                  label: const Text('Nuevo perfil'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openAddProfileModal(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    Navigator.pop(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final serene = theme.extension<SereneTheme>()!;
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(serene.radius.xl.topLeft.x),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            serene.spacing.lg,
            serene.spacing.lg,
            serene.spacing.lg,
            serene.spacing.xxl + MediaQuery.paddingOf(ctx).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Agregar Perfil',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              SizedBox(height: serene.spacing.md),
              UserProfileForm(
                submitLabel: 'Crear Perfil',
                onSubmit: (profile) async {
                  final newProfile = profile.copyWith(id: _uuid.v4());
                  await ref
                      .read(currentUserProfileProvider.notifier)
                      .addProfile(newProfile);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
