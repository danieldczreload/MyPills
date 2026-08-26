import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:my_pills/core/db/app_database.dart';
import 'package:my_pills/core/sync/sync_engine.dart';
import 'package:my_pills/features/medications/data/db/taxonomy_groups_dao.dart';
import 'package:my_pills/features/medications/domain/entities/taxonomy_group.dart';
import 'package:my_pills/features/medications/domain/entities/taxonomy_type.dart';
import 'package:my_pills/features/medications/domain/repositories/taxonomy_repository.dart';
import 'package:uuid/uuid.dart';

class SyncedTaxonomyRepository implements TaxonomyRepository {
  SyncedTaxonomyRepository(
    this._dao,
    this._db,
    this._syncEngine,
    this._profileId,
  );

  final TaxonomyGroupsDao _dao;
  final AppDatabase _db;
  final SyncEngine _syncEngine;
  final String _profileId;
  static const _uuid = Uuid();

  @override
  Stream<List<TaxonomyGroup>> watchByType(TaxonomyType type) {
    return (_db.select(_db.taxonomyGroupsTable)..where(
          (t) =>
              t.type.equals(type.name) &
              t.isTombstone.equals(false) &
              t.profileId.equals(_profileId),
        ))
        .watch()
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
    final clientId = _uuid.v4();
    final id = await _dao.insertTaxonomyGroup(
      TaxonomyGroupsTableCompanion.insert(
        type: taxonomyGroup.type.name,
        name: taxonomyGroup.name,
        description: taxonomyGroup.description,
        iconName: taxonomyGroup.iconName,
        colorValue: taxonomyGroup.colorValue,
        clientId: Value(clientId),
        profileId: Value(_profileId),
        syncStatus: const Value('pending'),
        isTombstone: const Value(false),
      ),
    );

    await _db
        .into(_db.outboxTable)
        .insert(
          OutboxTableCompanion.insert(
            profileId: _profileId,
            entityType: 'taxonomy_group',
            entityId: id.toString(),
            clientId: clientId,
            action: 'CREATE',
            payloadJson: jsonEncode({
              'type': taxonomyGroup.type.name,
              'name': taxonomyGroup.name,
              'description': taxonomyGroup.description,
              'iconName': taxonomyGroup.iconName,
              'colorValue': taxonomyGroup.colorValue,
              'isCustom': true,
              'clientId': clientId,
            }),
            createdAt: DateTime.now().toUtc(),
          ),
        );

    unawaited(_syncEngine.flushOutbox());
  }

  @override
  Future<void> updateTaxonomyGroup(TaxonomyGroup taxonomyGroup) async {
    final row = await (_db.select(
      _db.taxonomyGroupsTable,
    )..where((t) => t.id.equals(taxonomyGroup.id))).getSingleOrNull();

    final clientId = row?.clientId ?? _uuid.v4();
    final serverId = row?.serverId;

    await _dao.updateTaxonomyGroup(
      taxonomyGroup.id,
      TaxonomyGroupsTableCompanion(
        name: Value(taxonomyGroup.name),
        description: Value(taxonomyGroup.description),
        iconName: Value(taxonomyGroup.iconName),
        colorValue: Value(taxonomyGroup.colorValue),
        syncStatus: const Value('pending'),
      ),
    );

    await _db
        .into(_db.outboxTable)
        .insert(
          OutboxTableCompanion.insert(
            profileId: _profileId,
            entityType: 'taxonomy_group',
            entityId: serverId ?? taxonomyGroup.id.toString(),
            clientId: clientId,
            action: 'UPDATE',
            payloadJson: jsonEncode({
              'type': taxonomyGroup.type.name,
              'name': taxonomyGroup.name,
              'description': taxonomyGroup.description,
              'iconName': taxonomyGroup.iconName,
              'colorValue': taxonomyGroup.colorValue,
              'isCustom': true,
              'clientId': clientId,
            }),
            createdAt: DateTime.now().toUtc(),
          ),
        );

    unawaited(_syncEngine.flushOutbox());
  }

  @override
  Future<void> deleteTaxonomyGroup(int id) async {
    final row = await (_db.select(
      _db.taxonomyGroupsTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();

    final clientId = row?.clientId ?? _uuid.v4();
    final serverId = row?.serverId;

    await (_db.update(_db.taxonomyGroupsTable)..where((t) => t.id.equals(id)))
        .write(const TaxonomyGroupsTableCompanion(isTombstone: Value(true)));

    await _db
        .into(_db.outboxTable)
        .insert(
          OutboxTableCompanion.insert(
            profileId: _profileId,
            entityType: 'taxonomy_group',
            entityId: serverId ?? id.toString(),
            clientId: clientId,
            action: 'DELETE',
            payloadJson: jsonEncode({}),
            createdAt: DateTime.now().toUtc(),
          ),
        );

    unawaited(_syncEngine.flushOutbox());
  }
}
