import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_pills/app/providers.dart';
import 'package:my_pills/app/router.dart';
import 'package:my_pills/core/theme/serene_theme.dart';
import 'package:my_pills/features/greetings/config/personal_config.dart';
import 'package:my_pills/features/greetings/data/greeting_gate.dart';
import 'package:my_pills/features/greetings/presentation/providers/greetings_providers.dart';
import 'package:my_pills/features/profile/presentation/providers/profile_providers.dart';
import 'package:my_pills/l10n/app_localizations.dart';

class GreetingScreen extends ConsumerStatefulWidget {
  const GreetingScreen({super.key});

  @override
  ConsumerState<GreetingScreen> createState() => _GreetingScreenState();
}

class _GreetingScreenState extends ConsumerState<GreetingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLeaving = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _leaveToApp() {
    setState(() => _isLeaving = true);
    unawaited(
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        final prefs = ref.read(sharedPreferencesProvider);
        GreetingGate.markSeen(prefs);
        context.go(AppRoutes.today);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final serene = theme.extension<SereneTheme>()!;
    final quoteAsync = ref.watch(todayQuoteProvider);

    final hour = DateTime.now().hour;
    final salutation = switch (hour) {
      < 12 => l10n.homeGreetingMorning,
      < 19 => l10n.homeGreetingAfternoon,
      _ => l10n.homeGreetingEvening,
    };

    final profile = ref.watch(currentUserProfileProvider);
    final greetingText = profile?.name != null
        ? '$salutation, ${profile!.name}'
        : salutation;

    return Scaffold(
      body: AnimatedOpacity(
        opacity: _isLeaving ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInCubic,
        child: Stack(
          children: [
            // ── Background Image ───────────────────────────────────────────────
            Positioned.fill(
              child: Image.asset(
                'assets/images/greeting_bg.png',
                fit: BoxFit.cover,
              ).animate().fadeIn(duration: 800.ms),
            ),

            // ── Content ────────────────────────────────────────────────────────
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (page) {
                        setState(() => _currentPage = page);
                      },
                      children: [
                        // Page 1: Bienvenida
                        _GreetingCard(
                          icon: Icons.light_mode_rounded,
                          title: greetingText,
                          message: PersonalConfig.personalMessageLines.join(
                            ' ',
                          ),
                          buttonLabel: l10n.welcomeContinueButton,
                          onPressed: () {
                            if (_pageController.hasClients) {
                              unawaited(
                                _pageController.nextPage(
                                  duration: 400.ms,
                                  curve: Curves.easeOutCubic,
                                ),
                              );
                            }
                          },
                        ),

                        // Page 2: Mensaje de Superación (Daily Quote)
                        quoteAsync.when(
                          data: (quote) => _GreetingCard(
                            icon: Icons.auto_awesome_rounded,
                            title: l10n.welcomeQuoteOfTheDayLabel,
                            message:
                                '“${quote.text}”'
                                '${quote.author != null ? '\n\n— ${quote.author}' : ''}',
                            buttonLabel:
                                l10n.welcomeContinueButton, // Or "Comenzar"
                            isLastPage: true,
                            onPressed: _leaveToApp,
                          ),
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (_, __) => _GreetingCard(
                            icon: Icons.error_outline_rounded,
                            title: 'Ups!',
                            message:
                                'No pudimos cargar tu mensaje de hoy, '
                                'pero igual será un gran día.',
                            buttonLabel: l10n.welcomeContinueButton,
                            isLastPage: true,
                            onPressed: _leaveToApp,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Page Indicators ──────────────────────────────────────────
                  Padding(
                    padding: EdgeInsets.only(bottom: serene.spacing.xl),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(2, (index) {
                        return AnimatedContainer(
                          duration: 300.ms,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 8,
                          width: _currentPage == index ? 24 : 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? theme.colorScheme.primary
                                : theme.colorScheme.primary.withValues(
                                    alpha: 0.3,
                                  ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
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

class _GreetingCard extends StatelessWidget {
  const _GreetingCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.onPressed,
    this.isLastPage = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final String buttonLabel;
  final VoidCallback onPressed;
  final bool isLastPage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final serene = theme.extension<SereneTheme>()!;

    return Center(
      child:
          Container(
                margin: EdgeInsets.symmetric(horizontal: serene.spacing.xxl),
                padding: EdgeInsets.all(serene.spacing.xxl),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLowest,
                  borderRadius: serene.radius.lg,
                  boxShadow: serene.ambientShadow,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon
                    Container(
                      padding: EdgeInsets.all(serene.spacing.lg),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: theme.colorScheme.onPrimary,
                        size: 32,
                      ),
                    ),
                    SizedBox(height: serene.spacing.xl),

                    // Title
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: serene.spacing.md),

                    // Divider
                    Container(
                      height: 1,
                      width: 40,
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.3,
                      ),
                    ),
                    SizedBox(height: serene.spacing.xl),

                    // Message
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                    SizedBox(height: serene.spacing.xxl),

                    // Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              theme.colorScheme.surfaceContainerLowest,
                          foregroundColor: theme.colorScheme.primary,
                          elevation: 2,
                          shadowColor: theme.colorScheme.primary.withValues(
                            alpha: 0.1,
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: serene.spacing.lg,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: serene.radius.xl,
                            side: BorderSide(
                              color: theme.colorScheme.outlineVariant
                                  .withValues(
                                    alpha: 0.2,
                                  ),
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              buttonLabel,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.1,
                              ),
                            ),
                            SizedBox(width: serene.spacing.sm),
                            Icon(
                              isLastPage
                                  ? Icons.check_rounded
                                  : Icons.arrow_forward_rounded,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
              .animate()
              .fadeIn(duration: 400.ms)
              .scale(
                begin: const Offset(0.95, 0.95),
                curve: Curves.easeOutCubic,
              ),
    );
  }
}
