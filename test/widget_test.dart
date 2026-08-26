import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_pills/app/providers.dart';
import 'package:my_pills/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('app boots and renders splash screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MyPillsApp(),
      ),
    );

    // First frame — splash screen is visible
    await tester.pump();
    expect(find.text('MyPills'), findsOneWidget);

    // Wait for entry and shimmer animations
    await tester.pumpAndSettle();

    // Wait for the Future.delayed(200ms) in _runSequence
    await tester.pump(const Duration(milliseconds: 250));

    // Wait for exit animation and navigation
    await tester.pumpAndSettle();
  });
}
