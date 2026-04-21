import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_pills/main.dart';

void main() {
  testWidgets('app boots and renders the Today placeholder screen',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MyPillsApp()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
