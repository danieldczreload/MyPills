import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure token storage for JWT access and refresh tokens.
class TokenStorage {
  TokenStorage({FlutterSecureStorage? secureStorage})
    : _storage = secureStorage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String _accessTokenKey = 'mypills_access_token';
  static const String _refreshTokenKey = 'mypills_refresh_token';

  String? _inMemoryAccessToken;

  /// Returns cached in-memory access token or loads it from secure storage.
  Future<String?> getAccessToken() async {
    if (_inMemoryAccessToken != null) {
      return _inMemoryAccessToken;
    }
    _inMemoryAccessToken = await _storage.read(key: _accessTokenKey);
    return _inMemoryAccessToken;
  }

  /// Returns stored refresh token.
  Future<String?> getRefreshToken() async {
    return _storage.read(key: _refreshTokenKey);
  }

  /// Stores new access token and refresh token.
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _inMemoryAccessToken = accessToken;
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  /// Clears stored access token and refresh token.
  Future<void> clearTokens() async {
    _inMemoryAccessToken = null;
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}
