import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_pills/core/theme/app_theme.dart';
import 'package:my_pills/features/schedules/presentation/dose_input_controller.dart';
import 'package:my_pills/features/schedules/presentation/persist_new_schedule.dart';
import 'package:my_pills/l10n/app_localizations.dart';

void main() {
  late DoseInputController controller;

  setUp(() {
    controller = DoseInputController();
  });

  tearDown(() => controller.dispose());

  Future<void> pumpHarness(WidgetTester tester, VoidCallback onPressed) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: onPressed,
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('readScheduleDose toasts and returns null when form is empty', (
    tester,
  ) async {
    await pumpHarness(tester, () {
      final context = tester.element(find.byType(TextButton));
      expect(readScheduleDose(context, controller), isNull);
    });

    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.text('Indica la cantidad y la unidad de la dosis'),
      findsOneWidget,
    );
  });

  testWidgets('readScheduleDose returns a Dose from valid input', (
    tester,
  ) async {
    controller
      ..amount.text = '500'
      ..unitCode = 'mg';

    await pumpHarness(tester, () {
      final context = tester.element(find.byType(TextButton));
      final dose = readScheduleDose(context, controller);
      expect(dose?.amount, 500);
      expect(dose?.unit, 'mg');
      expect(dose?.display, '500 mg');
    });

    await tester.tap(find.text('go'));
    await tester.pump();
    expect(find.byType(SnackBar), findsNothing);
  });
}
