# MyPills — Agent Instructions

Flutter MVP, client-only. Owner experienced in .NET, new to Flutter.
Favor idiomatic Flutter; anchor explanations to .NET equivalents
(Task→Future, EF Core→Drift, DI→Riverpod, record→freezed).

> **Visual standard:** consume tokens from `AppTheme`/`SereneTheme`
> defined in [`DESIGN.md`](./DESIGN.md) — never hard-code hex/px/font sizes.

## Stack

Flutter stable · Dart ≥ 3.3 · null-safety on

| Concern | Package |
|---------|---------|
| State | `flutter_riverpod` + `riverpod_generator` |
| Navigation | `go_router` |
| Local DB | `drift` |
| Models | `freezed` + `json_serializable` |
| Codegen | `build_runner` |
| Lints | `flutter_lints` + `very_good_analysis` |
| Tests | `flutter_test`, `mocktail` |

No `get_it` unless justified.

## Architecture

Clean Architecture: `presentation → domain ← data`.

```
lib/
  core/            utils, errors, Result, theme, AppDatabase
  features/<f>/
    data/          drift tables, DAOs, DTOs, repo impls
    domain/        entities (freezed), repo interfaces, use cases
    presentation/  widgets, screens, providers
  app/             routing, root widget, app-wide providers
  l10n/            ARB files (MVP ships `es`)
```

Rules:
- `domain` imports nothing from `data` or `presentation`.
- `presentation` calls use cases, not repositories.
- `data` implements `domain` interfaces; never leak Drift types past `data`.
- One feature folder when ≥ 2 files. One `AppDatabase` in `core/db/`.
- DAOs expose `Stream<T>` for reactive UI.

## Conventions

- Files `snake_case.dart` · Classes `PascalCase` · private `_`.
- Imports: `dart:` → `package:` → relative.
- Prefer `final`/`const`. Use records + patterns where simpler.
- Errors: `Result<T, Failure>` (sealed/freezed) from use cases — don't throw across layers.
- Widgets: small, `const`, `ConsumerWidget`/`HookConsumerWidget`. No `setState` except leaf widgets.
- All UI strings via `AppLocalizations.of(context)` (from `lib/l10n/*.arb`).

## Agent behavior

- Ask before adding a dependency or deviating from the stack.
- Run `dart run build_runner build --delete-conflicting-outputs` after freezed/riverpod/drift changes.
- Before touching UI, load [`DESIGN.md`](./DESIGN.md) — single source of truth for visual tokens.
- Keep PRs feature-scoped; don't refactor unrelated code.
- `flutter analyze` clean + `dart format` applied before considering work done.
