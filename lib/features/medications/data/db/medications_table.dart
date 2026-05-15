import 'package:drift/drift.dart';

class MedicationsTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text().withLength(min: 1, max: 120)();

  TextColumn get form => text().withLength(min: 1, max: 32)();

  TextColumn get category => text().withLength(min: 1, max: 80)();

  TextColumn get colorToken => text().withLength(min: 1, max: 80)();

  TextColumn get notes => text().nullable()();
}
