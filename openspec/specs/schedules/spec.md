# schedules Specification

## Purpose
TBD - created by archiving change backend-integration. Update Purpose after archive.
## Requirements
### Requirement: Schedule Rule Variants
The client must support creating daily, interval, and specific-days intake schedules with JSON structures matching backend expectations.

#### Scenario: Creating daily schedule
- **WHEN** user configures a daily schedule
- **THEN** client sends `POST /api/v1/profiles/{profileId}/schedules` with body:
  ```json
  {
    "medicationId": "uuid-string",
    "type": "daily",
    "startDate": "2026-08-01",
    "doseAmount": 400,
    "doseUnit": "mg",
    "timesOfDay": [
      { "hour": 8, "minute": 0 },
      { "hour": 20, "minute": 30 }
    ],
    "clientId": "uuid-v4-string"
  }
  ```
- **AND** `doseAmount` is a JSON number > 0 (max 4 decimal places) and `doseUnit` is a catalog `code` from `GET /api/v1/dose-units`.

#### Scenario: Creating hourly interval schedule
- **WHEN** user configures an interval schedule (e.g. every 6 hours)
- **THEN** client sends `POST /api/v1/profiles/{profileId}/schedules` with body:
  ```json
  {
    "medicationId": "uuid-string",
    "type": "daily_interval",
    "startDate": "2026-08-01",
    "everyHours": 6,
    "startAt": { "hour": 8, "minute": 0 },
    "endAt": { "hour": 22, "minute": 0 },
    "clientId": "uuid-v4-string"
  }
  ```

#### Scenario: Creating specific days schedule
- **WHEN** user configures a specific days schedule
- **THEN** client sends `POST /api/v1/profiles/{profileId}/schedules` with `type: "specific_days"`, `daysOfWeek: [1, 3, 5]` (ISO 8601: 1=Monday..7=Sunday), and `timesOfDay: [{ "hour": 9, "minute": 30 }]`.

### Requirement: Server Occurrence Hand-Off
The client must defer authoritative dose occurrence generation to backend sync responses.

#### Scenario: Rendering dose timeline
- **WHEN** displaying medication intake reminders
- **THEN** client renders server-generated dose events from sync and does not create duplicate local occurrences.

