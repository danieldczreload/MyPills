import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_pills/app/router.dart';
import 'package:my_pills/core/theme/app_colors.dart';
import 'package:my_pills/core/theme/serene_theme.dart';

/// Pantalla de presentación (splash) que se muestra al iniciar la app.
///
/// Flujo:
///   1. El logo aparece con fade-in + scale desde 0.7 → 1.0 (600 ms).
///   2. Un pulso suave de brillo (shimmer) durante ~1 s.
///   3. Fade-out de toda la pantalla (400 ms).
///   4. Navegación a [AppRoutes.welcome] (o [AppRoutes.today] si ya visto).
///
/// El router decide a dónde ir después; aquí solo orquestamos el timing.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Logo entrance ────────────────────────────────────────────────────────
  late final AnimationController _entryCtrl;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;

  // ── Shimmer pulse ────────────────────────────────────────────────────────
  late final AnimationController _shimmerCtrl;
  late final Animation<double> _shimmerOpacity;

  // ── Exit fade ────────────────────────────────────────────────────────────
  late final AnimationController _exitCtrl;
  late final Animation<double> _exitOpacity;

  // ── Tagline slide ────────────────────────────────────────────────────────
  late final Animation<Offset> _taglineSlide;
  late final Animation<double> _taglineOpacity;

  @override
  void initState() {
    super.initState();

    // Entry: 300 ms (DESIGN.md motion-medium token)
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _logoOpacity = CurvedAnimation(
      parent: _entryCtrl,
      curve: Curves.easeOutCubic,
    );
    _logoScale = Tween<double>(begin: 0.72, end: 1).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutBack),
    );
    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _taglineOpacity = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.4, 1, curve: Curves.easeOut),
    );

    // Shimmer pulse: single, 300 ms (DESIGN.md motion-medium token)
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _shimmerOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 0.35), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.35, end: 0), weight: 50),
    ]).animate(_shimmerCtrl);

    // Exit: 400 ms
    _exitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _exitOpacity = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _exitCtrl, curve: Curves.easeInCubic),
    );

    unawaited(_runSequence());
  }

  Future<void> _runSequence() async {
    // 1. Logo enters
    await _entryCtrl.forward();

    // 2. Single shimmer pulse
    await _shimmerCtrl.forward();

    // Small pause so the logo sits still before leaving
    await Future<void>.delayed(const Duration(milliseconds: 200));

    // 3. Fade out
    await _exitCtrl.forward();

    // 4. Navigate — the router redirect will evaluate welcome vs. today
    if (mounted) {
      context.go(AppRoutes.postSplash);
    }
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _shimmerCtrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final serene = Theme.of(context).extension<SereneTheme>()!;

    return AnimatedBuilder(
      animation: _exitOpacity,
      builder: (context, child) {
        return Opacity(
          opacity: _exitOpacity.value,
          child: child,
        );
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            // ── Subtle radial gradient background ───────────────────────────
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.25),
                    radius: 0.85,
                    colors: [
                      AppColors.primaryContainer.withValues(alpha: 0.09),
                      AppColors.background,
                    ],
                  ),
                ),
              ),
            ),

            // ── Decorative blurred circle top-left ──────────────────────────
            Positioned(
              top: -60,
              left: -40,
              child: _BlurCircle(
                size: 220,
                color: AppColors.primaryContainer.withValues(alpha: 0.12),
              ),
            ),

            // ── Decorative blurred circle bottom-right ──────────────────────
            Positioned(
              bottom: -50,
              right: -30,
              child: _BlurCircle(
                size: 180,
                color: const Color(0xFF10B981).withValues(alpha: 0.08),
              ),
            ),

            // ── Center content ───────────────────────────────────────────────
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo with scale + opacity entry + shimmer overlay
                  AnimatedBuilder(
                    animation: Listenable.merge([
                      _logoScale,
                      _logoOpacity,
                      _shimmerOpacity,
                    ]),
                    builder: (context, _) {
                      return Opacity(
                        opacity: _logoOpacity.value,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Logo card with soft shadow
                              Container(
                                width: 148,
                                height: 148,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerLowest,
                                  borderRadius: BorderRadius.circular(
                                    serene.radius.lg.topLeft.x,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryContainer
                                          .withValues(alpha: 0.18),
                                      blurRadius: 48,
                                      spreadRadius: 4,
                                      offset: const Offset(0, 12),
                                    ),
                                    BoxShadow(
                                      color: AppColors.primaryContainer
                                          .withValues(alpha: 0.06),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    serene.radius.lg.topLeft.x,
                                  ),
                                  child: Image.asset(
                                    'assets/images/app_logo.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),

                              // Shimmer pulse overlay
                              Container(
                                width: 148,
                                height: 148,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    serene.radius.lg.topLeft.x,
                                  ),
                                  gradient: RadialGradient(
                                    colors: [
                                      Colors.white.withValues(
                                        alpha: _shimmerOpacity.value,
                                      ),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  SizedBox(height: serene.spacing.xl),

                  // Tagline slides up after logo
                  SlideTransition(
                    position: _taglineSlide,
                    child: FadeTransition(
                      opacity: _taglineOpacity,
                      child: Column(
                        children: [
                          Text(
                            'MyPills',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                          ),
                          SizedBox(height: serene.spacing.xs),
                          Text(
                            'Tu salud, organizada.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppColors.onSurfaceVariant.withValues(
                                    alpha: 0.7,
                                  ),
                                  letterSpacing: 0.3,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Blurred decorative circle for depth/glassmorphism feel.
class _BlurCircle extends StatelessWidget {
  const _BlurCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
