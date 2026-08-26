# dose-events Specification

## Purpose
TBD - created by archiving change backend-integration. Update Purpose after archive.
## Requirements
### Requirement: Dose Status Recording
The client must record dose intake states (`pending`, `taken`, `skipped`) and query timeline ranges.

#### Scenario: Marking dose as taken
- **WHEN** user marks a scheduled dose as taken
- **THEN** client posts to `POST /api/v1/profiles/{profileId}/dose-events` with `status: "taken"` and `takenAt` ISO-8601 timestamp.

#### Scenario: Querying dose timeline history
- **WHEN** loading timeline view
- **THEN** client requests `GET /api/v1/profiles/{profileId}/dose-events?from=<ISO>&to=<ISO>` with required date range parameters.

