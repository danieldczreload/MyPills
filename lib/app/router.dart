import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Application-wide route configuration.
///
/// Route paths are defined as constants so they can be referenced safely from
/// anywhere in the codebase.  Screens are placeholder [Scaffold]s for now —
/// they will be replaced in Phase 5.
///
/// .NET analogy: this is similar to `app.MapGet(...)` in ASP.NET Core minimal
/// APIs, but declarative and driven by [GoRouter].
final router = GoRouter(
  initialLocation: AppRoutes.today,
  routes: [
    GoRoute(
      path: AppRoutes.today,
      name: AppRoutes.today,
      builder: (context, state) =>
          const _PlaceholderScreen(title: 'Hoy'),
    ),
    GoRoute(
      path: AppRoutes.medications,
      name: AppRoutes.medications,
      builder: (context, state) =>
          const _PlaceholderScreen(title: 'Medicamentos'),
    ),
    GoRoute(
      path: AppRoutes.timeline,
      name: AppRoutes.timeline,
      builder: (context, state) =>
          const _PlaceholderScreen(title: 'Historial'),
    ),
  ],
);

/// Typed route constants.  Use these instead of raw string paths.
abstract final class AppRoutes {
  static const String today = '/';
  static const String medications = '/medications';
  static const String timeline = '/timeline';
  static const String schedulerDaily = '/schedule/daily';
  static const String schedulerSpecificDays = '/schedule/specific-days';
}

/// Temporary placeholder screen used during Phase 0 bootstrap.
/// Replaced in Phase 5 with real screens.
class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(child: Text(title)),
      );
}
