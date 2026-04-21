import 'package:flutter/material.dart';

import 'package:my_pills/core/theme/app_colors.dart';

/// Non-standard design tokens that extend Material 3 but aren't part of
/// [ColorScheme] or [TextTheme] — glass surfaces, signature gradients,
/// ambient shadows, spacing scale, and radius scale.
///
/// Access from any widget with:
/// ```dart
/// final serene = Theme.of(context).extension<SereneTheme>()!;
/// ```
///
/// This is the Flutter analogue of a CSS design-token layer: consumers read
/// tokens, never hard-code px or hex.
class SereneTheme extends ThemeExtension<SereneTheme> {
  const SereneTheme({
    required this.glassOpacity,
    required this.glassBlur,
    required this.signatureGradient,
    required this.ambientShadow,
    required this.spacing,
    required this.radius,
  });

  /// Creates a [SereneTheme] with all required design tokens.
  factory SereneTheme.standard() => SereneTheme(
        glassOpacity: 0.70,
        glassBlur: 20,
        signatureGradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          transform: GradientRotation(135 * 3.14159 / 180),
          colors: [AppColors.primary, AppColors.primaryContainer],
        ),
        ambientShadow: [
          BoxShadow(
            color: AppColors.primaryContainer.withValues(alpha: 0.08),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
        spacing: const SpacingScale(),
        radius: const RadiusScale(),
      );

  // ── Glass surface ──────────────────────────────────────────────────────────

  /// Opacity applied to surfaceContainerLowest for glass layers (0.70).
  final double glassOpacity;

  /// Backdrop blur for glass surfaces (20 dp).
  final double glassBlur;

  // ── Signature gradient (hero CTAs only) ───────────────────────────────────

  /// Linear gradient from [AppColors.primary] → [AppColors.primaryContainer].
  final LinearGradient signatureGradient;

  // ── Ambient shadow ─────────────────────────────────────────────────────────

  /// Signature ambient shadow — tinted with [AppColors.primaryContainer].
  final List<BoxShadow> ambientShadow;

  // ── Spacing scale (4-px base) ─────────────────────────────────────────────

  /// Spacing tokens: xs=4, sm=8, md=12, lg=16, xl=24, xxl=32, …
  final SpacingScale spacing;

  // ── Radius scale ──────────────────────────────────────────────────────────

  /// Radius tokens: sm=8, md=16, lg=24, xl=32, full=9999
  final RadiusScale radius;

  // ── ThemeExtension boilerplate ────────────────────────────────────────────

  @override
  SereneTheme copyWith({
    double? glassOpacity,
    double? glassBlur,
    LinearGradient? signatureGradient,
    List<BoxShadow>? ambientShadow,
    SpacingScale? spacing,
    RadiusScale? radius,
  }) =>
      SereneTheme(
        glassOpacity: glassOpacity ?? this.glassOpacity,
        glassBlur: glassBlur ?? this.glassBlur,
        signatureGradient: signatureGradient ?? this.signatureGradient,
        ambientShadow: ambientShadow ?? this.ambientShadow,
        spacing: spacing ?? this.spacing,
        radius: radius ?? this.radius,
      );

  @override
  SereneTheme lerp(SereneTheme? other, double t) {
    if (other == null) return this;
    return SereneTheme(
      glassOpacity:
          _lerpDouble(glassOpacity, other.glassOpacity, t),
      glassBlur: _lerpDouble(glassBlur, other.glassBlur, t),
      signatureGradient: LinearGradient.lerp(
        signatureGradient,
        other.signatureGradient,
        t,
      )!,
      ambientShadow:
          BoxShadow.lerpList(ambientShadow, other.ambientShadow, t)!,
      spacing: spacing,
      radius: radius,
    );
  }

  static double _lerpDouble(double a, double b, double t) =>
      a + (b - a) * t;
}

// ── Spacing scale ────────────────────────────────────────────────────────────

/// xs=4, sm=8, md=12, lg=16, xl=24, xxl=32, xxxl=48, xxxxl=64
/// (DESIGN.md §4)
class SpacingScale {
  const SpacingScale();

  /// 4 dp
  double get xs => 4;

  /// 8 dp
  double get sm => 8;

  /// 12 dp
  double get md => 12;

  /// 16 dp
  double get lg => 16;

  /// 24 dp
  double get xl => 24;

  /// 32 dp
  double get xxl => 32;

  /// 48 dp
  double get xxxl => 48;

  /// 64 dp
  double get xxxxl => 64;

  /// Default card internal padding (24 dp — DESIGN.md §6).
  double get cardPadding => xl;
}

// ── Radius scale ─────────────────────────────────────────────────────────────

/// sm=8, md=16, lg=24, xl=32, full=9999  (DESIGN.md §4)
class RadiusScale {
  const RadiusScale();

  /// 8 dp — minimum for any interactive element.
  BorderRadius get sm => BorderRadius.circular(8);

  /// 16 dp
  BorderRadius get md => BorderRadius.circular(16);

  /// 24 dp — cards.
  BorderRadius get lg => BorderRadius.circular(24);

  /// 32 dp — primary buttons (near-pill shape).
  BorderRadius get xl => BorderRadius.circular(32);

  /// 9999 dp — fully rounded pill.
  BorderRadius get full => BorderRadius.circular(9999);

  /// Convenience [Radius] for use in [RoundedRectangleBorder] and similar.
  Radius get smRadius => const Radius.circular(8);

  /// 16 dp as [Radius].
  Radius get mdRadius => const Radius.circular(16);

  /// 24 dp as [Radius].
  Radius get lgRadius => const Radius.circular(24);

  /// 32 dp as [Radius].
  Radius get xlRadius => const Radius.circular(32);

  /// Full pill as [Radius].
  Radius get fullRadius => const Radius.circular(9999);
}
