import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_pills/core/theme/app_theme.dart';
import 'package:my_pills/core/widgets/app_notification.dart';

void main() {
  group('AppNotification Tests', () {
    testWidgets('renders message and default success icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: AppNotification(
              message: 'Dosis tomada con éxito',
              tone: AppNotificationTone.success,
            ),
          ),
        ),
      );

      expect(find.text('Dosis tomada con éxito'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('renders action button and triggers callback', (tester) async {
      var actionTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: AppNotification(
              message: 'Horario guardado',
              tone: AppNotificationTone.warning,
              actionLabel: 'Conectar',
              onAction: () => actionTriggered = true,
            ),
          ),
        ),
      );

      expect(find.text('Conectar'), findsOneWidget);
      await tester.tap(find.text('Conectar'));
      await tester.pump();

      expect(actionTriggered, isTrue);
    });

    testWidgets('AppNotification.showSuccess displays floating snackbar', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AppNotification.showSuccess(
                  context,
                  'Operación exitosa',
                ),
                child: const Text('Mostrar'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Mostrar'));
      await tester.pump(); // Start animation
      await tester.pump(
        const Duration(milliseconds: 300),
      ); // Finish entry animation

      expect(find.text('Operación exitosa'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('AppNotification.showError displays floating error snackbar', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AppNotification.showError(
                  context,
                  'Ocurrió un error inesperado',
                ),
                child: const Text('Error'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Error'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Ocurrió un error inesperado'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });

    testWidgets('context extension showInfoNotification works', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => context.showInfoNotification('Información'),
                child: const Text('Info'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Info'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Información'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
    });
  });
}
