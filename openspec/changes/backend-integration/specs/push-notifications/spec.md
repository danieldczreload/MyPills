# Capability: Push Notifications & Device Registration

## ADDED Requirements

### Requirement: FCM Device Token Registration
The client must register FCM tokens with the backend on login and unregister on logout.

#### Scenario: FCM token registration on login
- **WHEN** user logs in successfully
- **THEN** client posts FCM token to `POST /api/v1/devices` with `fcmToken`, `platform`, and `locale`.

#### Scenario: FCM device unregistration on logout
- **WHEN** user logs out
- **THEN** client calls `DELETE /api/v1/devices/{deviceId}` before clearing access tokens.

### Requirement: Deep Link Push Handling
The client must route notification tap events to target domain screens.

#### Scenario: Push tap navigation
- **WHEN** user taps a received push notification
- **THEN** app parses payload and navigates directly to the corresponding profile or dose event screen.
