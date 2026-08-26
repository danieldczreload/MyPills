# Capability: External Calendar Integration (OAuth 2.0 PKCE)

## ADDED Requirements

### Requirement: PKCE Authorization Flow & System Browser
The client must execute PKCE authorization using system browser for external calendar consent.

#### Scenario: Starting calendar authorization
- **WHEN** user connects Google or Microsoft calendar
- **THEN** client generates 32-byte `codeVerifier` and SHA-256 base64url `codeChallenge`
- **AND** calls `POST /api/v1/calendars/{provider}/authorize` with `profileId` and `codeChallenge`
- **AND** opens `authorizationUrl` in system browser (Custom Tabs / ASWebAuthenticationSession).

#### Scenario: Completing calendar authorization via deep link
- **GIVEN** registered scheme `mypills://oauth/callback` in `AndroidManifest.xml` / `Info.plist`
- **WHEN** provider deep link returns `code` and `state`
- **THEN** client verifies `state` matches original server state
- **AND** posts `POST /api/v1/calendars/{provider}/connect` with `profileId`, `code`, `state`, and `codeVerifier`.

### Requirement: Provider Refresh Token Security
The client must never store or request external calendar refresh tokens.

#### Scenario: Calendar token handling
- **THEN** client stores only connection status (`active`, `reauth_required`) and never persists provider refresh tokens.
