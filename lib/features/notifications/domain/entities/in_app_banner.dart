/// Payload for the in-app dose reminder overlay.
class InAppBanner {
  const InAppBanner({
    required this.medicationName,
    this.doseDisplay,
  });

  final String medicationName;
  final String? doseDisplay;
}
