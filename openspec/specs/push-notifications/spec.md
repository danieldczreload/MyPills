# push-notifications Specification

## Purpose
TBD - created by archiving change backend-integration. Update Purpose after archive.
## Requirements
### Requirement: FCM Device Token Registration
The client must register FCM tokens with the backend on login and unregister on logout.

#### Scenario: FCM token registration on login
- **WHEN** user logs in successfully
- **THEN** client posts FCM token to `POST /api/v1/devices` with payload:
  ```json
  {
    "fcmToken": "fcm-registration-token-string",
    "platform": "android",
    "locale": "es-MX"
  }
  ```

#### Scenario: FCM device unregistration on logout
- **WHEN** user logs out
- **THEN** client calls `DELETE /api/v1/devices/{deviceId}` before clearing access tokens.

### Requirement: Deep Link Push Payload Schema & Navigation
The client must route push notification tap payloads to target screens.

#### Scenario: Push tap navigation payload
- **WHEN** user taps a received push notification containing payload:
  ```json
  {
    "type": "dose_reminder",
    "doseEventId": "uuid-string",
    "medicationName": "Amoxicilina",
    "doseDisplay": "500 mg",
    "doseAmount": "500",
    "doseUnit": "mg"
  }
  ```
- **THEN** app parses payload and navigates to `/today`
- **AND** in-app banner body uses `doseDisplay` (fallback `dosage` for legacy pushes).

### Requirement: Diagnostic Test Push Endpoint
The client must support triggering diagnostic test notifications for QA.

#### Scenario: Test push request
- **WHEN** user triggers a test push in diagnostics settings
- **THEN** client sends `POST /api/v1/notifications/test-push` with body `{ "title": "Test", "body": "Delivery check" }`
- **AND** expects `200 OK` response `{ "sent": int, "failed": 0 }`.

