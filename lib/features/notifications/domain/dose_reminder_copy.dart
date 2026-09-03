/// Body copy for a dose reminder. Matches the Spanish l10n templates.
String formatDoseReminderBody({
  required String medicationName,
  String? doseDisplay,
}) {
  final display = doseDisplay?.trim() ?? '';
  if (display.isEmpty) return 'Es hora de tomar $medicationName';
  return 'Es hora de tomar $medicationName ($display)';
}
