import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:my_pills/core/theme/app_colors.dart';
import 'package:my_pills/core/theme/serene_theme.dart';

/// Single source of truth for [ThemeData].
///
/// Usage:
/// ```dart
/// MaterialApp.router(theme: AppTheme.light(), ...)
/// ```
///
/// Non-standard tokens (glass, gradient, shadows, spacing, radius) live on
/// [SereneTheme] and are accessed via
/// `Theme.of(context).extension<SereneTheme>()!`.
abstract final class AppTheme {
  /// Custom scroll behavior that enables mouse dragging on desktop platforms.
  /// Useful for testing mobile-like scrolling during development on Linux.
  static ScrollBehavior get scrollBehavior => const AppScrollBehavior();

  /// Returns the Serene Precision light theme.
  static ThemeData light() {
    final colorScheme = _buildColorScheme();
    final textTheme = _buildTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.background,
      // Disable default dividers — "No-Line" rule from DESIGN.md §2.
      dividerColor: Colors.transparent,
      dividerTheme: const DividerThemeData(color: Colors.transparent),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: SereneTheme.standard().radius.xl,
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(
          AppColors.outlineVariant.withValues(alpha: 0.4),
        ),
        thickness: WidgetStateProperty.all(4),
        radius: const Radius.circular(8),
        interactive: true,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceContainerLowest,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.onSurface,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: SereneTheme.standard().radius.lg,
          side: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.15),
          ),
        ),
        elevation: 4,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        actionTextColor: AppColors.primary,
      ),
      extensions: [SereneTheme.standard()],
    );
  }

  // ── ColorScheme ────────────────────────────────────────────────────────────

  static ColorScheme _buildColorScheme() => const ColorScheme(
    brightness: Brightness.light,
    // Primary
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.onPrimary,
    // Secondary (sage green = "taken")
    secondary: AppColors.secondary,
    onSecondary: AppColors.onPrimary,
    secondaryContainer: Color(0xFFB7F0D4),
    onSecondaryContainer: AppColors.onSecondaryContainer,
    // Tertiary (amber = pending/missed — never red for doses)
    tertiary: AppColors.tertiaryFixedDim,
    onTertiary: AppColors.onSurface,
    tertiaryContainer: Color(0xFFFFEAC7),
    onTertiaryContainer: AppColors.onSurface,
    // Error (reserved for actual system failures only)
    error: AppColors.error,
    onError: AppColors.onPrimary,
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: AppColors.error,
    // Surface
    surface: AppColors.background,
    onSurface: AppColors.onSurface,
    surfaceContainerLowest: AppColors.surfaceContainerLowest,
    surfaceContainerLow: AppColors.surfaceContainerLow,
    surfaceContainer: AppColors.surfaceContainer,
    onSurfaceVariant: AppColors.onSurfaceVariant,
    // Outline
    outline: AppColors.outlineVariant,
    outlineVariant: AppColors.outlineVariant,
  );

  // ── TextTheme (Manrope) ────────────────────────────────────────────────────

  /// Maps DESIGN.md §3 typography roles to Material 3 text styles.
  ///
  /// | DESIGN role  | Material slot   | Size | Weight |
  /// |---|---|---|---|
  /// | display-lg   | displayLarge    | 56   | 700    |
  /// | headline-md  | headlineMedium  | 28   | 600    |
  /// | title-lg     | titleLarge      | 22   | 500    |
  /// | body-lg      | bodyLarge       | 16   | 400    |
  /// | label-md     | labelMedium     | 12   | 600    |
  static TextTheme _buildTextTheme() => const TextTheme(
    displayLarge: TextStyle(
      fontFamily: 'Manrope',
      fontSize: 56,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      color: AppColors.onSurface,
    ),
    displayMedium: TextStyle(
      fontFamily: 'Manrope',
      fontSize: 45,
      fontWeight: FontWeight.w700,
    ),
    displaySmall: TextStyle(
      fontFamily: 'Manrope',
      fontSize: 36,
      fontWeight: FontWeight.w600,
    ),
    headlineLarge: TextStyle(
      fontFamily: 'Manrope',
      fontSize: 32,
      fontWeight: FontWeight.w600,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'Manrope',
      fontSize: 28,
      fontWeight: FontWeight.w600,
      color: AppColors.onSurface,
    ),
    headlineSmall: TextStyle(
      fontFamily: 'Manrope',
      fontSize: 24,
      fontWeight: FontWeight.w600,
    ),
    titleLarge: TextStyle(
      fontFamily: 'Manrope',
      fontSize: 22,
      fontWeight: FontWeight.w500,
      color: AppColors.onSurface,
    ),
    titleMedium: TextStyle(
      fontFamily: 'Manrope',
      fontSize: 16,
      fontWeight: FontWeight.w500,
    ),
    titleSmall: TextStyle(
      fontFamily: 'Manrope',
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    bodyLarge: TextStyle(
      fontFamily: 'Manrope',
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: AppColors.onSurface,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'Manrope',
      fontSize: 14,
      fontWeight: FontWeight.w400,
    ),
    bodySmall: TextStyle(
      fontFamily: 'Manrope',
      fontSize: 12,
      fontWeight: FontWeight.w400,
    ),
    labelLarge: TextStyle(
      fontFamily: 'Manrope',
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
    labelMedium: TextStyle(
      fontFamily: 'Manrope',
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
      color: AppColors.onSurfaceVariant,
    ),
    labelSmall: TextStyle(
      fontFamily: 'Manrope',
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
  );
}

/// A [MaterialScrollBehavior] that supports dragging with a mouse.
///
/// By default, Flutter desktop platforms only support scrolling via the mouse
/// wheel or trackpad. This behavior enables "click and drag" scrolling, which
/// is essential for testing the mobile experience on a desktop environment.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}
