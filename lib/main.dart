import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:my_pills/app/router.dart';
import 'package:my_pills/core/theme/app_theme.dart';
import 'package:my_pills/l10n/app_localizations.dart';

void main() {
  runApp(
    // ProviderScope is the Riverpod equivalent of registering services in
    // ASP.NET Core's DI container — all providers are available beneath it.
    const ProviderScope(
      child: MyPillsApp(),
    ),
  );
}

/// Root application widget.
///
/// Wires together:
/// - [AppTheme.light] — Serene Precision design tokens
/// - [AppLocalizations] — Spanish (es) strings; multi-locale ready
/// - [router] — go_router declarative navigation
class MyPillsApp extends StatelessWidget {
  const MyPillsApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        // ── Theme ────────────────────────────────────────────────────────────
        theme: AppTheme.light(),
        debugShowCheckedModeBanner: false,

        // ── i18n ─────────────────────────────────────────────────────────────
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),

        // ── Navigation ───────────────────────────────────────────────────────
        routerConfig: router,
      );
}
