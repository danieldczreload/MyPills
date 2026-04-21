# DESIGN.md — Serene Precision Design System

> Visual guidelines for **MyPills**. Token *values* (hex, dp, weights) live in
> code — see `lib/core/theme/`. This file defines **rules, philosophy, and
> component specs** that code alone cannot express.

## 0. How to Use This File

- Token values → `app_colors.dart`, `app_theme.dart`, `serene_theme.dart`.
- Do **not** invent new tokens; extend this file + code together.
- Implementation target: **Flutter + Material 3**.
- When a case isn't covered, defer to the **North Star** (§1).
- Mirrors the Stitch design system "Lumina Wellness". When Stitch and this file diverge, update this file and re-sync.

---

## 1. North Star — "The Digital Sanctuary"

Philosophy: **Serene Precision**. In a medication domain, the UI must be a calm, authoritative guide that minimizes cognitive load while radiating reliability.

Three operational principles:

1. **Intentional asymmetry** — white space is a *structural* element, not a gap.
2. **Tonal depth** — replace lines with layered sheets of color.
3. **Fluid micro-interactions** — transitions that feel like frosted glass, not rectangles snapping.

---

## 2. Color Rules

Token values → `AppColors` in `app_colors.dart`.

### The "No-Line" rule

1px solid borders are **forbidden** for sectioning. Separate regions only through a background shift (e.g., `background` → `surface_container_low`).

### Glass & gradient

- **Glass surface**: `surfaceContainerLowest` @ 70% opacity + 20px backdrop blur. Used for floating nav and modal sheets.
- **Signature gradient** (hero CTAs only): linear gradient `primary` → `primaryContainer` at 135°.

### Semantic color intent

- **Sage green** (`secondary`) = "taken" / health-goal-met. Never use for other statuses.
- **Amber** (`tertiaryFixedDim`) = pending / missed. Supportive, not alarmist.
- **Red** (`error`) = system failures only — **never** for missed doses.

---

## 3. Typography

Font: **Manrope** (humanist authority). Bundled locally under `assets/fonts/`. Do **not** fetch Google Fonts at runtime (determinism + offline).

Scale and weights → `_buildTextTheme()` in `app_theme.dart`.

---

## 4. Spacing & Radius

Values → `SpacingScale` and `RadiusScale` in `serene_theme.dart`.

### Radius assignment rules

- Cards → `lg` (24).
- Primary buttons → `xl` (32), close to pill shape.
- Any interactive element → **minimum `sm` (8)**. Sharper corners are forbidden.

---

## 5. Elevation & Depth

### Tonal layering (default — prefer over shadows)

1. Base: `background`
2. Section: `surfaceContainerLow`
3. Interactive card: `surfaceContainerLowest`

Use shadows only for **hero** elements that demand immediate focus.

Shadow values → `SereneTheme.standard()` in `serene_theme.dart`.

- Never pure black. Always tint with `primaryContainer`.
- Ghost border (accessibility fallback): `outlineVariant` at **15% opacity** — never higher.

---

## 6. Component Library

### Buttons — "Fluid Tap"

- **Primary**: `xl` radius, indigo gradient background, `onPrimary` text. On press: scale → 0.98, shadow diffuses.
- **Secondary (success/completion)**: sage-green @ 10% soft-fill, `onSecondaryContainer` text.
- **Tertiary (text)**: no background, `primary` text.

### Cards — Medicine Tracker

- Zero border. `surfaceContainerLowest`. Radius `lg`. Padding `cardPadding`.
- Imagery (pill icons) may **bleed off the right edge** — embrace asymmetry.

### Input fields — Soft Focus

- Filled: `surfaceContainerLow`, no border.
- Focus: background → `surfaceContainerLowest` + 1pt ghost border of `primary` @ 20%.

### Glass bottom navigation

- Floating container suspended `lg` (16) from the bottom edge, horizontal inset `lg`.
- Radius `xl`. Glass surface token.
- Active item: `primary` icon + label; inactive: `onSurfaceVariant`.

### Chips / Status pills

- Taken → sage soft-fill.
- Pending → amber soft-fill.
- Missed → amber soft-fill (never red).
- System error → `errorContainer` soft-fill; reserved for actual system errors (e.g., "sync failed"), not medication states.

---

## 7. Motion & Interaction

- **Durations**: 200ms (short), 300ms (medium), 500ms (sheets/modals).
- **Curves**: `Curves.easeOutCubic` for entry, `Curves.easeInCubic` for exit.
- **Press feedback**: scale 0.98 for 100ms.
- **List reveal**: 40ms stagger per item, opacity + translateY(8).

---

## 8. Iconography & Imagery

- Icons: Material Symbols Rounded (weight 400, grade 0, optical size 24).
- Pill/medication illustrations are encouraged; place them on the asymmetric right edge of cards.

---

## 9. Accessibility

- Minimum contrast: **4.5:1** for body text, **3:1** for title and above.
- Tap targets: **≥ 48×48 dp**.
- Respect `MediaQuery.textScaleFactor` — never hard-lock font sizes.
- Any status conveyed by color is **always** paired with text or an icon.

---

## 10. Do / Don't

### Do

- Lean on white space to create hierarchy.
- Reserve sage green strictly for "taken" / health-goal-met.
- Tint shadows with `primaryContainer`.

### Don't

- Use red for missed doses. Amber is supportive, red is alarmist.
- Draw solid borders to separate regions.
- Use pure black shadows.
- Use a radius smaller than 8px on any interactive element.
