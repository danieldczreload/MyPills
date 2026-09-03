/// Dio `RequestOptions.extra` flag: a 4xx/5xx is expected and must not be
/// logged as ERROR (best-effort calls such as logout).
const String kHttpBestEffortExtra = 'bestEffort';

/// Compact, token-safe description of an HTTP error body for debug logs.
///
/// JSON API errors collapse to `error.message`. HTML pages (Symfony
/// profiler dumps) collapse to `html: <title>` so a 404/500 never floods
/// `flutter run` with CSS and stack traces.
String summarizeHttpErrorBody(Object? body, {int maxChars = 240}) {
  if (body == null) {
    return '';
  }
  final jsonMessage = jsonServerErrorMessage(body);
  if (jsonMessage != null) {
    return _truncate(jsonMessage, maxChars);
  }
  final text = body is String ? body : body.toString();
  final trimmed = text.trimLeft();
  if (_looksLikeHtml(trimmed)) {
    final title = _htmlTitle(trimmed);
    return title == null
        ? 'html error page'
        : 'html: ${_truncate(_collapseWs(title), maxChars)}';
  }
  return _truncate(text, maxChars);
}

/// Message from a `{error: {message}}` JSON envelope, or null if absent.
String? jsonServerErrorMessage(Object? body) {
  if (body is! Map) {
    return null;
  }
  final error = body['error'];
  if (error is! Map) {
    return null;
  }
  final message = error['message']?.toString();
  if (message != null && message.isNotEmpty) {
    return message;
  }
  final type = error['type']?.toString();
  if (type != null && type.isNotEmpty) {
    return type;
  }
  return null;
}

bool _looksLikeHtml(String text) {
  final head = text.length > 32 ? text.substring(0, 32) : text;
  final lower = head.toLowerCase();
  return lower.startsWith('<!doctype') ||
      lower.startsWith('<html') ||
      lower.startsWith('<!--');
}

String? _htmlTitle(String html) {
  final match = RegExp(
    '<title>([^<]+)</title>',
    caseSensitive: false,
    dotAll: true,
  ).firstMatch(html);
  final title = match?.group(1)?.trim();
  if (title == null || title.isEmpty) {
    return null;
  }
  return title;
}

String _collapseWs(String value) => value.replaceAll(RegExp(r'\s+'), ' ');

String _truncate(String value, int maxChars) {
  if (value.length <= maxChars) {
    return value;
  }
  return '${value.substring(0, maxChars)}…';
}
