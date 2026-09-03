import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_pills/core/theme/app_theme.dart';
import 'package:my_pills/features/schedules/presentation/widgets/schedule_time_picker.dart';
import 'package:my_pills/l10n/app_localizations.dart';

void main() {
  group('time helpers', () {
    test('stepHour in 12h keeps period and wraps 1-12', () {
      const eightAm = TimeOfDay(hour: 8, minute: 0);
      expect(stepHour(eightAm, 1, use24Hour: false).hour, 9);
      expect(stepHour(eightAm, -1, use24Hour: false).hour, 7);

      const twelveAm = TimeOfDay(hour: 0, minute: 0);
      expect(stepHour(twelveAm, 1, use24Hour: false).hour, 1);
      expect(stepHour(twelveAm, -1, use24Hour: false).hour, 11);

      const elevenPm = TimeOfDay(hour: 23, minute: 0);
      expect(stepHour(elevenPm, 1, use24Hour: false).hour, 12);
      expect(stepHour(elevenPm, 1, use24Hour: false).period, DayPeriod.pm);
    });

    test('stepHour in 24h wraps 0-23', () {
      expect(
        stepHour(const TimeOfDay(hour: 23, minute: 0), 1, use24Hour: true).hour,
        0,
      );
      expect(
        stepHour(const TimeOfDay(hour: 0, minute: 0), -1, use24Hour: true).hour,
        23,
      );
    });

    test('stepMinute wraps 0-59', () {
      expect(stepMinute(const TimeOfDay(hour: 8, minute: 59), 1).minute, 0);
      expect(stepMinute(const TimeOfDay(hour: 8, minute: 0), -1).minute, 59);
    });

    test('withPeriod toggles AM/PM without changing minute', () {
      const eightAm = TimeOfDay(hour: 8, minute: 15);
      final pm = withPeriod(eightAm, DayPeriod.pm);
      expect(pm.hour, 20);
      expect(pm.minute, 15);
      expect(withPeriod(pm, DayPeriod.am).hour, 8);
    });

    test('displayHourIndex / timeFromDisplayHour round-trip', () {
      const eightAm = TimeOfDay(hour: 8, minute: 15);
      final index = displayHourIndex(eightAm, use24Hour: false);
      expect(index, 7);
      expect(
        timeFromDisplayHour(
          hourIndex: index,
          minute: 15,
          use24Hour: false,
          isPm: false,
        ).hour,
        8,
      );

      const eightPm = TimeOfDay(hour: 20, minute: 15);
      expect(displayHourIndex(eightPm, use24Hour: true), 20);
      expect(
        timeFromDisplayHour(
          hourIndex: 20,
          minute: 15,
          use24Hour: true,
          isPm: true,
        ).hour,
        20,
      );
    });
  });

  group('ScheduleTimePickerField', () {
    testWidgets('renders 08:00 a. m. from TimeOfDay(8, 0)', (tester) async {
      await tester.pumpWidget(
        _host(
          const ScheduleTimePickerField(
            value: TimeOfDay(hour: 8, minute: 0),
            onChanged: _noop,
          ),
        ),
      );

      expect(find.text('08'), findsOneWidget);
      expect(find.text('00'), findsOneWidget);
      expect(find.text('a. m.'), findsOneWidget);
      expect(find.text('p. m.'), findsOneWidget);
    });

    testWidgets('tapping hour-up moves 8 to 9', (tester) async {
      var time = const TimeOfDay(hour: 8, minute: 0);
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) {
              return ScheduleTimePickerField(
                value: time,
                onChanged: (next) => setState(() => time = next),
              );
            },
          ),
        ),
      );

      await tester.tap(find.byKey(ScheduleTimePickerField.hourUpKey));
      await tester.pump();

      expect(time.hour, 9);
      expect(find.text('09'), findsOneWidget);
    });

    testWidgets('tapping p. m. from 8:00 AM yields 20:00', (tester) async {
      var time = const TimeOfDay(hour: 8, minute: 0);
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) {
              return ScheduleTimePickerField(
                value: time,
                onChanged: (next) => setState(() => time = next),
              );
            },
          ),
        ),
      );

      await tester.tap(find.byKey(ScheduleTimePickerField.periodPmKey));
      await tester.pump();

      expect(time.hour, 20);
    });

    testWidgets('tapping the numeral opens the wheel sheet', (tester) async {
      await tester.pumpWidget(
        _host(
          const ScheduleTimePickerField(
            value: TimeOfDay(hour: 8, minute: 0),
            onChanged: _noop,
          ),
        ),
      );

      await tester.tap(find.byKey(ScheduleTimePickerField.hourValueKey));
      await tester.pumpAndSettle();

      expect(find.text('Hora de la dosis'), findsOneWidget);
      expect(find.text('Confirmar'), findsOneWidget);
    });

    testWidgets('dismissing the sheet without confirm keeps the value', (
      tester,
    ) async {
      var time = const TimeOfDay(hour: 8, minute: 0);
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) {
              return ScheduleTimePickerField(
                value: time,
                onChanged: (next) => setState(() => time = next),
              );
            },
          ),
        ),
      );

      await tester.tap(find.byKey(ScheduleTimePickerField.hourValueKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(time.hour, 8);
      expect(find.text('Hora de la dosis'), findsNothing);
    });

    testWidgets('24h hides AM/PM and shows 20:30', (tester) async {
      await tester.pumpWidget(
        _host(
          const ScheduleTimePickerField(
            value: TimeOfDay(hour: 20, minute: 30),
            onChanged: _noop,
          ),
          use24Hour: true,
        ),
      );

      expect(find.text('20'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
      expect(find.byKey(ScheduleTimePickerField.periodAmKey), findsNothing);
      expect(find.byKey(ScheduleTimePickerField.periodPmKey), findsNothing);
      expect(find.text('a. m.'), findsNothing);
    });
  });
}

void _noop(TimeOfDay _) {}

Widget _host(Widget child, {bool use24Hour = false}) {
  return MaterialApp(
    theme: AppTheme.light(),
    locale: const Locale('es'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, appChild) {
      final media = MediaQuery.of(context);
      return MediaQuery(
        data: media.copyWith(alwaysUse24HourFormat: use24Hour),
        child: appChild!,
      );
    },
    home: Scaffold(body: child),
  );
}
