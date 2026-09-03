import 'package:flutter_test/flutter_test.dart';
import 'package:my_pills/core/network/http_error_body.dart';

void main() {
  group('summarizeHttpErrorBody', () {
    test('extracts JSON API error.message', () {
      expect(
        summarizeHttpErrorBody({
          'error': {
            'type': 'UNAUTHORIZED',
            'message': 'Invalid token payload.',
            'details': <dynamic>[],
          },
        }),
        'Invalid token payload.',
      );
    });

    test('collapses Symfony HTML to the title', () {
      const html = '''
<!DOCTYPE html>
<html lang="en">
  <head>
    <title>No route found for "POST https://localhost:8443/api/v1/auth/logout"</title>
    <style>:root { --color-error: #b0413e; }</style>
  </head>
  <body></body>
</html>
''';
      final summary = summarizeHttpErrorBody(html);
      expect(summary, startsWith('html: No route found'));
      expect(summary.contains(':root'), isFalse);
      expect(summary.contains('<style'), isFalse);
      expect(summary.length, lessThan(240));
    });

    test('truncates a long HTML title', () {
      final title = 'x' * 400;
      final summary = summarizeHttpErrorBody(
        '<html><title>$title</title></html>',
      );
      expect(summary.startsWith('html: '), isTrue);
      expect(summary.endsWith('…'), isTrue);
      expect(summary.length, 6 + 240 + 1);
    });

    test('returns empty for null', () {
      expect(summarizeHttpErrorBody(null), isEmpty);
    });
  });

  group('jsonServerErrorMessage', () {
    test('returns null for HTML', () {
      expect(
        jsonServerErrorMessage('<!DOCTYPE html><title>boom</title>'),
        isNull,
      );
    });
  });
}
