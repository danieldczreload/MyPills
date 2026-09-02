import 'dart:convert';

/// Unverified JWT payload reader for OpenID Connect ID tokens.
///
/// Used only to copy display claims (`name`, `picture`) that Google already
/// signed. Token authenticity is still enforced by the backend.
final class IdTokenClaims {
  const IdTokenClaims({this.email, this.name, this.picture});

  final String? email;
  final String? name;
  final String? picture;

  static IdTokenClaims? tryParse(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final normalized = base64Url.normalize(parts[1]);
      final decoded = jsonDecode(utf8.decode(base64Url.decode(normalized)));
      if (decoded is! Map<String, dynamic>) return null;
      return IdTokenClaims(
        email: decoded['email'] as String?,
        name: decoded['name'] as String?,
        picture: decoded['picture'] as String?,
      );
    } on Object {
      return null;
    }
  }
}
