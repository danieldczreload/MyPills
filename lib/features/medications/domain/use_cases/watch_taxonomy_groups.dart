import 'package:my_pills/features/medications/domain/entities/taxonomy_group.dart';
import 'package:my_pills/features/medications/domain/entities/taxonomy_type.dart';
import 'package:my_pills/features/medications/domain/repositories/taxonomy_repository.dart';

class WatchTaxonomyGroups {
  WatchTaxonomyGroups(this._repository);
  final TaxonomyRepository _repository;

  Stream<List<TaxonomyGroup>> call(TaxonomyType type) {
    return _repository.watchByType(type);
  }
}
