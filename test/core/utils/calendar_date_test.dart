import 'package:flutter_test/flutter_test.dart';
import 'package:my_pills/core/utils/calendar_date.dart';

void main() {
  group('CalendarDate.toIso', () {
    test('formats a local calendar date as YYYY-MM-DD', () {
      expect(CalendarDate.toIso(DateTime(2026, 9, 2)), '2026-09-02');
    });

    test('zero-pads month and day', () {
      expect(CalendarDate.toIso(DateTime(2026, 1, 5)), '2026-01-05');
    });

    test('does not shift the calendar day through UTC conversion', () {
      final localMidnight = DateTime(2026, 9, 2);
      expect(CalendarDate.toIso(localMidnight), '2026-09-02');
      expect(CalendarDate.toIso(localMidnight), isNot(contains('T')));
    });
  });
}
