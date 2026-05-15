import 'package:drift/drift.dart';

@DataClassName('TaxonomyGroupData')
class TaxonomyGroupsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()(); // 'category' or 'disease'
  TextColumn get name => text()();
  TextColumn get description => text()();
  TextColumn get iconName => text()(); // From health_icons
  IntColumn get colorValue => integer()();
}
