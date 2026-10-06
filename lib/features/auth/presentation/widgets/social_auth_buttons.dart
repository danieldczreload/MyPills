import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_pills/core/auth/app_google_sign_in.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/core/theme/serene_theme.dart';
import 'package:my_pills/core/utils/log.dart';
import 'package:my_pills/core/widgets/app_notification.dart';
import 'package:my_pills/features/auth/data/id_token_claims.dart';
import 'package:my_pills/features/auth/domain/entities/auth_user.dart';
import 'package:my_pills/features/auth/presentation/providers/auth_providers.dart';
import 'package:my_pills/features/calendar_integration/presentation/google_calendar_link_messages.dart';
import 'package:my_pills/features/profile/presentation/providers/profile_providers.dart';
import 'package:my_pills/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// Serene 1-Tap Social Auth Buttons (Google & Microsoft).
class SocialAuthButtons extends ConsumerStatefulWidget {
  const SocialAuthButtons({
    required this.onSuccess,
    super.key,
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
        AppNotification.showError(
          context,
          l10n.loginErrorGoogle('idToken is null'),
        );
        return;
      }

      final claims = IdTokenClaims.tryParse(token);
      mlog(
        'mypills.auth',
        'Google account email=${account.email} '
            'displayName=${account.displayName} photoUrl=${account.photoUrl} '
            'jwtName=${claims?.name} jwtPicture=${claims?.picture}',
      );

      final result = await ref
          .read(authProvider.notifier)
          .loginWithGoogle(
            token,
            displayName: account.displayName ?? claims?.name,
            photoUrl: account.photoUrl ?? claims?.picture,
          );

      if (!mounted) return;

      switch (result) {
        case Success(:final value):
          await _linkCalendarAfterLogin(l10n, account.email);
          if (!mounted) return;
          setState(() => _isLoading = false);
          widget.onSuccess(value);
        case FailureResult(:final failure):
          setState(() => _isLoading = false);
          widget.onError?.call(failure.toString());
          AppNotification.showError(
            context,
            l10n.loginErrorGoogle(failure.toString()),
          );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      widget.onError?.call(e.toString());
      AppNotification.showError(
        context,
        l10n.loginErrorGoogle(e.toString()),
      );
    }
  }

  /// The session already exists. A declined Calendar grant does not undo it.
  Future<void> _linkCalendarAfterLogin(
    AppLocalizations l10n,
    String email,
  ) async {
    final profileId = ref.read(currentUserProfileProvider)?.id ?? '';
    final outcome = await linkGoogleCalendarForProfile(
      ref: ref,
      profileId: profileId,
      expectedEmail: email,
    );
    if (!mounted) return;
    final notice = googleCalendarLinkMessage(l10n, outcome);
    if (notice == null) return;
    AppNotification.showWarning(context, notice);
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
        AppNotification.showError(
          context,
          l10n.loginErrorMicrosoft(
            'No se pudo abrir el navegador para Microsoft',
          ),
        );
        return;
      }

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      widget.onError?.call(e.toString());
      AppNotification.showError(
        context,
        l10n.loginErrorMicrosoft(e.toString()),
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
