# Capability: Medication Catalog Management

## ADDED Requirements

### Requirement: Medication Data Contract
The client must support creating, updating, listing, and deleting medications for patient profiles.

#### Scenario: Creating a medication
- **WHEN** user submits a new medication form
- **THEN** client posts to `POST /api/v1/profiles/{profileId}/medications` with `name`, `dosage`, `instructions`, `photoUrl`, and `clientId` UUID v4.

#### Scenario: Deleting a medication
- **WHEN** user deletes a medication
- **THEN** client sends `DELETE /api/v1/profiles/{profileId}/medications/{medicationId}`.

### Requirement: Offline Persistence
The client must persist medications to local Drift database before sync.

#### Scenario: Local medication persistence
- **WHEN** user saves a medication
- **THEN** medication is stored immediately in Drift `MedicationsTable`
- **AND** outbox operation is queued if offline.
