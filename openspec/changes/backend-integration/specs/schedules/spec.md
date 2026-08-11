# Capability: Medication Schedules & Recurrence Rules

## ADDED Requirements

### Requirement: Schedule Rule Variants
The client must support creating daily, interval, and specific-days intake schedules.

#### Scenario: Creating daily schedule
- **WHEN** user configures a daily schedule
- **THEN** client sends `POST /api/v1/profiles/{profileId}/schedules` with `type: "daily"` and `timesOfDay: [{ "hour": 8, "minute": 0 }]`.

#### Scenario: Creating specific days schedule
- **WHEN** user configures a specific days schedule
- **THEN** client sends `type: "specific_days"` with `daysOfWeek` ISO integers (1=Mon..7=Sun).

### Requirement: Server Occurrence Hand-Off
The client must defer authoritative dose occurrence generation to backend sync responses.

#### Scenario: Rendering dose timeline
- **WHEN** displaying medication intake reminders
- **THEN** client renders server-generated dose events from sync and does not create duplicate local occurrences.
