import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:my_pills/features/medications/domain/entities/taxonomy_type.dart';

part 'taxonomy_group.freezed.dart';

@freezed
abstract class TaxonomyGroup with _$TaxonomyGroup {
  const factory TaxonomyGroup({
    required int id,
    required TaxonomyType type,
    required String name,
    required String description,
    required String iconName,
    required int colorValue,
  }) = _TaxonomyGroup;
}
