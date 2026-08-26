import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_pills/core/widgets/app_avatar.dart';

void main() {
  group('AppAvatar Tests', () {
    test('resolveImageUrl resolves relative and absolute URLs correctly', () {
      expect(
        resolveImageUrl('https://example.com/photo.jpg'),
        equals('https://example.com/photo.jpg'),
      );
      expect(
        resolveImageUrl('http://example.com/photo.jpg'),
        equals('http://example.com/photo.jpg'),
      );
      expect(
        resolveImageUrl('/uploads/avatar.png'),
        contains('/uploads/avatar.png'),
      );
    });

    test('isRemoteImageUrl detects remote and local URLs correctly', () {
      expect(isRemoteImageUrl('https://google.com/photo.png'), isTrue);
      expect(isRemoteImageUrl('http://example.com/photo.png'), isTrue);
      expect(isRemoteImageUrl('/uploads/photo.png'), isTrue);
      expect(isRemoteImageUrl('uploads/photo.png'), isTrue);
      expect(isRemoteImageUrl('/data/user/0/cache/photo.jpg'), isFalse);
      expect(isRemoteImageUrl('assets/images/logo.png'), isFalse);
    });

    testWidgets('renders fallback icon when photoPath is null or empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppAvatar(
              photoPath: null,
              radius: 24,
              fallbackIcon: Icons.person,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('renders custom fallback icon and colors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppAvatar(
              photoPath: '',
              radius: 30,
              fallbackIcon: Icons.add_a_photo,
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.add_a_photo), findsOneWidget);
    });
  });
}
