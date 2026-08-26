/// Environment and runtime configuration constants.
abstract final class EnvConfig {
  /// Base URL for the MyPills backend API.
  /// Defaults to the deployed production backend.
  /// Can be overridden at compile time via:
  /// `--dart-define=API_BASE_URL=https://...`
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://mypills-api.danieldelcid.com/api/v1',
  );

  /// Google OAuth 2.0 Android Client ID (PKCE public, no secret) used for
  /// Calendar + Identity. Replaces the former Desktop client
  /// 7kecgckss4f3fjgj1lde7m01h865dcb7.
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '583477896483-8061qrld7nh240st439768dplhsggq73.apps.googleusercontent.com',
  );

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
