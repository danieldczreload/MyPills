import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:my_pills/core/utils/log.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Resolves the device IANA timezone (e.g. `America/El_Salvador`).
///
/// .NET analogue: `TimeZoneInfo.Local.Id` — **not** `StandardName`
/// (`CST`/`CDT`), which is what [DateTime.timeZoneName] returns and cannot
/// drive DST-safe reminder expansion on the backend.
///
/// [initializeLocal] may apply an offset fallback to `tz.local` so local
/// notifications still have a location. [currentIanaId] is what goes on the
/// wire. It returns only an id the platform actually reported. It never
/// invents a city from the numeric offset (`America/Mexico_City` for every
/// UTC−6 device) and never sends a sign-inverted `Etc/GMT` guess.
abstract final class DeviceTimezone {
  /// Last id reported by the platform. Survives a later reset of `tz.local`
  /// back to UTC.
  static String? _platformIanaId;

  /// `GMT-06:00` / `UTC+5` style ids some Android builds return instead of
  /// an area name.
  static final RegExp _fixedOffsetId = RegExp(
    r'^(?:GMT|UTC)([+-])(\d{1,2})(?::?(\d{2}))?$',
  );

  /// Queries the native zone, applies it to `tz.local`, and returns the id
  /// used for `tz.local`.
  ///
  /// Call at boot and again whenever the app resumes or is about to send a
  /// schedule. A failed read keeps the previous platform id.
  static Future<String> initializeLocal() async {
    _ensureDatabase();

    final platformId = await _readPlatformId();
    final resolved = locationForPlatformId(platformId);
    if (resolved != null && _apply(resolved, source: 'platform')) {
      _platformIanaId = resolved;
      mlog('mypills.boot', 'reportable timezone -> $resolved');
      return resolved;
    }

    final kept = _platformIanaId ?? _reportableLocalName();
    if (kept != null) {
      mlog('mypills.boot', 'keeping previous timezone $kept');
      return kept;
    }

    final offsetId = fixedOffsetId(DateTime.now().timeZoneOffset);
    if (offsetId != null &&
        offsetId != 'UTC' &&
        _apply(offsetId, source: 'offset fallback')) {
      mlog(
        'mypills.boot',
        'WARNING: no IANA timezone from the device. '
            'tz.local=$offsetId will not be sent',
      );
      return offsetId;
    }

    mlog(
      'mypills.boot',
      'WARNING: tz.local defaulted to UTC and will not be sent',
    );
    return 'UTC';
  }

  /// IANA id safe to send to the backend, or `null` if the device zone is
  /// not known.
  static String? currentIanaId() {
    final reported = _platformIanaId;
    if (reported != null && reported.isNotEmpty) return reported;
    return _reportableLocalName();
  }

  /// Maps a platform timezone id to a location in the IANA database.
  ///
  /// Returns null for abbreviations (`CST`) and for ids the database does
  /// not contain. A fixed offset such as `GMT-06:00` becomes `Etc/GMT+6`
  /// (IANA flips the sign). It does not guess a city.
  static String? locationForPlatformId(String? platformId) {
    _ensureDatabase();
    if (platformId == null) return null;
    final id = platformId.trim();
    if (id.isEmpty) return null;

    final direct = _knownLocation(id);
    if (direct != null) return direct;

    final fixed = _androidFixedOffsetId(id);
    if (fixed == null) return null;
    return _knownLocation(fixed);
  }

  /// POSIX `Etc/GMT±N` for a whole-hour [offset], or `UTC` for zero.
  ///
  /// IANA inverts the sign: `Etc/GMT+6` is UTC−6. Fractional offsets cannot
  /// be represented and return null. This id is only a local fallback; it
  /// is sent solely when the platform itself reported that fixed offset.
  static String? fixedOffsetId(Duration offset) {
    if (offset.inSeconds == 0) return 'UTC';
    if (offset.inSeconds.abs() % Duration.secondsPerHour != 0) return null;
    final hours = offset.inHours;
    final sign = hours > 0 ? '-' : '+';
    return 'Etc/GMT$sign${hours.abs()}';
  }

  /// Instant Android should schedule for the wall clock of [when].
  ///
  /// `flutter_local_notifications` sends the clock components plus the
  /// timezone location name. Android then does
  /// `ZonedDateTime.of(localDateTime, ZoneId.of(timeZoneName))`.
  ///
  /// When [ianaId] is the device zone, the alarm is that clock time in that
  /// zone (08:00 in `America/El_Salvador`). When [ianaId] has a different
  /// offset than the device, the absolute instant of [when] is kept in UTC
  /// so a wrong zone cannot move the reminder.
  static tz.TZDateTime reminderInstant(DateTime when, {String? ianaId}) {
    _ensureDatabase();
    final wall = when.isUtc ? when.toLocal() : when;
    if (ianaId != null) {
      try {
        final location = tz.getLocation(ianaId);
        final zoned = tz.TZDateTime(
          location,
          wall.year,
          wall.month,
          wall.day,
          wall.hour,
          wall.minute,
          wall.second,
          wall.millisecond,
          wall.microsecond,
        );
        if (zoned.millisecondsSinceEpoch == wall.millisecondsSinceEpoch) {
          return zoned;
        }
      } on Object {
        // Unknown id or a DST gap. Keep the absolute instant below.
      }
    }
    return tz.TZDateTime.from(wall.toUtc(), tz.UTC);
  }

  static Future<String?> _readPlatformId() async {
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      final identifier = info.identifier.trim();
      mlog('mypills.boot', 'FlutterTimezone -> $identifier');
      if (identifier.isEmpty) return null;
      return identifier;
    } on Object catch (e) {
      mlog('mypills.boot', 'FlutterTimezone failed: $e');
      return null;
    }
  }

  static String? _reportableLocalName() {
    _ensureDatabase();
    try {
      final name = tz.local.name;
      if (_isReportableIana(name)) return name;
    } on Object {
      // `tz.local` is `late` until the database is initialized.
    }
    return null;
  }

  static String? _knownLocation(String id) {
    try {
      return tz.getLocation(id).name;
    } on Object {
      return null;
    }
  }

  static String? _androidFixedOffsetId(String id) {
    final match = _fixedOffsetId.firstMatch(id.trim());
    if (match == null) return null;
    final minutes = int.parse(match.group(3) ?? '0');
    if (minutes != 0) return null;
    final hours = int.parse(match.group(2)!);
    final negative = match.group(1) == '-';
    return fixedOffsetId(Duration(hours: negative ? -hours : hours));
  }

  static void _ensureDatabase() {
    // `initializeTimeZones` resets `tz.local` to UTC — skip if already loaded.
    if (tz.timeZoneDatabase.isInitialized) return;
    tzdata.initializeTimeZones();
  }

  static bool _apply(String identifier, {required String source}) {
    try {
      tz.setLocalLocation(tz.getLocation(identifier));
      mlog(
        'mypills.boot',
        'tz.local successfully set to $identifier ($source)',
      );
      return true;
    } on Object catch (e) {
      mlog('mypills.boot', 'tz.getLocation("$identifier") failed: $e');
      return false;
    }
  }

  /// True for area ids the backend can use for DST (`America/El_Salvador`).
  ///
  /// `UTC` and `Etc/GMT±N` are valid IANA, but they are also what a failed
  /// boot leaves in `tz.local`. Those are not reported from `tz.local`.
  /// An id the platform itself returned is stored in [_platformIanaId] and
  /// reported even when it is `UTC` or a fixed `Etc/GMT` offset.
  static bool _isReportableIana(String id) {
    if (id.isEmpty || id.startsWith('Etc/GMT') || id == 'UTC') return false;
    return id.contains('/');
  }
}
