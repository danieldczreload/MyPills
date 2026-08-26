import 'package:drift/drift.dart' show Value;
import 'package:my_pills/core/db/app_database.dart';
import 'package:my_pills/features/medications/data/db/taxonomy_groups_dao.dart';
import 'package:my_pills/features/medications/domain/entities/taxonomy_group.dart';
import 'package:my_pills/features/medications/domain/entities/taxonomy_type.dart';
import 'package:my_pills/features/medications/domain/repositories/taxonomy_repository.dart';

class TaxonomyRepositoryImpl implements TaxonomyRepository {
  TaxonomyRepositoryImpl(this._dao, {String profileId = 'default'})
    : _profileId = profileId;

  final TaxonomyGroupsDao _dao;
  final String _profileId;

  @override
  Stream<List<TaxonomyGroup>> watchByType(TaxonomyType type) {
    return _dao
        .watchByType(type.name, profileId: _profileId)
        .map(
          (list) => list
              .map(
                (data) => TaxonomyGroup(
                  id: data.id,
                  type: TaxonomyType.fromString(data.type),
                  name: data.name,
                  description: data.description,
                  iconName: data.iconName,
                  colorValue: data.colorValue,
                ),
              )
              .toList(),
        );
  }

  @override
  Future<void> addTaxonomyGroup(TaxonomyGroup taxonomyGroup) async {
    await _dao.insertTaxonomyGroup(
      TaxonomyGroupsTableCompanion.insert(
        type: taxonomyGroup.type.name,
        name: taxonomyGroup.name,
        description: taxonomyGroup.description,
        iconName: taxonomyGroup.iconName,
        colorValue: taxonomyGroup.colorValue,
        profileId: Value(_profileId),
      ),
    );
  }

  @override
  Future<void> updateTaxonomyGroup(TaxonomyGroup taxonomyGroup) async {
    await _dao.updateTaxonomyGroup(
      taxonomyGroup.id,
      TaxonomyGroupsTableCompanion(
        name: Value(taxonomyGroup.name),
        description: Value(taxonomyGroup.description),
        iconName: Value(taxonomyGroup.iconName),
        colorValue: Value(taxonomyGroup.colorValue),
      ),
    );
  }

  @override
  Future<void> deleteTaxonomyGroup(int id) async {
    await _dao.deleteTaxonomyGroup(id);
  }
}
