import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

/// Stateless utility that reads and writes the "last greeting shown" date.
///
/// Kept as a pure static helper so both the router redirect (BuildContext-only
/// scope) and the GreetingScreen (Riverpod scope) can use it without extra
/// indirection.
abstract final class GreetingGate {
  static const _key = 'greetings.last_shown_date';
  static bool _dismissed = false;

  static bool shouldShow(SharedPreferences prefs) {
    if (_dismissed) return false;
    /*final lastShown = prefs.getString(_key);
    return lastShown != _todayKey();*/
    return true;
  }

  static void markSeen(SharedPreferences prefs) {
    _dismissed = true;
    unawaited(prefs.setString(_key, _todayKey()));
  }

  static String _todayKey() {
    final d = DateTime.now();
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }
}
