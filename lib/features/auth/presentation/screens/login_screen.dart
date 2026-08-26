import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_pills/app/providers.dart';
import 'package:my_pills/app/router.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/core/theme/app_colors.dart';
import 'package:my_pills/core/theme/serene_theme.dart';
import 'package:my_pills/features/auth/domain/entities/auth_user.dart';
import 'package:my_pills/features/auth/presentation/widgets/social_auth_buttons.dart';
import 'package:my_pills/features/profile/presentation/providers/profile_providers.dart';
import 'package:my_pills/l10n/app_localizations.dart';

/// Serene 1-Tap Login Screen for MyPills.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isProcessing = false;

  Future<void> _onAuthSuccess(AuthUser user) async {
    setState(() => _isProcessing = true);
    final syncEngine = ref.read(syncEngineProvider);

    // Check if user already has profiles on backend
    final restoreResult = await syncEngine.fetchAndRestoreProfiles();

    if (!mounted) return;
    setState(() => _isProcessing = false);

    final profileRepo = ref.read(userProfileRepositoryProvider);

    if (restoreResult is Success<String?> && restoreResult.value != null) {
      // Profile and data restored from backend! Invalidate reactive state
      ref.invalidate(currentUserProfileProvider);
      ref.invalidate(allProfilesProvider);
      ref.invalidate(medicationRepositoryProvider);
      ref.invalidate(scheduleRepositoryProvider);
      ref.invalidate(doseEventRepositoryProvider);
      ref.invalidate(watchMedicationsUseCaseProvider);
      ref.invalidate(watchTodayDosesUseCaseProvider);
      context.go(AppRoutes.welcome);
    } else if (profileRepo.isOnboardingComplete()) {
      ref.invalidate(currentUserProfileProvider);
      ref.invalidate(allProfilesProvider);
      context.go(AppRoutes.welcome);
    } else {
      // New user without profile -> go to onboarding
      context.go(AppRoutes.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final serene = theme.extension<SereneTheme>()!;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: serene.spacing.xl),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Logo with subtle glow
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: serene.radius.xl,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryContainer.withValues(
                            alpha: 0.15,
                          ),
                          blurRadius: 32,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: serene.radius.xl,
                      child: Image.asset(
                        'assets/images/app_logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8)),
                  SizedBox(height: serene.spacing.xl),

                  // Heading
                  Text(
                    l10n.loginTitle,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 100.ms),
                  SizedBox(height: serene.spacing.sm),

                  Text(
                    l10n.loginSubtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 150.ms),
                  SizedBox(height: serene.spacing.xxl),

                  if (_isProcessing)
                    Padding(
                      padding: EdgeInsets.all(serene.spacing.lg),
                      child: Column(
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(l10n.loginSyncingAccount),
                        ],
                      ),
                    )
                  else
                    // 1-Tap Social Buttons
                    SocialAuthButtons(
                      onSuccess: _onAuthSuccess,
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
