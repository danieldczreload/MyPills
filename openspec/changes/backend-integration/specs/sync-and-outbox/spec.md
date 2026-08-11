# Capability: Offline-First Synchronization & Outbox Queue

## ADDED Requirements

### Requirement: Offline Idempotent Writes (`clientId` UUID)
The client must generate a stable UUID for new entities to guarantee write idempotency.

#### Scenario: Device entity creation
- **WHEN** user creates a medication, schedule, or dose event offline or online
- **THEN** client generates a UUID v4 in `clientId`
- **AND** preserves the exact `clientId` across all network retries without regenerating it.

### Requirement: Outbox Operations Queue (`outbox_operations`)
The client must store pending offline mutations in a local database table for background synchronization.

#### Scenario: Enqueueing offline mutation
- **WHEN** an entity mutation occurs while offline
- **THEN** client records an outbox entry in `outbox_operations` table with action `CREATE`, `UPDATE`, or `DELETE`.

#### Scenario: Processing outbox queue
- **WHEN** network connection is restored
- **THEN** client executes queued outbox HTTP operations sequentially
- **AND** deletes the outbox entry upon HTTP 2xx success response.

### Requirement: Incremental Delta Synchronization
The client must fetch incremental updates from the backend and apply them atomically.

#### Scenario: Delta sync application
- **WHEN** executing `GET /api/v1/profiles/{profileId}/sync?since=<lastSyncTime>`
- **THEN** client applies received entities in strict order: Medications -> Schedules -> DoseEvents -> Tomstones
- **AND** updates local sync cursor timestamp only after successful database commit.
