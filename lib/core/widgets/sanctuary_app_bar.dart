import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_pills/app/router.dart';
import 'package:my_pills/core/widgets/app_avatar.dart';
import 'package:my_pills/features/profile/presentation/providers/profile_providers.dart';
import 'package:my_pills/features/profile/presentation/widgets/profile_switch_sheet.dart';
import 'package:my_pills/l10n/app_localizations.dart';

/// Standardized frosted-glass AppBar used across all screens.
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
              onTap: () => showProfileSwitchSheet(context),
              child: Row(
                children: [
                  AppAvatar(
                    photoPath: profile?.photoPath,
                    radius: 20,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      profile?.name ?? l10n.appTitle,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.unfold_more_rounded,
                    size: 18,
                    color: theme.colorScheme.primary.withValues(alpha: 0.7),
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
