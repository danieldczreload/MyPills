import 'package:drift/drift.dart';
import 'package:my_pills/core/db/app_database.dart';
import 'package:my_pills/features/medications/data/db/taxonomy_groups_table.dart';

part 'taxonomy_groups_dao.g.dart';

@DriftAccessor(tables: [TaxonomyGroupsTable])
class TaxonomyGroupsDao extends DatabaseAccessor<AppDatabase>
    with _$TaxonomyGroupsDaoMixin {
  TaxonomyGroupsDao(super.attachedDatabase);

  Stream<List<TaxonomyGroupData>> watchByType(String type) {
    return (select(
      taxonomyGroupsTable,
    )..where((t) => t.type.equals(type))).watch();
  }

  Future<int> insertTaxonomyGroup(TaxonomyGroupsTableCompanion group) {
    return into(taxonomyGroupsTable).insert(group);
  }

  Future<int> deleteTaxonomyGroup(int id) {
    return (delete(taxonomyGroupsTable)..where((t) => t.id.equals(id))).go();
  }
}
