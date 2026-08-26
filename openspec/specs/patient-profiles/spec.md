# patient-profiles Specification

## Purpose
TBD - created by archiving change backend-integration. Update Purpose after archive.
## Requirements
### Requirement: Profile Data Management
The client must support listing, creating, updating, and deleting patient profiles.

#### Scenario: Creating a patient profile
- **WHEN** user submits a new patient profile form
- **THEN** client posts to `POST /api/v1/profiles` sending `name`, `birthDate` (`YYYY-MM-DD`), `gender`, and optional `photoUrl`.

#### Scenario: Deleting a patient profile
- **WHEN** user deletes a profile
- **THEN** client calls `DELETE /api/v1/profiles/{profileId}` and removes local profile data upon `204 No Content`.

### Requirement: Active Profile Scope & Sync Trigger
The client must scope data queries and trigger delta sync when switching active profiles.

#### Scenario: Switching active profile
- **WHEN** user selects a different profile in the UI
- **THEN** Riverpod active profile notifier updates
- **AND** client initiates `GET /api/v1/profiles/{newProfileId}/sync` for the newly selected profile.

