import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/core/utils/clock.dart';
import 'package:my_pills/features/tracker/domain/entities/dose_event.dart';
import 'package:my_pills/features/tracker/domain/repositories/dose_event_repository.dart';

/// Watches all dose events scheduled for the given date, emitting a new value
/// whenever the underlying data changes.
///
/// Use this use case (not `GetTodayDoses`) when the presentation layer needs a
/// reactive `StreamProvider` — for example, the Tracker screen rebuilding
/// automatically after a dose is marked taken or missed.
///
/// When `date` is omitted, `clock` is called to obtain the current moment.
/// Injecting `clock` keeps the use case fully testable without wall time.
class WatchTodayDoses {
  WatchTodayDoses(this._repository, {Clock? clock})
    : _clock = clock ?? DateTime.now;

  final DoseEventRepository _repository;
  final Clock _clock;

  Stream<Result<List<DoseEvent>>> call({DateTime? date}) {
    final target = date ?? _clock();
    final day = DateTime(target.year, target.month, target.day);
    return _repository.watchForDate(day);
  }
}
