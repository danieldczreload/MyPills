# Capability: API Contract & Data Synchronization

## ADDED Requirements

### Requirement: Authorization Header Format
The client must send Bearer tokens on protected endpoints.

#### Scenario: Sending HTTP requests
- **WHEN** making protected request to `/api/v1`
- **THEN** client includes `Authorization: Bearer <accessToken>` header.

### Requirement: Error Response Parsing
The client must parse standard error envelopes without raw server crashes.

#### Scenario: Server error envelope
- **WHEN** server returns HTTP 4xx or 5xx with JSON `{ "error": { "type": "VALIDATION", "message": "Validation failed." } }`
- **THEN** client maps error type to domain `Failure` without throwing unhandled exceptions.
