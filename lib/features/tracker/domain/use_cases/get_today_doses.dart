import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/core/utils/clock.dart';
import 'package:my_pills/features/tracker/domain/entities/dose_event.dart';
import 'package:my_pills/features/tracker/domain/repositories/dose_event_repository.dart';

/// Returns all dose events scheduled for the given date.
///
/// When `date` is omitted, `clock` is called to obtain the current moment.
/// Injecting `clock` (rather than calling `DateTime.now` directly) makes this
/// use case fully testable without patching global state.
class GetTodayDoses {
  GetTodayDoses(this._repository, {Clock? clock})
    : _clock = clock ?? DateTime.now;

  final DoseEventRepository _repository;
  final Clock _clock;

  Future<Result<List<DoseEvent>>> call({DateTime? date}) {
    final target = date ?? _clock();
    final day = DateTime(target.year, target.month, target.day);
    return _repository.getForDate(day);
  }
}
