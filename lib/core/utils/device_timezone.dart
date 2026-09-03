import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:my_pills/core/utils/log.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Resolves the device IANA timezone (e.g. `America/Mexico_City`).
///
/// .NET analogue: `TimeZoneInfo.Local.Id` — **not** `StandardName`
/// (`CST`/`CDT`), which is what [DateTime.timeZoneName] returns and cannot
/// drive DST-safe reminder expansion on the backend.
///
/// [initializeLocal] may apply offset fallbacks to `tz.local` so local
/// notifications still fire. [currentIanaId] is what goes on the wire and
/// only returns an unambiguous IANA id — never `Etc/GMT±N`.
abstract final class DeviceTimezone {
  /// Queries the native zone, applies it to `tz.local`, and returns the IANA
  /// id used for `tz.local` (may be an offset fallback).
  ///
  /// Call once at boot.
  static Future<String> initializeLocal() async {
    _ensureDatabase();

    String? identifier;
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      identifier = info.identifier;
      mlog('mypills.boot', 'FlutterTimezone -> $identifier');
    } on Object catch (e) {
      mlog('mypills.boot', 'FlutterTimezone failed: $e');
    }

    if (identifier != null &&
        identifier.isNotEmpty &&
        _apply(identifier, source: 'tz.getLocation')) {
      return identifier;
    }

    final offsetHours = DateTime.now().timeZoneOffset.inHours;
    if (offsetHours == -6 &&
        _apply('America/Mexico_City', source: 'fallback America/Mexico_City')) {
      return 'America/Mexico_City';
    }

    final offsetId = _offsetFallbackId();
    if (_apply(offsetId, source: 'fallback offset')) {
      return offsetId;
    }

    mlog('mypills.boot', 'WARNING: tz.local defaulted to UTC');
    return 'UTC';
  }

  /// IANA id safe to send to the backend, or `null` if unknown.
  ///
  /// Omits POSIX `Etc/GMT±N` fallbacks (sign-inverted, not a real zone).
  static String? currentIanaId() {
    _ensureDatabase();
    try {
      final name = tz.local.name;
      if (_isReportableIana(name)) return name;
    } on Object {
      // `tz.local` is `late` until the database is initialized.
    }
    return null;
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

  /// True for zone ids the backend can use for DST (`America/Mexico_City`).
  ///
  /// `UTC` / `Etc/UTC` are valid IANA, but `tz.local` defaults to UTC on
  /// failed boot — reporting that would claim the user is in UTC. Plugin
  /// `UTC` still applies to `tz.local`; we just do not send it unless the
  /// name is an unambiguous area/location id.
  static bool _isReportableIana(String id) {
    if (id.isEmpty || id.startsWith('Etc/GMT')) return false;
    return id.contains('/');
  }

  /// POSIX-style `Etc/GMT±N` from the current numeric offset.
  ///
  /// Used only to keep `tz.local` usable for notifications. Never sent
  /// on the wire — IANA inverts the sign (`Etc/GMT-6` is UTC+6).
  static String _offsetFallbackId() {
    final offsetHours = DateTime.now().timeZoneOffset.inHours;
    final sign = offsetHours >= 0 ? '+' : '-';
    return 'Etc/GMT$sign${offsetHours.abs()}';
  }
}
