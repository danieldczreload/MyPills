import 'package:flutter/material.dart';

/// All brand color tokens from DESIGN.md §2.
/// These values must stay in sync with the Stitch "Lumina Wellness" system.
/// Never reference raw hex values outside this file.
abstract final class AppColors {
  // ── Brand tokens ──────────────────────────────────────────────────────────

  /// Cloud White — canvas / app background.
  static const Color background = Color(0xFFF8FAFC);

  /// Authoritative Indigo — core actions, primary CTA.
  static const Color primary = Color(0xFF1F108E);

  /// Deep Indigo — trust accent / gradient end.
  static const Color primaryContainer = Color(0xFF3730A3);

  /// Text / icons that sit on primary surfaces.
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// Sage Green — health, success, "taken" state.
  static const Color secondary = Color(0xFF006C49);

  /// Text on soft-fill green chips.
  static const Color onSecondaryContainer = Color(0xFF00714D);

  /// Soft Amber — pending / missed (non-alarmist; never use red for doses).
  static const Color tertiaryFixedDim = Color(0xFFFFB95F);

  /// True system errors only — never for missed doses.
  static const Color error = Color(0xFFBA1A1A);

  // ── Surface hierarchy ─────────────────────────────────────────────────────

  /// Elevated floating cards.
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);

  /// Nested sections.
  static const Color surfaceContainerLow = Color(0xFFF2F4F6);

  /// Inputs, chips.
  static const Color surfaceContainer = Color(0xFFECEEF0);

  // ── Text & borders ────────────────────────────────────────────────────────

  /// Ghost borders (use at 15 % opacity only — DESIGN.md No-Line rule).
  static const Color outlineVariant = Color(0xFFC8C4D5);

  /// Default text.
  static const Color onSurface = Color(0xFF191C1E);

  /// Secondary text / metadata.
  static const Color onSurfaceVariant = Color(0xFF464553);
}
