# MyPills

A client-only Flutter MVP for medication tracking and reminder notifications. Built with Clean Architecture and reactive state management.

## Features

- Add and manage your medications with dosage and schedule details
- Local notifications to remind you when it's time to take a pill
- Track your intake history
- Light-weight, offline-first: all data lives on your device
- Spanish UI (MVP ships with `es` localization)

## Tech Stack

| Concern | Package |
|---------|---------|
| State Management & DI | `flutter_riverpod` + `riverpod_generator` |
| Navigation | `go_router` |
| Local Database | `drift` (SQLite) |
| Immutable Models | `freezed` + `json_serializable` |
| Code Generation | `build_runner` |
| Linting | `flutter_lints` + `very_good_analysis` |
| Testing | `flutter_test`, `mocktail` |

## Architecture

Clean Architecture layered as `presentation → domain ← data`.

```
lib/
  core/            # utils, errors, Result, theme, AppDatabase
  features/<f>/
    data/          # drift tables, DAOs, DTOs, repo implementations
    domain/        # entities (freezed), repo interfaces, use cases
    presentation/  # widgets, screens, providers
  app/             # routing, root widget, app-wide providers
  l10n/            # ARB localization files
```

Key rules:
- `domain` knows nothing about `data` or `presentation`.
- `presentation` talks to use cases, not repositories directly.
- `data` implements `domain` interfaces; Drift types never leak past the data layer.

## Getting Started

### Prerequisites

- Flutter stable channel (SDK >= 3.3)
- Dart >= 3.3
- Android Studio / Xcode (for emulators or physical devices)

### Install & Run

```bash
# Clone the repo
git clone https://github.com/<your-username>/MyPills.git
cd MyPills

# Fetch dependencies
flutter pub get

# Run code generation (required after any drift/freezed/riverpod changes)
dart run build_runner build --delete-conflicting-outputs

# Run the app
flutter run
```

### Code Quality

```bash
# Analyze
flutter analyze

# Format
flutter format lib test
```

## Building for Release

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release
```

## Project Status

This is an MVP. Features are intentionally scoped to core medication reminders. Future iterations may include cloud sync, multi-language support, and wearable integrations.

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
