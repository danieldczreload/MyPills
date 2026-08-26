import 'package:drift/drift.dart';

@DataClassName('TaxonomyGroupData')
class TaxonomyGroupsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()(); // 'category' or 'disease'
  TextColumn get name => text()();
  TextColumn get description => text()();
  TextColumn get iconName => text()(); // From health_icons
  IntColumn get colorValue => integer()();
  TextColumn get clientId => text().nullable()();
  TextColumn get profileId => text().withDefault(const Constant('default'))();
  TextColumn get serverId => text().nullable()();
  DateTimeColumn get serverUpdatedAt => dateTime().nullable()();
  TextColumn get syncStatus =>
      text().withDefault(const Constant('pending'))(); // pending | synced
  BoolColumn get isTombstone => boolean().withDefault(const Constant(false))();
}
