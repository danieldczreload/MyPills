import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_pills/app/router.dart';
import 'package:my_pills/features/profile/presentation/providers/profile_providers.dart';
import 'package:my_pills/l10n/app_localizations.dart';

/// Standardized frosted-glass AppBar used across all screens.
///
/// Implements the "Serene Precision" header pattern from DESIGN.md:
/// - Semi-transparent white surface with 20dp backdrop blur (glass surface token)
/// - 40×40 circular avatar (person icon placeholder)
/// - Bold primary-color brand title
/// - Notifications icon button on the trailing edge
///
/// Usage:
/// ```dart
/// Scaffold(
///   extendBodyBehindAppBar: true,
///   appBar: SanctuaryAppBar(),
/// )
/// ```
class SanctuaryAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const SanctuaryAppBar({this.title, this.onBack, super.key});

  final String? title;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final profile = ref.watch(currentUserProfileProvider);

    return AppBar(
      backgroundColor: Colors.white.withValues(alpha: 0.7),
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      leading: onBack != null
          ? IconButton(
              icon: Icon(Icons.arrow_back, color: theme.colorScheme.primary),
              onPressed: onBack,
            )
          : null,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(color: Colors.transparent),
        ),
      ),
      title: title != null
          ? Text(
              title!,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            )
          : GestureDetector(
              onTap: () => context.push(AppRoutes.editProfile),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: theme.colorScheme.surfaceContainerHigh,
                    backgroundImage: profile?.photoPath != null
                        ? FileImage(File(profile!.photoPath!))
                        : null,
                    child: profile?.photoPath == null
                        ? Icon(
                            Icons.person,
                            color: theme.colorScheme.onSurfaceVariant,
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    profile?.name ?? l10n.appTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
      actions: [
        if (title == null)
          IconButton(
            onPressed: () => context.push(AppRoutes.settings),
            icon: Icon(
              Icons.settings_outlined,
              color: theme.colorScheme.primary,
            ),
          ),
      ],
    );
  }
}
