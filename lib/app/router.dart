import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:my_pills/app/providers.dart';
import 'package:my_pills/core/widgets/glass_bottom_nav.dart';
import 'package:my_pills/features/greetings/data/greeting_gate.dart';
import 'package:my_pills/features/greetings/presentation/screens/greeting_screen.dart';
import 'package:my_pills/features/medications/domain/entities/medication.dart';
import 'package:my_pills/features/medications/presentation/add_medication_screen.dart';
import 'package:my_pills/features/medications/presentation/medication_detail_screen.dart';
import 'package:my_pills/features/medications/presentation/medication_list_screen.dart';
import 'package:my_pills/features/medications/presentation/taxonomy_screen.dart';
import 'package:my_pills/features/schedules/presentation/daily_scheduler_screen.dart';
import 'package:my_pills/features/schedules/presentation/specific_days_scheduler_screen.dart';
import 'package:my_pills/features/profile/presentation/edit_profile_screen.dart';
import 'package:my_pills/features/profile/presentation/onboarding_screen.dart';
import 'package:my_pills/features/profile/presentation/providers/profile_providers.dart';
import 'package:my_pills/features/settings/presentation/settings_screen.dart';
import 'package:my_pills/features/splash/presentation/splash_screen.dart';
import 'package:my_pills/features/tracker/presentation/tracker_screen.dart';
import 'package:my_pills/l10n/app_localizations.dart';

/// Global key for the root [Navigator]. Used by widgets mounted in
/// `MaterialApp.builder` (which sit above the Navigator) to reach into the
/// router's [OverlayState] — e.g. the in-app reminder banner.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'rootNavigator',
);

/// Application-wide route configuration.
///
/// Uses [StatefulShellRoute] for the three primary tabs (Timeline, Medicamentos,
/// Categorías) and modal [GoRoute]s for scheduler flows.
///
/// .NET analogy: this is similar to `app.MapGet(...)` in ASP.NET Core minimal
/// APIs, but declarative and driven by [GoRouter].
final router = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: AppRoutes.splash,
  redirect: (context, state) {
    if (state.matchedLocation == AppRoutes.splash) return null;
    if (state.matchedLocation == AppRoutes.welcome) return null;

    // Only intercept the post-splash pivot — all other in-app routes
    // navigate freely and must not be redirected back to today.
    if (state.matchedLocation != AppRoutes.postSplash) return null;

    final container = ProviderScope.containerOf(context);
    final profileRepo = container.read(userProfileRepositoryProvider);

    if (!profileRepo.isOnboardingComplete()) {
      return AppRoutes.onboarding;
    }

    final prefs = container.read(sharedPreferencesProvider);
    return GreetingGate.shouldShow(prefs) ? AppRoutes.welcome : AppRoutes.today;
  },
  routes: [
    // ── Splash ───────────────────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.splash,
      name: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    // ── Post-splash virtual pivot (always redirected by GoRouter) ────────────
    GoRoute(
      path: AppRoutes.postSplash,
      name: AppRoutes.postSplash,
      builder: (context, state) => const SizedBox.shrink(),
    ),
    // ── Daily greeting ───────────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.welcome,
      name: AppRoutes.welcome,
      pageBuilder: (context, state) => _buildFadePage(
        key: state.pageKey,
        child: const GreetingScreen(),
      ),
    ),
    // ── Onboarding ───────────────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.onboarding,
      name: AppRoutes.onboarding,
      pageBuilder: (context, state) => _buildFadePage(
        key: state.pageKey,
        child: const OnboardingScreen(),
      ),
    ),
    // ── Edit Profile ─────────────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.editProfile,
      name: AppRoutes.editProfile,
      pageBuilder: (context, state) => const MaterialPage(
        fullscreenDialog: true,
        child: EditProfileScreen(),
      ),
    ),
    // ── Primary tab shell ────────────────────────────────────────────────────
    StatefulShellRoute.indexedStack(
      pageBuilder: (context, state, navigationShell) => _buildFadePage(
        key: state.pageKey,
        child: _ScaffoldWithNavBar(navigationShell: navigationShell),
      ),
      branches: [
        // Timeline (tracker screen)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.today,
              name: AppRoutes.today,
              builder: (context, state) => const TrackerScreen(),
            ),
          ],
        ),
        // Medicamentos (medication list + add/edit)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.medications,
              name: AppRoutes.medications,
              builder: (context, state) => const MedicationListScreen(),
            ),
          ],
        ),
        // Categorías (taxonomy)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.categories,
              name: AppRoutes.categories,
              builder: (context, state) => const TaxonomyScreen(),
            ),
          ],
        ),
      ],
    ),

    // ── Add medication (create mode) ─────────────────────────────────────────
    GoRoute(
      path: AppRoutes.addMedication,
      name: AppRoutes.addMedication,
      pageBuilder: (context, state) => const MaterialPage(
        fullscreenDialog: true,
        child: AddMedicationScreen(),
      ),
    ),

    // ── Edit medication ───────────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.editMedication,
      name: AppRoutes.editMedication,
      pageBuilder: (context, state) => MaterialPage(
        fullscreenDialog: true,
        child: AddMedicationScreen(
          medication: state.extra as Medication?,
        ),
      ),
    ),

    // ── Medication detail (schedules + info) ─────────────────────────────────
    GoRoute(
      path: AppRoutes.medicationDetail,
      name: AppRoutes.medicationDetail,
      pageBuilder: (context, state) => MaterialPage(
        child: MedicationDetailScreen(
          medication: state.extra! as Medication,
        ),
      ),
    ),

    // ── Modal scheduler flows ────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.schedulerDaily,
      name: AppRoutes.schedulerDaily,
      pageBuilder: (context, state) => MaterialPage(
        fullscreenDialog: true,
        child: DailySchedulerScreen(
          initialMedicationId: state.extra as int?,
        ),
      ),
    ),
    GoRoute(
      path: AppRoutes.schedulerSpecificDays,
      name: AppRoutes.schedulerSpecificDays,
      pageBuilder: (context, state) => MaterialPage(
        fullscreenDialog: true,
        child: SpecificDaysSchedulerScreen(
          initialMedicationId: state.extra as int?,
        ),
      ),
    ),
    // ── Settings ─────────────────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.settings,
      name: AppRoutes.settings,
      pageBuilder: (context, state) => const MaterialPage(
        fullscreenDialog: true,
        child: SettingsScreen(),
      ),
    ),
  ],
);

CustomTransitionPage<void> _buildFadePage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 450),
    reverseTransitionDuration: const Duration(milliseconds: 350),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fade = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      final scale = Tween<double>(begin: 0.96, end: 1).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
      );
      return FadeTransition(
        opacity: fade,
        child: ScaleTransition(scale: scale, child: child),
      );
    },
  );
}

/// Typed route constants. Use these instead of raw string paths.
abstract final class AppRoutes {
  static const String splash = '/splash';
  static const String postSplash = '/post-splash';
  static const String welcome = '/welcome';
  static const String today = '/';
  static const String medications = '/medications';
  static const String categories = '/categories';
  static const String addMedication = '/medications/add';
  static const String editMedication = '/medications/edit';
  static const String medicationDetail = '/medications/detail';
  static const String schedulerDaily = '/schedule/daily';
  static const String schedulerSpecificDays = '/schedule/specific-days';
  static const String onboarding = '/onboarding';
  static const String editProfile = '/profile/edit';
  static const String settings = '/settings';
}

class _ScaffoldWithNavBar extends StatelessWidget {
  const _ScaffoldWithNavBar({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      extendBody: true,
      body: navigationShell,
      floatingActionButton: switch (navigationShell.currentIndex) {
        // Timeline tab: add new schedule
        0 => FloatingActionButton(
          onPressed: () => context.push(AppRoutes.schedulerDaily),
          child: const Icon(Icons.add),
        ),
        // Medicamentos tab: add new medication
        1 => FloatingActionButton(
          onPressed: () => context.push(AppRoutes.addMedication),
          child: const Icon(Icons.add),
        ),
        _ => null,
      },
      bottomNavigationBar: GlassBottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: navigationShell.goBranch,
        items: [
          (
            icon: Icons.event_note_outlined,
            selectedIcon: Icons.event_note,
            label: l10n.navToday,
          ),
          (
            icon: Icons.medication_outlined,
            selectedIcon: Icons.medication,
            label: l10n.navMedications,
          ),
          (
            icon: Icons.grid_view_outlined,
            selectedIcon: Icons.grid_view,
            label: l10n.navCategories,
          ),
        ],
      ),
    );
  }
}
