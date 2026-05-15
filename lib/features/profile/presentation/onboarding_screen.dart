import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_pills/app/router.dart';
import 'package:my_pills/core/theme/serene_theme.dart';
import 'package:my_pills/features/notifications/presentation/onboarding_permission_flow.dart';
import 'package:my_pills/features/profile/domain/entities/user_profile.dart';
import 'package:my_pills/features/profile/presentation/providers/profile_providers.dart';
import 'package:my_pills/features/profile/presentation/widgets/user_profile_form.dart';
import 'package:my_pills/l10n/app_localizations.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final serene = theme.extension<SereneTheme>()!;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                serene.spacing.xxl,
                serene.spacing.xxl,
                serene.spacing.xxl,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.onboardingTitle,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn().slideY(begin: -0.2),
                  SizedBox(height: serene.spacing.md),
                  Text(
                    l10n.onboardingSubtitle,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 100.ms),
                ],
              ),
            ),
            Expanded(
              child: UserProfileForm(
                submitLabel: l10n.onboardingStartButton,
                onSubmit: (profile) => _submit(context, ref, profile),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) async {
    await ref.read(currentUserProfileProvider.notifier).updateProfile(profile);
    await runOnboardingPermissionFlow(ref);
    if (context.mounted) {
      context.go(AppRoutes.welcome);
    }
  }
}
