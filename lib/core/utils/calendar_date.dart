/// Calendar date (`YYYY-MM-DD`) in the device's local calendar.
///
/// Never uses [DateTime.toUtc] — a local midnight in UTC+N would otherwise
/// shift to the previous day.
abstract final class CalendarDate {
  static String toIso(DateTime date) {
    final local = date.isUtc ? date.toLocal() : date;
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
