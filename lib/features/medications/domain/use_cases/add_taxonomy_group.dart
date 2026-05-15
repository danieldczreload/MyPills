import 'package:my_pills/features/medications/domain/entities/taxonomy_group.dart';
import 'package:my_pills/features/medications/domain/repositories/taxonomy_repository.dart';

class AddTaxonomyGroup {
  AddTaxonomyGroup(this._repository);
  final TaxonomyRepository _repository;

  Future<void> call(TaxonomyGroup taxonomyGroup) {
    return _repository.addTaxonomyGroup(taxonomyGroup);
  }
}
