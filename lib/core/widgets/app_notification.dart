import 'package:flutter/material.dart';

import 'package:my_pills/core/theme/serene_theme.dart';

/// Semantic tone for in-app floating notifications.
enum AppNotificationTone {
  /// Sage green tone — success, completion, "taken" confirmation.
  success,

  /// Amber tone — warning, pending, reminder.
  warning,

  /// Red tone — true system errors only (never for missed doses).
  error,

  /// Authoritative Indigo tone — neutral information, updates.
  info,
}

/// Floating in-app notification component and helper adhering to
/// Serene Precision (DESIGN.md).
///
/// Replaces the default Flutter fixed black SnackBar with a floating,
/// rounded, elevated card with tonal depth, icon, and clear typography.
class AppNotification extends StatelessWidget {
  const AppNotification({
    required this.message,
    this.tone = AppNotificationTone.info,
    this.icon,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String message;
  final AppNotificationTone tone;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Creates a styled [SnackBar] for use with [ScaffoldMessenger].
  static SnackBar createSnackBar({
    required BuildContext context,
    required String message,
    AppNotificationTone tone = AppNotificationTone.info,
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    final serene =
        Theme.of(context).extension<SereneTheme>() ?? SereneTheme.standard();
    return SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      padding: EdgeInsets.zero,
      margin: EdgeInsets.fromLTRB(
        serene.spacing.lg,
        0,
        serene.spacing.lg,
        serene.spacing.lg,
      ),
      duration: duration,
      dismissDirection: DismissDirection.horizontal,
      content: AppNotification(
        message: message,
        tone: tone,
        icon: icon,
        actionLabel: actionLabel,
        onAction: onAction,
      ),
    );
  }

  /// Shows a notification using [ScaffoldMessenger.of(context)].
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> show(
    BuildContext context,
    String message, {
    AppNotificationTone tone = AppNotificationTone.info,
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) =>
      showWithMessenger(
        ScaffoldMessenger.of(context),
        context: context,
        message: message,
        tone: tone,
        icon: icon,
        actionLabel: actionLabel,
        onAction: onAction,
        duration: duration,
      );

  /// Shows a success notification (Sage green).
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSuccess(
    BuildContext context,
    String message, {
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) =>
      show(
        context,
        message,
        tone: AppNotificationTone.success,
        icon: icon,
        actionLabel: actionLabel,
        onAction: onAction,
        duration: duration,
      );

  /// Shows an error notification (Red — system failures only).
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showError(
    BuildContext context,
    String message, {
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) =>
      show(
        context,
        message,
        tone: AppNotificationTone.error,
        icon: icon,
        actionLabel: actionLabel,
        onAction: onAction,
        duration: duration,
      );

  /// Shows a warning / pending notification (Amber).
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showWarning(
    BuildContext context,
    String message, {
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) =>
      show(
        context,
        message,
        tone: AppNotificationTone.warning,
        icon: icon,
        actionLabel: actionLabel,
        onAction: onAction,
        duration: duration,
      );

  /// Shows an informative notification (Indigo).
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showInfo(
    BuildContext context,
    String message, {
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) =>
      show(
        context,
        message,
        icon: icon,
        actionLabel: actionLabel,
        onAction: onAction,
        duration: duration,
      );

  /// Shows a notification with an explicit [ScaffoldMessengerState].
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason>
      showWithMessenger(
    ScaffoldMessengerState messenger, {
    required BuildContext context,
    required String message,
    AppNotificationTone tone = AppNotificationTone.info,
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    messenger.hideCurrentSnackBar();
    return messenger.showSnackBar(
      createSnackBar(
        context: context,
        message: message,
        tone: tone,
        icon: icon,
        actionLabel: actionLabel,
        onAction: onAction,
        duration: duration,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final serene = theme.extension<SereneTheme>() ?? SereneTheme.standard();
    final scheme = theme.colorScheme;
    final (toneColor, toneBg, defaultIcon) = _toneStyles(scheme);
    final effectiveIcon = icon ?? defaultIcon;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: serene.radius.lg,
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.15),
        ),
        boxShadow: serene.ambientShadow,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: serene.spacing.md,
        vertical: serene.spacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: toneBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              effectiveIcon,
              size: 20,
              color: toneColor,
            ),
          ),
          SizedBox(width: serene.spacing.md),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            SizedBox(width: serene.spacing.xs),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                onAction!();
              },
              style: TextButton.styleFrom(
                foregroundColor: scheme.primary,
                padding: EdgeInsets.symmetric(
                  horizontal: serene.spacing.sm,
                  vertical: serene.spacing.xs,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }

  (Color, Color, IconData) _toneStyles(ColorScheme scheme) {
    return switch (tone) {
      AppNotificationTone.success => (
        scheme.secondary,
        scheme.secondary.withValues(alpha: 0.12),
        Icons.check_circle_rounded,
      ),
      AppNotificationTone.warning => (
        scheme.onTertiaryContainer,
        scheme.tertiary.withValues(alpha: 0.25),
        Icons.warning_amber_rounded,
      ),
      AppNotificationTone.error => (
        scheme.error,
        scheme.errorContainer,
        Icons.error_outline_rounded,
      ),
      AppNotificationTone.info => (
        scheme.primary,
        scheme.primary.withValues(alpha: 0.10),
        Icons.info_outline_rounded,
      ),
    };
  }
}

/// Extension on [BuildContext] for convenient notification presentation.
extension AppNotificationContextExtension on BuildContext {
  /// Shows a Serene floating success notification.
  void showSuccessNotification(
    String message, {
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) => AppNotification.showSuccess(
    this,
    message,
    icon: icon,
    actionLabel: actionLabel,
    onAction: onAction,
    duration: duration,
  );

  /// Shows a Serene floating error notification.
  void showErrorNotification(
    String message, {
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) => AppNotification.showError(
    this,
    message,
    icon: icon,
    actionLabel: actionLabel,
    onAction: onAction,
    duration: duration,
  );

  /// Shows a Serene floating warning notification.
  void showWarningNotification(
    String message, {
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) => AppNotification.showWarning(
    this,
    message,
    icon: icon,
    actionLabel: actionLabel,
    onAction: onAction,
    duration: duration,
  );

  /// Shows a Serene floating info notification.
  void showInfoNotification(
    String message, {
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) => AppNotification.showInfo(
    this,
    message,
    icon: icon,
    actionLabel: actionLabel,
    onAction: onAction,
    duration: duration,
  );
}
