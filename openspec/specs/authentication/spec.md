# authentication Specification

## Purpose
TBD - created by archiving change backend-integration. Update Purpose after archive.
## Requirements
### Requirement: Account Registration & Login
The client must support registering and logging in users using email and password against the application's backend.

#### Scenario: Successful account login
- **WHEN** user submits valid email and password credentials
- **THEN** client posts to `POST /api/v1/auth/login`
- **AND** stores returned `accessToken` and `refreshToken` in `TokenStorage`
- **AND** transitions Riverpod state to `Authenticated`.

#### Scenario: Legacy social login rejection
- **GIVEN** normal application user login
- **THEN** client MUST NOT call legacy routes `POST /api/v1/auth/google` or `POST /api/v1/auth/microsoft`.

### Requirement: Secure Token Storage & Authorization Header
The client must store JWT credentials securely and append them to protected HTTP requests.

#### Scenario: Protected request header
- **WHEN** sending any protected request to `/api/v1`
- **THEN** client includes `Authorization: Bearer <accessToken>` header from `TokenStorage`.

### Requirement: Single-Flight Mutex Token Refresh
The client must refresh access tokens using a single-flight mutex lock when encountering HTTP 401 Unauthorized responses.

#### Scenario: Concurrent 401 token refresh
- **GIVEN** multiple simultaneous API requests returning `401 Unauthorized`
- **WHEN** token refresh is triggered
- **THEN** client executes exactly one `POST /api/v1/auth/refresh` request guarded by a mutex
- **AND** retries all pending original requests with the new access token upon success.

#### Scenario: Failed token refresh
- **WHEN** `POST /api/v1/auth/refresh` fails or returns non-200 status
- **THEN** client clears `TokenStorage` and transitions user state to `Unauthenticated`.

### Requirement: Logout Session Revocation
The client must revoke the session on the backend and clear local tokens on logout.

#### Scenario: User logout
- **WHEN** user initiates logout
- **THEN** client posts to `POST /api/v1/auth/logout`
- **AND** clears stored `accessToken` and `refreshToken` unconditionally.

