import 'package:my_pills/app/providers.dart';
import 'package:my_pills/features/medications/data/db/taxonomy_groups_dao.dart';
import 'package:my_pills/features/medications/data/repositories/taxonomy_repository_impl.dart';
import 'package:my_pills/features/medications/domain/entities/taxonomy_group.dart';
import 'package:my_pills/features/medications/domain/entities/taxonomy_type.dart';
import 'package:my_pills/features/medications/domain/repositories/taxonomy_repository.dart';
import 'package:my_pills/features/medications/domain/use_cases/add_taxonomy_group.dart';
import 'package:my_pills/features/medications/domain/use_cases/watch_taxonomy_groups.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'taxonomy_providers.g.dart';

@riverpod
TaxonomyRepository taxonomyRepository(Ref ref) {
  final db = ref.watch(databaseProvider);
  return TaxonomyRepositoryImpl(TaxonomyGroupsDao(db));
}

@riverpod
WatchTaxonomyGroups watchTaxonomyGroups(Ref ref) {
  return WatchTaxonomyGroups(ref.watch(taxonomyRepositoryProvider));
}

@riverpod
AddTaxonomyGroup addTaxonomyGroup(Ref ref) {
  return AddTaxonomyGroup(ref.watch(taxonomyRepositoryProvider));
}

@riverpod
Stream<List<TaxonomyGroup>> taxonomyGroupsByType(Ref ref, TaxonomyType type) {
  return ref.watch(watchTaxonomyGroupsProvider).call(type);
}
