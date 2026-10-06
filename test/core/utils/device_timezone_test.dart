import 'package:flutter_test/flutter_test.dart';
import 'package:my_pills/core/utils/device_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(tzdata.initializeTimeZones);

  tearDown(() {
    tz.setLocalLocation(tz.getLocation('UTC'));
  });

  group('DeviceTimezone.currentIanaId', () {
    test('returns the IANA id applied to tz.local', () {
      tz.setLocalLocation(tz.getLocation('America/Mexico_City'));
      expect(DeviceTimezone.currentIanaId(), 'America/Mexico_City');
    });

    test('does not report POSIX Etc/GMT fallbacks', () {
      tz.setLocalLocation(tz.getLocation('Etc/GMT-6'));
      expect(DeviceTimezone.currentIanaId(), isNull);
    });

    test('does not report last-resort UTC as the user zone', () {
      tz.setLocalLocation(tz.getLocation('UTC'));
      expect(DeviceTimezone.currentIanaId(), isNull);
    });
  });

  group('DeviceTimezone.locationForPlatformId', () {
    test('keeps a real area id', () {
      expect(
        DeviceTimezone.locationForPlatformId('America/El_Salvador'),
        'America/El_Salvador',
      );
    });

    test('maps an Android fixed offset without guessing a city', () {
      expect(
        DeviceTimezone.locationForPlatformId('GMT-06:00'),
        'Etc/GMT+6',
      );
      expect(
        DeviceTimezone.locationForPlatformId('GMT-06:00'),
        isNot('America/Mexico_City'),
      );
    });

    test('rejects abbreviations and fractional offsets', () {
      expect(DeviceTimezone.locationForPlatformId('CST'), isNull);
      expect(DeviceTimezone.locationForPlatformId('GMT+05:30'), isNull);
      expect(DeviceTimezone.locationForPlatformId(null), isNull);
    });
  });

  group('DeviceTimezone.fixedOffsetId', () {
    test('inverts the IANA Etc/GMT sign', () {
      expect(
        DeviceTimezone.fixedOffsetId(const Duration(hours: -6)),
        'Etc/GMT+6',
      );
      expect(
        DeviceTimezone.fixedOffsetId(const Duration(hours: 2)),
        'Etc/GMT-2',
      );
      final utcMinus6 = tz.TZDateTime.now(tz.getLocation('Etc/GMT+6'));
      expect(utcMinus6.timeZoneOffset, const Duration(hours: -6));
    });

    test('cannot represent a half-hour offset', () {
      expect(
        DeviceTimezone.fixedOffsetId(const Duration(hours: 5, minutes: 30)),
        isNull,
      );
    });
  });

  group('DeviceTimezone.reminderInstant', () {
    test('keeps 08:00 in the device zone when the offset matches', () {
      final wall = DateTime(2026, 10, 6, 8);
      final iana = _matchingZone(wall);
      expect(iana, isNotNull, reason: 'this host has no known matching zone');

      final zoned = DeviceTimezone.reminderInstant(wall, ianaId: iana);
      expect(zoned.location.name, iana);
      expect(zoned.hour, 8);
      expect(zoned.minute, 0);
      expect(zoned.millisecondsSinceEpoch, wall.millisecondsSinceEpoch);
    });

    test('does not move 08:00 into a zone with a different offset', () {
      final wall = DateTime(2026, 10, 6, 8);
      final other = wall.timeZoneOffset == Duration.zero
          ? 'America/El_Salvador'
          : 'UTC';

      final zoned = DeviceTimezone.reminderInstant(wall, ianaId: other);
      expect(zoned.location.name, 'UTC');
      expect(zoned.millisecondsSinceEpoch, wall.millisecondsSinceEpoch);
    });
  });
}

String? _matchingZone(DateTime wall) {
  const candidates = [
    'UTC',
    'America/El_Salvador',
    'America/Mexico_City',
    'America/Chicago',
    'Europe/Madrid',
  ];
  for (final id in candidates) {
    final location = tz.getLocation(id);
    final zoned = tz.TZDateTime(
      location,
      wall.year,
      wall.month,
      wall.day,
      wall.hour,
      wall.minute,
    );
    if (zoned.millisecondsSinceEpoch == wall.millisecondsSinceEpoch) return id;
  }
  return null;
}
