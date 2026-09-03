# medications Specification

## Purpose
TBD - created by archiving change backend-integration. Update Purpose after archive.
## Requirements
### Requirement: Medication Data Contract & UI Field Mapping
The client must map local Medication attributes to the backend API payload fields.

#### Scenario: Creating a medication with field mapping
- **WHEN** user submits a new medication form with `name`, `instructions`, and `photoUrl`
- **THEN** client posts to `POST /api/v1/profiles/{profileId}/medications` with body:
  ```json
  {
    "name": "Ibuprofen",
    "instructions": "Take after meals with water",
    "photoUrl": "https://...",
    "form": "pill",
    "colorToken": "sky",
    "clientId": "550e8400-e29b-41d4-a716-446655440000"
  }
  ```
- **AND** does not send `dosage` — dose belongs to the schedule, not the medication.

#### Scenario: Deleting a medication
- **WHEN** user deletes a medication
- **THEN** client sends `DELETE /api/v1/profiles/{profileId}/medications/{medicationId}`.

### Requirement: Offline Persistence
The client must persist medications to local Drift database before sync.

#### Scenario: Local medication persistence
- **WHEN** user saves a medication
- **THEN** medication is stored immediately in Drift `MedicationsTable`
- **AND** outbox operation is queued if offline.

