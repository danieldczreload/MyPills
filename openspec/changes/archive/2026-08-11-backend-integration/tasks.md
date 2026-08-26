# Tasks: Backend Integration & SDD Implementation

- [x] Add dependencies (`dio`, `flutter_secure_storage`, `uuid`) to `pubspec.yaml` <!-- id: 0 -->
- [x] Implement `TokenStorage` and `ApiClient` with mutex token refresh interceptor <!-- id: 1 -->
- [x] Implement Auth Repository & Riverpod State (`POST /auth/login`, `/auth/register`, `/auth/refresh`, `/auth/logout`) <!-- id: 2 -->
- [x] Update Drift database tables to include `clientId`, `serverUpdatedAt`, `syncStatus`, `isTombstone`, and `outbox_operations` table <!-- id: 3 -->
- [x] Implement `SyncEngine` for delta sync (`/sync?since=...`) and Outbox Queue sync <!-- id: 4 -->
- [x] Connect Profiles, Medications, Schedules, and DoseEvents repositories to SyncEngine & API DTOs <!-- id: 5 -->
- [x] Implement Push Notification registration (`POST /devices`) and tap routing <!-- id: 6 -->
- [x] Implement OAuth 2.0 PKCE Calendar Authorization (`/calendars/{provider}/authorize` & `/connect`) <!-- id: 7 -->
- [x] Run test suite, verify code coverage with mocks, `flutter analyze`, and `dart format` <!-- id: 8 -->

