# MyPills MVP — Implementation Plan

> Client-only Flutter MVP. Visual standard: see [`DESIGN.md`](./DESIGN.md). Source of truth for screens: Stitch project `4790005011651148693` ("MyPills Serene Precision").

## 1. Scope — Screens from Stitch

Visible screens in the Stitch project, mapped to MVP features:

| Stitch screen ID | Title | Role in MVP |
|---|---|---|
| `d2ed3a68…` | MyPills Medication Tracker | **Home** — today's doses, mark taken |
| `19dc8d13…` | Sistema de Taxonomía | Medication catalog / categories |
| `80592c0f…` | Scheduler: Daily (Unified) | Create schedule — daily cadence |
| `5e2736c5…` | Scheduler: Specific Days | Create schedule — day-of-week cadence |
| `32452d4e…` | Timeline Interactivo | Timeline across days |

Hidden screens in Stitch are alternates / component studies — ignored for MVP unless a gap emerges.

## 2. Domain Model

Three root entities drive every feature:

- **Medication** — `{ id, name, form (pill/capsule/liquid/…), category, colorToken, notes }`
- **Schedule** — sealed union of rule types:
  - `Daily({ timesOfDay, startDate, endDate? })`
  - `DailyInterval({ everyHours, startAt, endAt?, endDate? })`
  - `SpecificDays({ daysOfWeek, timesOfDay, startDate, endDate? })`
- **DoseEvent** — materialized occurrence: `{ id, medicationId, scheduleId, scheduledAt, status: pending|taken|missed, takenAt? }`

A **ScheduleExpander** is the engine that turns a `Schedule` rule into concrete `DoseEvent` rows for the next N days. Reconciled on app start and whenever schedules change.

.NET analogues:
- `Schedule` is a discriminated union (freezed sealed class ≈ `record` with case types).
- `ScheduleExpander` is the equivalent of an EF seeder materializing projections.
- `DoseEvent` is the read-side projection the UI subscribes to.

## 3. Phased Plan

### Phase 0 — Bootstrap & theme (~½ day)

- `flutter create` the project (org + package name).
- Wire deps in `pubspec.yaml`:
  - Runtime: `flutter_riverpod`, `riverpod_annotation`, `go_router`, `drift`, `drift_flutter`, `sqlite3_flutter_libs`, `path_provider`, `freezed_annotation`, `json_annotation`, `intl`, `flutter_localizations` (SDK).
  - Dev: `build_runner`, `riverpod_generator`, `drift_dev`, `freezed`, `json_serializable`, `very_good_analysis`, `mocktail`.
- Bundle Manrope under `assets/fonts/`; register in `pubspec.yaml`.
- `analysis_options.yaml` → `very_good_analysis`.
- Scaffold the `lib/` folders per AGENTS.md.
- Implement `core/theme/app_theme.dart` + `SereneTheme` extension per DESIGN.md §11.
- Set up i18n: `l10n.yaml` at repo root, `lib/l10n/app_es.arb` with seed strings, generated `AppLocalizations` wired into `MaterialApp.router`.
- `main.dart` → `ProviderScope` → `MaterialApp.router` (with `localizationsDelegates`, `supportedLocales: [Locale('es')]`, `locale: Locale('es')`).

Ask before touching `pubspec.yaml` (per AGENTS.md "ask before introducing a new dependency").

### Phase 1 — Core infrastructure (~½ day)

- `core/errors/failure.dart` — freezed sealed union (`NotFound`, `Conflict`, `Unexpected`, …).
- `core/result/result.dart` — `sealed Result<T, Failure>`.
- `core/db/app_database.dart` — Drift database, `MigrationStrategy`, file location via `path_provider`.
- `app/router.dart` — go_router with route placeholders.
- `app/providers.dart` — `databaseProvider`, `clockProvider` (for testability).

### Phase 2 — Domain layer (~1 day)

Feature by feature, entities + repository interfaces + use cases:

- `features/medications/domain/` — `Medication`, `MedicationRepository`, `AddMedication`, `ListMedications`.
- `features/schedules/domain/` — `Schedule` (sealed), `ScheduleRepository`, `CreateSchedule`.
- `features/tracker/domain/` — `DoseEvent`, `DoseEventRepository`, `GetTodayDoses`, `MarkDoseTaken`, `MarkDoseMissed`.
- `features/timeline/domain/` — `GetTimelineRange`.

All use cases return `Result<T, Failure>`.

### Phase 3 — Data layer (~1.5 days)

- Drift tables under each feature's `data/db/`:
  - `MedicationsTable`
  - `SchedulesTable` (rule stored as JSON + discriminator column)
  - `DoseEventsTable` (indexed by `scheduledAt`)
- DAOs exposing `Stream<T>` so UI is reactive.
- Repository impls: mappers row ↔ entity. **Drift types never leak past `data/`**.
- In-memory Drift wiring for tests.

### Phase 4 — Scheduler engine (~1 day)

- `features/schedules/domain/services/schedule_expander.dart` — pure function `Schedule → List<DoseEvent>` over a date window. Deterministic, timezone-aware (device zone for MVP, store UTC).
- `DoseReconciler` service: on app start and after schedule mutations, materializes the next **14 days** idempotently (upsert on `(scheduleId, scheduledAt)`).
- Heavy unit tests here — this is the risk hotspot (DST, month boundaries, every-N-hour wrap-around).

No push notifications in MVP. Flagged as a follow-up.

### Phase 5 — Presentation (~3 days)

Per screen workflow: pull the Stitch HTML via `mcp__stitch__get_screen`, identify layout + reusable widgets, build the Flutter equivalent with theme tokens, wire Riverpod providers, manually verify on emulator.

| Stitch screen | Flutter path |
|---|---|
| Medication Tracker | `features/tracker/presentation/tracker_screen.dart` |
| Taxonomía | `features/medications/presentation/taxonomy_screen.dart` |
| Scheduler Daily | `features/schedules/presentation/daily_scheduler_screen.dart` |
| Scheduler Specific Days | `features/schedules/presentation/specific_days_scheduler_screen.dart` |
| Timeline | `features/timeline/presentation/timeline_screen.dart` |

Shared widgets in `core/widgets/`:

- `GlassBottomNav`
- `GradientPrimaryButton`
- `PillCard`
- `StatusChip`
- `SoftInputField`

Navigation shell: `go_router` `StatefulShellRoute` with the glass bottom nav and three primary tabs — **Today / Medications / Timeline**. Scheduler flows are pushed modally.

### Phase 6 — Tests & polish (~1 day)

- Unit tests: `ScheduleExpander` (all rule types, DST edge cases), repository impls with in-memory Drift, mappers.
- Widget tests for the tracker screen (critical path only).
- `flutter analyze` clean, `dart format`, `flutter test` green.
- Manual device run.

## 4. Internationalization

**MVP ships Spanish (`es`) only**; architecture is multi-locale from day one.

- Localization assets under `lib/l10n/` as ARB files (`app_es.arb`, later `app_en.arb`, etc.).
- Generated via `flutter gen-l10n` — emits `AppLocalizations` class.
- `l10n.yaml` at repo root pins `arb-dir: lib/l10n`, `template-arb-file: app_es.arb`, `output-localization-file: app_localizations.dart`.
- Default locale: `es`. `supportedLocales` currently `[Locale('es')]`; adding a language = drop a new ARB + register the locale. No code rewrites.
- **Rule: no hardcoded user-facing strings.** Every label, button text, error message, empty-state copy goes through `AppLocalizations.of(context)`. Lint-friendly: plain string literals in widgets should be flagged in code review.
- Dates, times, numbers, plurals → `intl` package + ARB placeholders (`{count, plural, =0{...} one{...} other{...}}`).
- Domain/data layers may carry raw identifiers (e.g., `MedicationForm.capsule`) but never translated strings; the presentation layer maps enum → localized label.

Adding a second locale later is: (1) copy `app_es.arb` → `app_xx.arb`, translate, (2) add `Locale('xx')` to `supportedLocales`, (3) optionally expose a language picker provider. No schema or domain changes.

## 5. Estimate

~7–8 focused dev days solo.

## 6. Out of Scope for MVP

- Push/local notifications.
- Cloud sync or accounts.
- Medication interaction / drug database integrations.
- Dark mode (design system is light-only for now).
- Multi-profile / caregivers.
- Export / reporting.

These are parked as explicit follow-ups so scope creep is visible.

## 7. Definition of Done

Per AGENTS.md — a feature is done when:

1. Domain entities + use cases exist with tests.
2. Drift schema + repository impl with tests.
3. Riverpod providers expose state; screen consumes them.
4. `flutter analyze` clean, `dart format` applied, `flutter test` green.
5. Manually verified on a real/emulated device.
