# api-contract Specification

## Purpose
TBD - created by archiving change backend-integration. Update Purpose after archive.
## Requirements
### Requirement: Authorization Header & Content-Type
The client must attach JWT access tokens and application/json content types to all protected API calls.

#### Scenario: Protected request headers
- **WHEN** sending protected request to `/api/v1`
- **THEN** client includes `Authorization: Bearer <accessToken>` and `Content-Type: application/json`.

### Requirement: 204 No Content Handling
The client must handle empty 204 response bodies without attempting JSON decoding.

#### Scenario: Processing 204 No Content response
- **WHEN** backend returns status `204 No Content` (e.g., on DELETE operations)
- **THEN** HTTP client completes the operation successfully without invoking `jsonDecode` or attempting to parse response data.

### Requirement: Standard Error Envelope Parsing
The client must parse server error envelopes and map them to domain `Failure` instances without throwing raw exceptions.

#### Scenario: Error envelope structure
- **WHEN** backend returns status codes `400`, `403`, `404`, `409`, `422`, or `500`
- **THEN** client parses standard error envelope:
  ```json
  {
    "error": {
      "type": "VALIDATION | UNAUTHORIZED | NOT_FOUND | CONFLICT | PUSH_PARTIAL_FAILURE | SYNC_PARTIAL_FAILURE",
      "message": "Human readable error summary",
      "details": {}
    }
  }
  ```
- **AND** maps `401` to `Failure.unauthorized()`
- **AND** maps `404` to `Failure.notFound()`
- **AND** maps `409` to `Failure.conflict()`
- **AND** maps `422` to `Failure.validation()` with field error details
- **AND** maps network socket timeouts / connection failures to `Failure.network()`.

