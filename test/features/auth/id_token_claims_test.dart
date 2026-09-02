import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_pills/features/auth/data/id_token_claims.dart';

String _jwt(Map<String, Object?> payload) {
  String b64(String input) =>
      base64Url.encode(utf8.encode(input)).replaceAll('=', '');
  return '${b64('{"alg":"none"}')}.${b64(jsonEncode(payload))}.sig';
}

void main() {
  test('tryParse reads OpenID name and picture claims', () {
    final claims = IdTokenClaims.tryParse(
      _jwt({
        'email': 'dan@example.com',
        'name': 'Daniel',
        'picture': 'https://lh3.googleusercontent.com/a/photo',
      }),
    );

    expect(claims, isNotNull);
    expect(claims!.email, 'dan@example.com');
    expect(claims.name, 'Daniel');
    expect(claims.picture, 'https://lh3.googleusercontent.com/a/photo');
  });

  test('tryParse returns null for non-JWT tokens', () {
    expect(IdTokenClaims.tryParse('valid-dan@example.com'), isNull);
  });
}
