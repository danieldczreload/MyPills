/// Environment and runtime configuration constants.
abstract final class EnvConfig {
  /// Deployed production API. This is the compile-time default so release
  /// builds (`flutter build apk/appbundle/ios`) never hit localhost unless
  /// an explicit `--dart-define=API_BASE_URL=...` is passed.
  static const String productionApiBaseUrl =
      'https://mypills-api.danieldelcid.com/api/v1';

  /// Local HTTPS API used only in development launches.
  /// Desktop: `https://localhost/api/v1` (Caddy on :443).
  /// Android emulator: `https://localhost:8443/api/v1` plus
  /// `adb reverse tcp:8443 tcp:443` (privileged :443 cannot be reversed).
  static const String localApiBaseUrl = 'https://localhost/api/v1';

  /// Emulator-side URL. Requires `adb reverse tcp:8443 tcp:443` so SNI stays
  /// `localhost` (Caddy rejects TLS when the host is `10.0.2.2`).
  static const String androidEmulatorApiBaseUrl =
      'https://localhost:8443/api/v1';

  /// Base URL for the MyPills backend API.
  /// Override at compile time via:
  /// `--dart-define=API_BASE_URL=https://localhost/api/v1`
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: productionApiBaseUrl,
  );

  /// Google OAuth 2.0 Android Client ID (PKCE public, no secret) used for
  /// Calendar + Identity. Replaces the former Desktop client
  /// 7kecgckss4f3fjgj1lde7m01h865dcb7.
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '583477896483-8061qrld7nh240st439768dplhsggq73.apps.googleusercontent.com',
  );

  /// Google Web Application Client ID used as serverClientId so the
  /// serverAuthCode can be exchanged by the backend for Calendar API access.
  /// Public identifier (safe to hardcode); the secret lives only on the server.
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '583477896483-l1antrvp31f8pged7qqvlocu2rmqg7et.apps.googleusercontent.com',
  );

  /// Effective serverClientId passed to google_sign_in. Must match the client
  /// the backend uses to exchange the server auth code.
  static String get effectiveGoogleServerClientId =>
      googleWebClientId.isNotEmpty ? googleWebClientId : googleServerClientId;

  /// Scope required to create events on the user's primary Google Calendar.
  static const String googleCalendarScope =
      'https://www.googleapis.com/auth/calendar';

  /// Microsoft Azure Entra ID OAuth 2.0 Client ID.
  static const String microsoftClientId = String.fromEnvironment(
    'MICROSOFT_CLIENT_ID',
    defaultValue: '8027869b-ea6c-4e17-ba11-ac3b64d531e6',
  );

  /// Microsoft Azure Tenant ID.
  static const String microsoftTenantId = String.fromEnvironment(
    'MICROSOFT_TENANT_ID',
    defaultValue: '02c22510-e519-4d0f-88ca-acb3f4d87930',
  );

  /// Microsoft OAuth redirect URI.
  static const String microsoftRedirectUri = String.fromEnvironment(
    'MICROSOFT_REDIRECT_URI',
    defaultValue: 'com.mypills.app://auth',
  );
}
