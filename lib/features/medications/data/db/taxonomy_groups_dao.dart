import 'package:drift/drift.dart';
import 'package:my_pills/core/db/app_database.dart';
import 'package:my_pills/features/medications/data/db/taxonomy_groups_table.dart';

part 'taxonomy_groups_dao.g.dart';

@DriftAccessor(tables: [TaxonomyGroupsTable])
class TaxonomyGroupsDao extends DatabaseAccessor<AppDatabase>
    with _$TaxonomyGroupsDaoMixin {
  TaxonomyGroupsDao(super.attachedDatabase);

  Stream<List<TaxonomyGroupData>> watchByType(
    String type, {
    String? profileId,
  }) {
    return (select(
          taxonomyGroupsTable,
        )..where(
          (t) =>
              t.isTombstone.equals(false) &
              t.type.equals(type) &
              (profileId != null
                  ? t.profileId.equals(profileId)
                  : const Constant(true)),
        ))
        .watch();
  }

  Future<int> insertTaxonomyGroup(TaxonomyGroupsTableCompanion group) {
    return into(taxonomyGroupsTable).insert(group);
  }

  Future<int> updateTaxonomyGroup(int id, TaxonomyGroupsTableCompanion group) {
    return (update(
      taxonomyGroupsTable,
    )..where((t) => t.id.equals(id))).write(group);
  }

  Future<int> deleteTaxonomyGroup(int id) {
    return (delete(taxonomyGroupsTable)..where((t) => t.id.equals(id))).go();
  }
}
