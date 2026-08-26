import 'package:drift/drift.dart';

/// Table tracking pending HTTP operations to sync to backend when online.
@DataClassName('OutboxData')
class OutboxTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get profileId => text()();

  TextColumn get entityType => text().withLength(min: 1, max: 32)();

  TextColumn get entityId => text()();

  TextColumn get clientId => text()();

  TextColumn get action => text().withLength(min: 1, max: 16)();

  TextColumn get payloadJson => text()();

  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  DateTimeColumn get createdAt => dateTime()();
}
