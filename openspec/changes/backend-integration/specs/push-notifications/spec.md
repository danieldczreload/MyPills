# Capability: Push Notifications & Device Registration

## ADDED Requirements

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
    "kind": "dose_reminder",
    "profileId": "uuid-string",
    "medicationId": "uuid-string",
    "doseEventId": "uuid-string"
  }
  ```
- **THEN** app parses payload and navigates directly to the corresponding profile or dose event screen via `go_router`.

### Requirement: Diagnostic Test Push Endpoint
The client must support triggering diagnostic test notifications for QA.

#### Scenario: Test push request
- **WHEN** user triggers a test push in diagnostics settings
- **THEN** client sends `POST /api/v1/notifications/test-push` with body `{ "title": "Test", "body": "Delivery check" }`
- **AND** expects `200 OK` response `{ "sent": int, "failed": 0 }`.

### Requirement: OEM Battery Optimization Handling
The client must prompt OEM Android devices (Xiaomi, Huawei, Oppo, Vivo, OnePlus) to disable aggressive battery optimization.

#### Scenario: OEM battery optimization dialog prompt
- **GIVEN** an Android device from an OEM family requiring manual setup (Xiaomi, Huawei, Oppo, Vivo, OnePlus)
- **WHEN** push notification permissions are configured
- **THEN** client invokes `maybeShowOemSetup` to present device-tailored step-by-step instructions.
