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
}
