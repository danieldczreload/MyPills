import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/core/utils/clock.dart';
import 'package:my_pills/features/tracker/domain/repositories/dose_event_repository.dart';

/// Marks a dose as taken at the current moment.
///
/// `clock` is injected so tests can assert against a fixed timestamp instead
/// of relying on wall time.
class MarkDoseTaken {
  MarkDoseTaken(this._repository, {Clock? clock})
    : _clock = clock ?? DateTime.now;

  final DoseEventRepository _repository;
  final Clock _clock;

  Future<Result<void>> call(int id) => _repository.markTaken(id, _clock());
}
