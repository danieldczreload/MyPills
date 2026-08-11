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

<!-- headroom:rtk-instructions -->
# RTK (Rust Token Killer) - Token-Optimized Commands

When running shell commands, **always prefix with `rtk`**. This reduces context
usage by 60-90% with zero behavior change. If rtk has no filter for a command,
it passes through unchanged — so it is always safe to use.

## Key Commands
```bash
# Git (59-80% savings)
rtk git status          rtk git diff            rtk git log

# Files & Search (60-75% savings)
rtk ls <path>           rtk read <file>         rtk grep <pattern>
rtk find <pattern>      rtk diff <file>

# Test (90-99% savings) — shows failures only
rtk pytest tests/       rtk cargo test          rtk test <cmd>

# Build & Lint (80-90% savings) — shows errors only
rtk tsc                 rtk lint                rtk cargo build
rtk prettier --check    rtk mypy                rtk ruff check

# Analysis (70-90% savings)
rtk err <cmd>           rtk log <file>          rtk json <file>
rtk summary <cmd>       rtk deps                rtk env

# GitHub (26-87% savings)
rtk gh pr view <n>      rtk gh run list         rtk gh issue list

# Package managers (70-90% savings)
rtk pip list            rtk pnpm install        rtk npm run <script>
```
<!-- /headroom:rtk-instructions -->

<!-- headroom:memory-instructions -->
## Memory Guidance
Use the `headroom_memory` MCP server for persistent cross-session knowledge.
- **Before** answering questions about prior decisions or architecture — call `memory_search` first.
- **After** making durable decisions or discovering conventions — call `memory_save` to persist them.
