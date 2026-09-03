import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/features/schedules/domain/entities/dose_unit.dart';

/// Catalog of dose units from `GET /api/v1/dose-units`.
abstract interface class DoseUnitRepository {
  Future<Result<List<DoseUnit>>> getAll();
}
