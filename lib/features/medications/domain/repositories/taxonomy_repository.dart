import 'package:my_pills/features/medications/domain/entities/taxonomy_group.dart';
import 'package:my_pills/features/medications/domain/entities/taxonomy_type.dart';

abstract class TaxonomyRepository {
  Stream<List<TaxonomyGroup>> watchByType(TaxonomyType type);
  Future<void> addTaxonomyGroup(TaxonomyGroup taxonomyGroup);
  Future<void> updateTaxonomyGroup(TaxonomyGroup taxonomyGroup);
  Future<void> deleteTaxonomyGroup(int id);
}
