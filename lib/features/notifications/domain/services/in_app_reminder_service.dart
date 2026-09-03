import 'dart:developer' as developer;
import 'dart:async';
import 'dart:convert';
import 'package:my_pills/core/utils/log.dart';

import 'package:my_pills/features/notifications/domain/entities/in_app_banner.dart';
import 'package:my_pills/features/tracker/domain/entities/dose_event.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Emits [InAppBanner]s that are due for an in-app reminder.
///
/// Fires when `now` is between (scheduledAt - minutesBefore) and (scheduledAt + 1h).
/// Already-notified dose IDs are persisted per-day so the user is not
/// re-banner-bombed if the app restarts within the day.
class InAppReminderService {
  InAppReminderService({
    required Stream<List<DoseEvent>> todayDosesStream,
    required DateTime Function() clock,
    required SharedPreferences prefs,
    required int Function() minutesBefore,
    required String Function(int medicationId) medicationNameOf,
  }) : _todayDosesStream = todayDosesStream,
       _clock = clock,
       _prefs = prefs,
       _minutesBefore = minutesBefore,
       _medicationNameOf = medicationNameOf {
    _restoreNotifiedIds();
    _init();
  }

  final Stream<List<DoseEvent>> _todayDosesStream;
  final DateTime Function() _clock;
  final SharedPreferences _prefs;
  final int Function() _minutesBefore;
  final String Function(int medicationId) _medicationNameOf;

  static const String _prefsPrefix = 'mypills.reminded_doses_';
  static const Duration _checkInterval = Duration(seconds: 30);
  static const Duration _maxLateness = Duration(hours: 1);

  // Single-subscriber stream — buffers emissions until the StreamProvider
  // attaches its listener. A broadcast stream would drop events fired before
  // the first listener arrives, which happens during boot when a dose is
  // already in-window.
  final _bannerController = StreamController<InAppBanner>();
  Stream<InAppBanner> get banners => _bannerController.stream;

  StreamSubscription<List<DoseEvent>>? _dosesSubscription;
  Timer? _timer;
  List<DoseEvent> _currentDoses = const [];
  Set<int> _notifiedDoseIds = {};
  String _notifiedDay = '';

  // Diagnostics — read by the settings screen.
  DateTime? lastCheckAt;
  int firedToday = 0;
  Object? lastError;

  /// Snapshot of the next reminder we *expect* to fire, or null if none.
  ({int doseId, DateTime scheduledAt, DateTime fireAt})? nextReminder({
    DateTime Function()? clock,
  }) {
    final now = (clock ?? _clock)();
    final lead = Duration(minutes: _minutesBefore());
    final pending =
        _currentDoses
            .where(
              (d) =>
                  d.status == DoseStatus.pending &&
                  !_notifiedDoseIds.contains(d.id) &&
                  d.scheduledAt.add(_maxLateness).isAfter(now),
            )
            .toList()
          ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    if (pending.isEmpty) return null;
    final d = pending.first;
    return (
      doseId: d.id,
      scheduledAt: d.scheduledAt,
      fireAt: d.scheduledAt.subtract(lead),
    );
  }

  int get currentDosesCount => _currentDoses.length;
  int get pendingDosesCount =>
      _currentDoses.where((d) => d.status == DoseStatus.pending).length;

  String _dayKey(DateTime now) =>
      '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';

  void _restoreNotifiedIds() {
    final today = _dayKey(_clock());
    _notifiedDay = today;
    final raw = _prefs.getString('$_prefsPrefix$today');
    if (raw == null) {
      _notifiedDoseIds = {};
      _gcOldDays(today);
      return;
    }
    try {
      final list = (jsonDecode(raw) as List).cast<int>();
      _notifiedDoseIds = list.toSet();
    } catch (_) {
      _notifiedDoseIds = {};
    }
    _gcOldDays(today);
  }

  void _gcOldDays(String keepDay) {
    for (final key in _prefs.getKeys()) {
      if (key.startsWith(_prefsPrefix) && !key.endsWith(keepDay)) {
        _prefs.remove(key);
      }
    }
  }

  Future<void> _persistNotifiedIds() async {
    await _prefs.setString(
      '$_prefsPrefix$_notifiedDay',
      jsonEncode(_notifiedDoseIds.toList()),
    );
  }

  void _init() {
    _dosesSubscription = _todayDosesStream.listen(
      (doses) {
        _currentDoses = doses;
        _checkReminders();
      },
      onError: (Object e, StackTrace st) {
        developer.log(
          'todayDosesStream error: $e',
          name: 'mypills.inapp',
          error: e,
          stackTrace: st,
        );
      },
    );

    _timer = Timer.periodic(_checkInterval, (_) => _checkReminders());
  }

  /// Manual trigger — e.g. on app foreground or after settings change.
  void reevaluate() {
    _restoreNotifiedIds();
    _checkReminders();
  }

  void showBanner(InAppBanner banner) {
    _bannerController.add(banner);
  }

  void markNotified(int doseId) {
    if (_notifiedDoseIds.add(doseId)) {
      unawaited(_persistNotifiedIds());
    }
  }

  void fireDiagnosticTest() {
    mlog('mypills.inapp', 'fireDiagnosticTest');
    _bannerController.add(
      const InAppBanner(medicationName: 'Medicación'),
    );
  }

  void _checkReminders() {
    final now = _clock();
    lastCheckAt = now;
    final today = _dayKey(now);
    if (today != _notifiedDay) {
      _notifiedDay = today;
      _notifiedDoseIds = {};
      firedToday = 0;
      _gcOldDays(today);
    }

    final lead = Duration(minutes: _minutesBefore());
    final fired = <int>[];

    developer.log(
      'check now=$now doses=${_currentDoses.length} '
      'pending=${pendingDosesCount} notifiedSet=${_notifiedDoseIds.length}',
      name: 'mypills.inapp',
    );

    for (final dose in _currentDoses) {
      if (dose.status != DoseStatus.pending) {
        if (_notifiedDoseIds.add(dose.id)) fired.add(dose.id);
        continue;
      }
      if (_notifiedDoseIds.contains(dose.id)) continue;

      final start = dose.scheduledAt.subtract(lead);
      final end = dose.scheduledAt.add(_maxLateness);
      final inWindow = now.isAfter(start) && now.isBefore(end);
      developer.log(
        '  dose ${dose.id} scheduledAt=${dose.scheduledAt} '
        'window=[$start..$end) inWindow=$inWindow',
        name: 'mypills.inapp',
      );
      if (inWindow) {
        mlog('mypills.inapp', '  → firing');
        _notifiedDoseIds.add(dose.id);
        fired.add(dose.id);
        firedToday++;
        _bannerController.add(
          InAppBanner(
            medicationName: _medicationNameOf(dose.medicationId),
            doseDisplay: dose.dose?.display,
          ),
        );
      }
    }

    if (fired.isNotEmpty) {
      unawaited(_persistNotifiedIds());
    }
  }

  void dispose() {
    _dosesSubscription?.cancel();
    _timer?.cancel();
    _bannerController.close();
  }
}
