# Capability: Offline-First Synchronization & Outbox Queue

## ADDED Requirements

### Requirement: Offline Idempotent Writes (`clientId` UUID)
The client must generate a stable UUID for new entities to guarantee write idempotency across network retries.

#### Scenario: Device entity creation
- **WHEN** user creates a medication, schedule, or dose event offline or online
- **THEN** client generates a UUID v4 in `clientId`
- **AND** preserves the exact `clientId` across all network retries without regenerating it.

### Requirement: Remote vs Local Primary Key Mapping
The client must map backend String UUID identifiers (`id` and `clientId`) to local database records.

#### Scenario: Local database schema ID mapping
- **GIVEN** local SQLite tables with auto-incrementing integer `id` primary keys
- **WHEN** syncing with backend
- **THEN** client stores backend UUID string in `remoteId` and `clientId` columns
- **AND** uses `remoteId` for remote entity references while preserving local integer primary keys for internal SQLite foreign key constraints.

### Requirement: Outbox Operations Queue (`outbox_operations`)
The client must store pending offline mutations in a local database table for background synchronization.

#### Scenario: Enqueueing offline mutation
- **WHEN** an entity mutation occurs while offline
- **THEN** client records an outbox entry in `outbox_operations` table with action `CREATE`, `UPDATE`, or `DELETE`.

#### Scenario: Processing outbox queue
- **WHEN** network connection is restored
- **THEN** client executes queued outbox HTTP operations sequentially
- **AND** deletes the outbox entry upon HTTP 2xx success response.

### Requirement: Incremental Delta Synchronization & Overlap Window
The client must fetch incremental updates from backend and apply them atomically.

#### Scenario: Delta sync application with safety overlap
- **WHEN** executing `GET /api/v1/profiles/{profileId}/sync?since=<lastSyncTime>`
- **THEN** client subtracts a 5-second overlap window from `lastSyncTime` to compensate for clock drift and database transaction commit boundaries
- **AND** applies received entities in strict order: Medications -> Schedules -> DoseEvents -> Tombstones
- **AND** updates local sync cursor timestamp only after successful database commit.

### Requirement: Profile Timezone Synchronization
The client must report the device's current IANA timezone to prevent daylight saving scheduling errors.

#### Scenario: Timezone update
- **WHEN** performing profile sync or schedule creation
- **THEN** client queries native IANA timezone via `flutter_timezone` (e.g. `America/Mexico_City`)
- **AND** includes `timezone` in profile update requests.
