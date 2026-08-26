import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_pills/core/auth/app_google_sign_in.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/core/theme/serene_theme.dart';
import 'package:my_pills/features/auth/domain/entities/auth_user.dart';
import 'package:my_pills/features/auth/presentation/providers/auth_providers.dart';
import 'package:my_pills/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// Serene 1-Tap Social Auth Buttons (Google & Microsoft).
class SocialAuthButtons extends ConsumerStatefulWidget {
  const SocialAuthButtons({
    super.key,
    required this.onSuccess,
    this.onError,
  });

  final void Function(AuthUser user) onSuccess;
  final void Function(String error)? onError;

  @override
  ConsumerState<SocialAuthButtons> createState() => _SocialAuthButtonsState();
}

class _SocialAuthButtonsState extends ConsumerState<SocialAuthButtons> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn(AppLocalizations l10n) async {
    setState(() => _isLoading = true);
    try {
      final googleSignIn = appGoogleSignIn;
      final account = await googleSignIn.signIn();

      if (account == null) {
        // User cancelled the Google sign-in dialog
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final auth = await account.authentication;
      var token = auth.idToken;
      if (token == null && kDebugMode) {
        // Local-dev bypass: the backend accepts `valid-<email>` tokens only
        // when it runs with APP_ENV=dev. Never used in release builds.
        token = 'valid-${account.email}';
      }

      if (token == null) {
        // Google could not mint an ID token: the serverClientId is missing or
        // is not a *Web application* OAuth client of the same Cloud project
        // (and/or the app SHA-1 is not registered there).
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.loginErrorGoogle('idToken is null')),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }

      final result = await ref
          .read(authProvider.notifier)
          .loginWithGoogle(
            token,
            displayName: account.displayName,
            photoUrl: account.photoUrl,
          );

      if (!mounted) return;
      setState(() => _isLoading = false);

      switch (result) {
        case Success(:final value):
          widget.onSuccess(value);
        case FailureResult(:final failure):
          widget.onError?.call(failure.toString());
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.loginErrorGoogle(failure.toString())),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      widget.onError?.call(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.loginErrorGoogle(e.toString())),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _handleMicrosoftSignIn(AppLocalizations l10n) async {
    setState(() => _isLoading = true);
    try {
      final msService = ref.read(microsoftAuthServiceProvider);
      final authUri = await msService.getAuthorizationUrl();

      final launched = await launchUrl(
        authUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.loginErrorMicrosoft(
                'No se pudo abrir el navegador para Microsoft',
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      widget.onError?.call(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.loginErrorMicrosoft(e.toString())),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final serene = theme.extension<SereneTheme>()!;
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(serene.spacing.lg),
          child: const CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Google 1-Tap Button
        ElevatedButton(
          onPressed: () => _handleGoogleSignIn(l10n),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.surfaceContainerLowest,
            foregroundColor: colorScheme.onSurface,
            elevation: 1,
            padding: EdgeInsets.symmetric(
              vertical: serene.spacing.md,
              horizontal: serene.spacing.lg,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: serene.radius.xl,
              side: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.g_mobiledata_rounded,
                size: 28,
                color: colorScheme.primary,
              ),
              SizedBox(width: serene.spacing.sm),
              Text(
                l10n.loginContinueGoogle,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: serene.spacing.md),

        // Microsoft Button
        ElevatedButton(
          onPressed: () => _handleMicrosoftSignIn(l10n),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.surfaceContainerLowest,
            foregroundColor: colorScheme.onSurface,
            elevation: 1,
            padding: EdgeInsets.symmetric(
              vertical: serene.spacing.md,
              horizontal: serene.spacing.lg,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: serene.radius.xl,
              side: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.grid_view_rounded,
                size: 22,
                color: colorScheme.secondary,
              ),
              SizedBox(width: serene.spacing.sm),
              Text(
                l10n.loginContinueMicrosoft,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
