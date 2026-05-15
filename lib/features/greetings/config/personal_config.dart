/// Single source of truth for personal customization.
///
/// To release as a generic public app: set [userName] to null and
/// [showPersonalMessage] to false — the greeting screen will show only the
/// time-of-day salutation and the daily quote, with no personal content.
abstract final class PersonalConfig {
  static const bool showPersonalMessage = true;
  static const List<String> personalMessageLines = [
    'Eres única en este mundo y en mi vida.',
    'Eres más fuerte de lo que imaginas,',
    'más valiente de lo que crees.',
    'Tu sonrisa ilumina cada día,',
    'tu amor sostiene a esta familia.',
    'Vamos a salir adelante juntos —',
    'paso a paso, dosis a dosis, día a día.',
    'Te amamos infinitamente. ❤️',
  ];
}
