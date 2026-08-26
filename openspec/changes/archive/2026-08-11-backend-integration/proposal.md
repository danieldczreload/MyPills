# Change Proposal: Backend Integration & Offline-First Sync

## Scope
Integrate the MyPills Flutter client with the Symfony backend API (`~/Projects/MyPills-api`) at `/api/v1`. Enable account authentication, local token storage, device FCM registration, PKCE external calendar authorization, and offline-first delta sync for patient profiles, medications, schedules, and dose events.

## Motivation
The MVP version of MyPills is strictly local on-device. Integrating with the backend enables cross-device sync, push notifications for dose reminders, and calendar integration while keeping offline-first reliability.

## Key Changes
1. **Network & Auth Core:** Dio client with mutex single-flight refresh on `401 Unauthorized`, `flutter_secure_storage` token management.
2. **Offline-First Sync Engine:** Outbox table in Drift SQLite, idempotent `clientId` UUIDs, delta sync (`GET /api/v1/profiles/{profileId}/sync?since=...`), tombstone processing.
3. **Feature Migration:** Multi-profile support, medication/schedule/dose event synchronization with backend domain contract.
4. **Push Notifications & Calendar Integration:** FCM device registration and OAuth 2.0 PKCE calendar authorization.

## Dependencies & Risk
- Risk: Token expiration concurrent requests triggering duplicate refresh. Mitigated by mutex-guarded refresh interceptor.
- Risk: Offline data conflict. Mitigated by backend authoritative `updatedAt` LWW and `clientId` retry idempotency.
