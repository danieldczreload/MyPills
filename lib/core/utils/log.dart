import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Single logger used across notifications/diagnostics. Writes to both:
/// - `dart:developer` (visible in DevTools / VM logging tab)
/// - `debugPrint` (visible in `flutter run` console)
///
/// `developer.log` alone is not always surfaced by `flutter run`, which made
/// our notification debugging blind in the past.
void mlog(String name, String message) {
  developer.log(message, name: name);
  debugPrint('[$name] $message');
}

void mlogError(
  String name,
  String message, {
  Object? error,
  StackTrace? stackTrace,
}) {
  developer.log(
    message,
    name: name,
    error: error,
    stackTrace: stackTrace,
  );
  debugPrint('[$name] ERROR: $message');
  if (error != null) debugPrint('  $error');
  if (stackTrace != null) debugPrint('  $stackTrace');
}
