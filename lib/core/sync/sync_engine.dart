import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:my_pills/core/db/app_database.dart';
import 'package:my_pills/core/errors/failure.dart';
import 'package:my_pills/core/network/api_client.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/features/schedules/data/mappers/dose_mapper.dart';
import 'package:my_pills/features/schedules/domain/entities/dose.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Offline-first synchronization engine handling delta sync and outbox queue.
class SyncEngine {
  SyncEngine({
    required ApiClient apiClient,
    required AppDatabase db,
    required SharedPreferences prefs,
  }) : _apiClient = apiClient,
       _db = db,
       _prefs = prefs;

  final ApiClient _apiClient;
  final AppDatabase _db;
  final SharedPreferences _prefs;

  static const String _syncCursorPrefix = 'sync_cursor_profile_';

  /// Performs incremental delta sync for a patient profile.
  Future<Result<void>> syncProfile(String profileId) async {
    try {
      final lastSync = _prefs.getString('$_syncCursorPrefix$profileId');
      final path = lastSync != null && lastSync.isNotEmpty
          ? '/profiles/$profileId/sync?since=${Uri.encodeComponent(lastSync)}'
          : '/profiles/$profileId/sync';

      final response = await _apiClient.dio.get<Map<String, dynamic>>(path);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!;
        final medications = (data['medications'] as List<dynamic>?) ?? [];
        final schedules = (data['schedules'] as List<dynamic>?) ?? [];
        final doseEvents = (data['doseEvents'] as List<dynamic>?) ?? [];
        final taxonomyGroups = (data['taxonomyGroups'] as List<dynamic>?) ?? [];
        final tombstones = (data['tombstones'] as List<dynamic>?) ?? [];

        final nowIso = DateTime.now().toUtc().toIso8601String();

        await _db.transaction(() async {
          // 1. Process Upserts: Medications -> Schedules -> DoseEvents -> TaxonomyGroups
          for (final med in medications) {
            if (med is Map<String, dynamic>) {
              await _upsertMedication(med, profileId: profileId);
            }
          }
          for (final sched in schedules) {
            if (sched is Map<String, dynamic>) {
              await _upsertSchedule(sched, profileId: profileId);
            }
          }
          for (final dose in doseEvents) {
            if (dose is Map<String, dynamic>) {
              await _upsertDoseEvent(dose, profileId: profileId);
            }
          }
          for (final tax in taxonomyGroups) {
            if (tax is Map<String, dynamic>) {
              await _upsertTaxonomyGroup(tax, profileId: profileId);
            }
          }

          // 2. Process Tombstones
          for (final tomb in tombstones) {
            if (tomb is Map<String, dynamic>) {
              await _applyTombstone(tomb);
            }
          }
        });

        // 3. Save sync cursor after successful commit
        await _prefs.setString('$_syncCursorPrefix$profileId', nowIso);
        return const Result.success(null);
      }
      return const Result.failure(
        Failure.server(statusCode: 500, message: 'Invalid sync response'),
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        return const Result.failure(Failure.network());
      }
      return FailureResult(
        Failure.server(
          statusCode: e.response?.statusCode ?? 500,
          message: e.message,
        ),
      );
    } catch (e, st) {
      return Result.failure(Failure.unexpected(error: e, stackTrace: st));
    }
  }

  /// Flushes pending outbox operations to backend.
  Future<Result<void>> flushOutbox() async {
    try {
      final pendingOps = await _db.select(_db.outboxTable).get();

      for (final op in pendingOps) {
        final success = await _executeOutboxOp(op);
        if (success) {
          await (_db.delete(
            _db.outboxTable,
          )..where((t) => t.id.equals(op.id))).go();
        }
      }
      return const Result.success(null);
    } catch (e, st) {
      return Result.failure(Failure.unexpected(error: e, stackTrace: st));
    }
  }

  /// Fetches profiles associated with the authenticated account and syncs the first one.
  Future<Result<String?>> fetchAndRestoreProfiles() async {
    try {
      final response = await _apiClient.dio.get<List<dynamic>>('/profiles');
      if (response.statusCode == 200 && response.data != null) {
        final list = response.data!;
        if (list.isNotEmpty) {
          final profileObjects = list.map((item) {
            final map = item as Map<String, dynamic>;
            return {
              'id': map['id'] as String? ?? 'default',
              'name': map['name'] as String? ?? 'Usuario',
              'birthDate': map['birthDate'] as String? ?? '2000-01-01',
              'gender': map['gender'] as String? ?? 'other',
              'photoPath': map['photoUrl'] as String?,
              'isDefault': map['isDefault'] as bool? ?? false,
            };
          }).toList();
          await _prefs.setString(
            'profiles_list_json',
            jsonEncode(profileObjects),
          );

          final first = list.first as Map<String, dynamic>;
          final profileId = first['id'] as String?;
          if (profileId != null) {
            await _prefs.setString('active_profile_id', profileId);
            final name = first['name'] as String? ?? 'Usuario';
            final gender = first['gender'] as String? ?? 'other';
            final birthDateStr = first['birthDate'] as String?;
            final birthDate = birthDateStr != null
                ? DateTime.tryParse(birthDateStr) ?? DateTime(1990)
                : DateTime(1990);
            final photoUrl = first['photoUrl'] as String?;
            await _prefs.setString('profile.name', name);
            await _prefs.setString('profile.gender', gender);
            await _prefs.setString(
              'profile.birth_date',
              birthDate.toIso8601String(),
            );
            if (photoUrl != null && photoUrl.isNotEmpty) {
              await _prefs.setString('profile.photo_path', photoUrl);
            } else {
              await _prefs.remove('profile.photo_path');
            }
            await _prefs.setBool('profile.onboarding_complete', true);

            await syncProfile(profileId);
            return Result.success(profileId);
          }
        } else {
          final localName = _prefs.getString('profile.name') ?? 'Usuario';
          final localGender = _prefs.getString('profile.gender') ?? 'other';
          final localBirthDateStr = _prefs.getString('profile.birth_date');
          final localPhoto = _prefs.getString('profile.photo_path');
          final createRes = await _apiClient.dio.post<Map<String, dynamic>>(
            '/profiles',
            data: {
              'name': localName,
              'birthDate': localBirthDateStr != null
                  ? localBirthDateStr.split('T').first
                  : '1990-01-01',
              'gender': localGender,
              'timezone': DateTime.now().timeZoneName,
              if (localPhoto != null) 'photoUrl': localPhoto,
            },
          );
          if (createRes.statusCode == 201 && createRes.data != null) {
            final profileId = createRes.data!['id'] as String?;
            if (profileId != null) {
              await _prefs.setString('active_profile_id', profileId);
              final profileObjects = [
                {
                  'id': profileId,
                  'name': localName,
                  'birthDate': localBirthDateStr ?? '1990-01-01',
                  'gender': localGender,
                  'photoPath': localPhoto,
                  'isDefault': true,
                },
              ];
              await _prefs.setString(
                'profiles_list_json',
                jsonEncode(profileObjects),
              );
              await syncProfile(profileId);
              return Result.success(profileId);
            }
          }
        }
      }
      return const Result.success(null);
    } on DioException catch (e) {
      return Result.failure(
        Failure.server(
          statusCode: e.response?.statusCode ?? 500,
          message: e.message,
        ),
      );
    } catch (e, st) {
      return Result.failure(Failure.unexpected(error: e, stackTrace: st));
    }
  }

  Future<bool> _executeOutboxOp(OutboxData op) async {
    try {
      final payload = jsonDecode(op.payloadJson) as Map<String, dynamic>;
      late Response<dynamic> response;
      final activeProfileId =
          _prefs.getString('active_profile_id') ?? op.profileId;

      if (op.entityType == 'profile') {
        if (op.action == 'CREATE') {
          response = await _apiClient.dio.post<Map<String, dynamic>>(
            '/profiles',
            data: payload,
          );
          if (response.statusCode == 201 && response.data != null) {
            final serverProfileId = response.data!['id'] as String?;
            if (serverProfileId != null) {
              await _prefs.setString('active_profile_id', serverProfileId);
            }
          }
        } else if (op.action == 'UPDATE') {
          if (activeProfileId == 'default') return false;
          response = await _apiClient.dio.patch<dynamic>(
            '/profiles/$activeProfileId',
            data: payload,
          );
        } else if (op.action == 'DELETE') {
          if (activeProfileId == 'default') return false;
          response = await _apiClient.dio.delete<dynamic>(
            '/profiles/$activeProfileId',
          );
        }
      } else if (op.entityType == 'medication') {
        if (activeProfileId == 'default') return false;
        if (op.action == 'CREATE') {
          response = await _apiClient.dio.post<Map<String, dynamic>>(
            '/profiles/$activeProfileId/medications',
            data: payload,
          );
          if (response.statusCode == 201 && response.data != null) {
            final serverId = response.data!['id'] as String?;
            final serverUpdatedAtStr = response.data!['updatedAt'] as String?;
            final serverUpdatedAt = serverUpdatedAtStr != null
                ? DateTime.tryParse(serverUpdatedAtStr)
                : null;
            if (serverId != null) {
              await (_db.update(
                _db.medicationsTable,
              )..where((t) => t.clientId.equals(op.clientId))).write(
                MedicationsTableCompanion(
                  serverId: Value(serverId),
                  serverUpdatedAt: Value(serverUpdatedAt),
                  syncStatus: const Value('synced'),
                ),
              );
            }
          }
        } else if (op.action == 'UPDATE') {
          var targetId = op.entityId;
          final medRow = await (_db.select(
            _db.medicationsTable,
          )..where((t) => t.clientId.equals(op.clientId))).getSingleOrNull();
          if (medRow?.serverId != null) {
            targetId = medRow!.serverId!;
          }
          response = await _apiClient.dio.patch<dynamic>(
            '/profiles/$activeProfileId/medications/$targetId',
            data: payload,
          );
        } else if (op.action == 'DELETE') {
          var targetId = op.entityId;
          final medRow = await (_db.select(
            _db.medicationsTable,
          )..where((t) => t.clientId.equals(op.clientId))).getSingleOrNull();
          if (medRow?.serverId != null) {
            targetId = medRow!.serverId!;
          }
          response = await _apiClient.dio.delete<dynamic>(
            '/profiles/$activeProfileId/medications/$targetId',
          );
        }
      } else if (op.entityType == 'schedule') {
        if (activeProfileId == 'default') return false;
        if (op.action == 'CREATE') {
          final scheduleData = Map<String, dynamic>.from(payload);
          if (scheduleData.containsKey('localMedicationId')) {
            final localMedId = scheduleData['localMedicationId'] as int;
            final medRow = await _db.medicationDao.getMedicationById(
              localMedId,
            );
            if (medRow?.serverId != null) {
              scheduleData['medicationId'] = medRow!.serverId!;
            }
            scheduleData.remove('localMedicationId');
          }
          response = await _apiClient.dio.post<Map<String, dynamic>>(
            '/profiles/$activeProfileId/schedules',
            data: scheduleData,
          );
          if (response.statusCode == 201 && response.data != null) {
            final serverId = response.data!['id'] as String?;
            final serverUpdatedAtStr = response.data!['updatedAt'] as String?;
            final serverUpdatedAt = serverUpdatedAtStr != null
                ? DateTime.tryParse(serverUpdatedAtStr)
                : null;
            final serverDose = DoseFields.of(parseDose(response.data!['dose']));
            if (serverId != null) {
              await (_db.update(
                _db.schedulesTable,
              )..where((t) => t.clientId.equals(op.clientId))).write(
                SchedulesTableCompanion(
                  serverId: Value(serverId),
                  serverUpdatedAt: Value(serverUpdatedAt),
                  syncStatus: const Value('synced'),
                  doseAmount: serverDose.amountValue,
                  doseUnit: serverDose.unitValue,
                  doseDisplay: serverDose.displayValue,
                ),
              );
            }
          }
        } else if (op.action == 'DELETE') {
          var targetId = op.entityId;
          final schedRow = await (_db.select(
            _db.schedulesTable,
          )..where((t) => t.clientId.equals(op.clientId))).getSingleOrNull();
          if (schedRow?.serverId != null) {
            targetId = schedRow!.serverId!;
          }
          response = await _apiClient.dio.delete<dynamic>(
            '/profiles/$activeProfileId/schedules/$targetId',
          );
        } else if (op.action == 'CANCEL_RECURRING') {
          var targetId = op.entityId;
          final schedRow = await (_db.select(
            _db.schedulesTable,
          )..where((t) => t.clientId.equals(op.clientId))).getSingleOrNull();
          if (schedRow?.serverId != null) {
            targetId = schedRow!.serverId!;
          }
          final serverMedId = payload['medicationId'] as String?;
          final hasValidServerSchedId =
              targetId.isNotEmpty &&
              (targetId.contains('-') || schedRow?.serverId != null);
          final hasValidServerMedId =
              serverMedId != null &&
              serverMedId.isNotEmpty &&
              serverMedId.contains('-');

          // If targeting a local-only entity that never existed on the server, skip server call
          if (op.entityId.isNotEmpty &&
              !hasValidServerSchedId &&
              (payload['medicationId'] != null && !hasValidServerMedId)) {
            return true;
          }

          final reqBody = <String, dynamic>{
            'cancelPush': payload['cancelPush'] ?? true,
            'cancelCalendar': payload['cancelCalendar'] ?? true,
            'deleteSchedule': payload['deleteSchedule'] ?? false,
          };
          if (hasValidServerSchedId) {
            reqBody['scheduleId'] = targetId;
          }
          if (hasValidServerMedId) {
            reqBody['medicationId'] = serverMedId;
          }
          response = await _apiClient.dio.post<dynamic>(
            '/profiles/$activeProfileId/notifications/cancel-recurring',
            data: reqBody,
          );
        }
      } else if (op.entityType == 'dose_event') {
        if (activeProfileId == 'default') return false;
        if (op.action == 'DELETE' || op.action == 'CANCEL_NOTIFICATION') {
          var targetId = op.entityId;
          final doseRow = await (_db.select(
            _db.doseEventsTable,
          )..where((t) => t.clientId.equals(op.clientId))).getSingleOrNull();
          if (doseRow?.serverId != null) {
            targetId = doseRow!.serverId!;
          }
          if (payload.containsKey('serverId') && payload['serverId'] != null) {
            targetId = payload['serverId'].toString();
          }

          // If the dose was only local (never had a serverId), no server call is needed
          if (targetId.isEmpty ||
              (int.tryParse(targetId) != null &&
                  !targetId.contains('-') &&
                  doseRow?.serverId == null)) {
            return true;
          }

          response = await _apiClient.dio.post<dynamic>(
            '/profiles/$activeProfileId/notifications/$targetId/cancel',
            data: {
              'cancelPush': payload['cancelPush'] ?? true,
              'cancelCalendar': payload['cancelCalendar'] ?? true,
            },
          );
        } else {
          // Dose event tracking via POST /profiles/{id}/dose-events
          final doseData = Map<String, dynamic>.from(payload);
          if (doseData.containsKey('localScheduleId')) {
            final localSchedId = doseData['localScheduleId'] as int;
            final schedRow = await _db.scheduleDao.getScheduleById(
              localSchedId,
            );
            if (schedRow?.serverId != null) {
              doseData['scheduleId'] = schedRow!.serverId!;
            }
            doseData.remove('localScheduleId');
          }

          response = await _apiClient.dio.post<Map<String, dynamic>>(
            '/profiles/$activeProfileId/dose-events',
            data: doseData,
          );
          if (response.statusCode == 201 && response.data != null) {
            final serverId = response.data!['id'] as String?;
            final serverUpdatedAtStr = response.data!['updatedAt'] as String?;
            final serverUpdatedAt = serverUpdatedAtStr != null
                ? DateTime.tryParse(serverUpdatedAtStr)
                : null;
            if (serverId != null) {
              await (_db.update(
                _db.doseEventsTable,
              )..where((t) => t.clientId.equals(op.clientId))).write(
                DoseEventsTableCompanion(
                  serverId: Value(serverId),
                  serverUpdatedAt: Value(serverUpdatedAt),
                  syncStatus: const Value('synced'),
                ),
              );
            }
          }
        }
      } else if (op.entityType == 'taxonomy_group') {
        if (activeProfileId == 'default') return false;
        if (op.action == 'CREATE') {
          response = await _apiClient.dio.post<Map<String, dynamic>>(
            '/profiles/$activeProfileId/taxonomy-groups',
            data: payload,
          );
          if (response.statusCode == 201 && response.data != null) {
            final serverId = response.data!['id'] as String?;
            final serverUpdatedAtStr = response.data!['updatedAt'] as String?;
            final serverUpdatedAt = serverUpdatedAtStr != null
                ? DateTime.tryParse(serverUpdatedAtStr)
                : null;
            if (serverId != null) {
              await (_db.update(
                _db.taxonomyGroupsTable,
              )..where((t) => t.clientId.equals(op.clientId))).write(
                TaxonomyGroupsTableCompanion(
                  serverId: Value(serverId),
                  serverUpdatedAt: Value(serverUpdatedAt),
                  syncStatus: const Value('synced'),
                ),
              );
            }
          }
        } else if (op.action == 'UPDATE') {
          var targetId = op.entityId;
          final taxRow = await (_db.select(
            _db.taxonomyGroupsTable,
          )..where((t) => t.clientId.equals(op.clientId))).getSingleOrNull();
          if (taxRow?.serverId != null) {
            targetId = taxRow!.serverId!;
          }
          response = await _apiClient.dio.patch<dynamic>(
            '/profiles/$activeProfileId/taxonomy-groups/$targetId',
            data: payload,
          );
        } else if (op.action == 'DELETE') {
          var targetId = op.entityId;
          final taxRow = await (_db.select(
            _db.taxonomyGroupsTable,
          )..where((t) => t.clientId.equals(op.clientId))).getSingleOrNull();
          if (taxRow?.serverId != null) {
            targetId = taxRow!.serverId!;
          }
          response = await _apiClient.dio.delete<dynamic>(
            '/profiles/$activeProfileId/taxonomy-groups/$targetId',
          );
        }
      }

      return response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300;
    } catch (_) {
      return false;
    }
  }

  Future<void> _upsertMedication(
    Map<String, dynamic> json, {
    String profileId = 'default',
  }) async {
    final serverId = json['id']?.toString();
    final clientId = json['clientId'] as String? ?? serverId;
    final name = json['name'] as String? ?? 'Desconocido';
    final instructions = json['instructions'] as String?;
    final form = json['form'] as String? ?? 'pill';
    final colorToken = json['colorToken'] as String? ?? 'sky';
    final serverUpdatedAtStr =
        json['updatedAt'] as String? ?? json['serverUpdatedAt'] as String?;
    final serverUpdatedAt = serverUpdatedAtStr != null
        ? DateTime.tryParse(serverUpdatedAtStr)
        : null;

    MedicationsTableData? existing;
    if (serverId != null) {
      existing = await (_db.select(
        _db.medicationsTable,
      )..where((t) => t.serverId.equals(serverId))).getSingleOrNull();
    }
    if (existing == null && clientId != null) {
      existing = await (_db.select(
        _db.medicationsTable,
      )..where((t) => t.clientId.equals(clientId))).getSingleOrNull();
    }

    if (existing != null) {
      await (_db.update(
        _db.medicationsTable,
      )..where((t) => t.id.equals(existing!.id))).write(
        MedicationsTableCompanion(
          name: Value(name),
          form: Value(form),
          colorToken: Value(colorToken),
          notes: Value(instructions),
          serverId: Value(serverId),
          clientId: Value(clientId),
          profileId: Value(profileId),
          serverUpdatedAt: Value(serverUpdatedAt),
          syncStatus: const Value('synced'),
          isTombstone: const Value(false),
        ),
      );
    } else {
      await _db
          .into(_db.medicationsTable)
          .insert(
            MedicationsTableCompanion.insert(
              name: name,
              form: form,
              category: 'General',
              colorToken: colorToken,
              notes: Value(instructions),
              clientId: Value(clientId),
              serverId: Value(serverId),
              profileId: Value(profileId),
              serverUpdatedAt: Value(serverUpdatedAt),
              syncStatus: const Value('synced'),
              isTombstone: const Value(false),
            ),
          );
    }
  }

  Future<void> _upsertSchedule(
    Map<String, dynamic> json, {
    String profileId = 'default',
  }) async {
    final serverId = json['id']?.toString();
    final serverMedicationId = json['medicationId']?.toString();
    final clientId = json['clientId'] as String? ?? serverId;
    final ruleType =
        json['type'] as String? ?? json['ruleType'] as String? ?? 'daily';

    // Map rule json format
    final Map<String, dynamic> ruleMap = {};
    if (json.containsKey('timesOfDay')) {
      ruleMap['timesOfDay'] = json['timesOfDay'];
    }
    if (json.containsKey('everyHours')) {
      ruleMap['everyHours'] = json['everyHours'];
    }
    if (json.containsKey('startAt')) {
      ruleMap['startAt'] = json['startAt'];
    }
    if (json.containsKey('endAt')) {
      ruleMap['endAt'] = json['endAt'];
    }
    if (json.containsKey('daysOfWeek')) {
      ruleMap['daysOfWeek'] = json['daysOfWeek'];
    }
    final ruleJson = jsonEncode(ruleMap);

    final startDateUtcStr =
        json['startDate'] as String? ?? json['startDateUtc'] as String?;
    final startDateUtc = startDateUtcStr != null
        ? DateTime.parse(startDateUtcStr).toUtc()
        : DateTime.now().toUtc();
    final endDateUtcStr =
        json['endDate'] as String? ?? json['endDateUtc'] as String?;
    final endDateUtc = endDateUtcStr != null
        ? DateTime.parse(endDateUtcStr).toUtc()
        : null;
    final serverUpdatedAtStr =
        json['updatedAt'] as String? ?? json['serverUpdatedAt'] as String?;
    final serverUpdatedAt = serverUpdatedAtStr != null
        ? DateTime.tryParse(serverUpdatedAtStr)
        : null;

    // Find local medication
    MedicationsTableData? localMed;
    if (serverMedicationId != null) {
      localMed = await (_db.select(
        _db.medicationsTable,
      )..where((t) => t.serverId.equals(serverMedicationId))).getSingleOrNull();
      localMed ??= await (_db.select(
        _db.medicationsTable,
      )..where((t) => t.clientId.equals(serverMedicationId))).getSingleOrNull();
    }

    if (localMed == null) {
      // Skip schedule if parent medication does not exist locally to avoid foreign key failure
      return;
    }

    final medicationId = localMed.id;
    final dose = DoseFields.of(parseDose(json['dose']));

    SchedulesTableData? existing;
    if (serverId != null) {
      existing = await (_db.select(
        _db.schedulesTable,
      )..where((t) => t.serverId.equals(serverId))).getSingleOrNull();
    }
    if (existing == null && clientId != null) {
      existing = await (_db.select(
        _db.schedulesTable,
      )..where((t) => t.clientId.equals(clientId))).getSingleOrNull();
    }

    if (existing != null) {
      await (_db.update(
        _db.schedulesTable,
      )..where((t) => t.id.equals(existing!.id))).write(
        SchedulesTableCompanion(
          medicationId: Value(medicationId),
          ruleType: Value(ruleType),
          ruleJson: Value(ruleJson),
          startDateUtc: Value(startDateUtc),
          endDateUtc: Value(endDateUtc),
          doseAmount: dose.amountValue,
          doseUnit: dose.unitValue,
          doseDisplay: dose.displayValue,
          serverId: Value(serverId),
          clientId: Value(clientId),
          profileId: Value(profileId),
          serverUpdatedAt: Value(serverUpdatedAt),
          syncStatus: const Value('synced'),
          isTombstone: const Value(false),
        ),
      );
    } else {
      await _db
          .into(_db.schedulesTable)
          .insert(
            SchedulesTableCompanion.insert(
              medicationId: medicationId,
              ruleType: ruleType,
              ruleJson: ruleJson,
              startDateUtc: startDateUtc,
              endDateUtc: Value(endDateUtc),
              doseAmount: dose.amountValue,
              doseUnit: dose.unitValue,
              doseDisplay: dose.displayValue,
              clientId: Value(clientId),
              serverId: Value(serverId),
              profileId: Value(profileId),
              serverUpdatedAt: Value(serverUpdatedAt),
              syncStatus: const Value('synced'),
              isTombstone: const Value(false),
            ),
          );
    }
  }

  Future<void> _upsertDoseEvent(
    Map<String, dynamic> json, {
    String profileId = 'default',
  }) async {
    final serverId = json['id']?.toString();
    final serverScheduleId = json['scheduleId']?.toString();
    final serverMedicationId = json['medicationId']?.toString();
    final scheduledAtUtcStr =
        json['scheduledAt'] as String? ?? json['scheduledAtUtc'] as String?;
    final scheduledAtUtc = scheduledAtUtcStr != null
        ? DateTime.parse(scheduledAtUtcStr).toUtc()
        : DateTime.now().toUtc();
    final status = json['status'] as String? ?? 'pending';
    final takenAtUtcStr =
        json['takenAt'] as String? ?? json['takenAtUtc'] as String?;
    final takenAtUtc = takenAtUtcStr != null
        ? DateTime.parse(takenAtUtcStr).toUtc()
        : null;
    final clientId = json['clientId'] as String? ?? serverId;
    final serverUpdatedAtStr =
        json['updatedAt'] as String? ?? json['serverUpdatedAt'] as String?;
    final serverUpdatedAt = serverUpdatedAtStr != null
        ? DateTime.tryParse(serverUpdatedAtStr)
        : null;

    SchedulesTableData? localSchedule;
    if (serverScheduleId != null) {
      localSchedule = await (_db.select(
        _db.schedulesTable,
      )..where((t) => t.serverId.equals(serverScheduleId))).getSingleOrNull();
      localSchedule ??= await (_db.select(
        _db.schedulesTable,
      )..where((t) => t.clientId.equals(serverScheduleId))).getSingleOrNull();
    }

    MedicationsTableData? localMedication;
    if (serverMedicationId != null) {
      localMedication = await (_db.select(
        _db.medicationsTable,
      )..where((t) => t.serverId.equals(serverMedicationId))).getSingleOrNull();
      localMedication ??= await (_db.select(
        _db.medicationsTable,
      )..where((t) => t.clientId.equals(serverMedicationId))).getSingleOrNull();
    }

    if (localSchedule == null) {
      // Skip dose event if parent schedule does not exist locally
      return;
    }

    final scheduleId = localSchedule.id;
    final medicationId = localMedication?.id ?? localSchedule.medicationId;
    final dose = DoseFields.of(parseDose(json['dose']));

    DoseEventsTableData? existing;
    if (serverId != null) {
      existing = await (_db.select(
        _db.doseEventsTable,
      )..where((t) => t.serverId.equals(serverId))).getSingleOrNull();
    }
    if (existing == null && clientId != null) {
      existing = await (_db.select(
        _db.doseEventsTable,
      )..where((t) => t.clientId.equals(clientId))).getSingleOrNull();
    }
    if (existing == null) {
      existing =
          await (_db.select(_db.doseEventsTable)..where(
                (t) =>
                    t.scheduleId.equals(scheduleId) &
                    t.scheduledAtUtc.equals(scheduledAtUtc),
              ))
              .getSingleOrNull();
    }

    if (existing != null) {
      await (_db.update(
        _db.doseEventsTable,
      )..where((t) => t.id.equals(existing!.id))).write(
        DoseEventsTableCompanion(
          medicationId: Value(medicationId),
          scheduleId: Value(scheduleId),
          scheduledAtUtc: Value(scheduledAtUtc),
          status: Value(status),
          takenAtUtc: Value(takenAtUtc),
          doseAmount: dose.amountValue,
          doseUnit: dose.unitValue,
          doseDisplay: dose.displayValue,
          serverId: Value(serverId),
          clientId: Value(clientId),
          profileId: Value(profileId),
          serverUpdatedAt: Value(serverUpdatedAt),
          syncStatus: const Value('synced'),
          isTombstone: const Value(false),
        ),
      );
    } else {
      await _db
          .into(_db.doseEventsTable)
          .insert(
            DoseEventsTableCompanion.insert(
              medicationId: medicationId,
              scheduleId: scheduleId,
              scheduledAtUtc: scheduledAtUtc,
              status: status,
              takenAtUtc: Value(takenAtUtc),
              doseAmount: dose.amountValue,
              doseUnit: dose.unitValue,
              doseDisplay: dose.displayValue,
              clientId: Value(clientId),
              serverId: Value(serverId),
              profileId: Value(profileId),
              serverUpdatedAt: Value(serverUpdatedAt),
              syncStatus: const Value('synced'),
              isTombstone: const Value(false),
            ),
          );
    }
  }

  Future<void> _upsertTaxonomyGroup(
    Map<String, dynamic> json, {
    String profileId = 'default',
  }) async {
    final serverId = json['id']?.toString();
    final clientId = json['clientId'] as String? ?? serverId;
    final type = json['type'] as String? ?? 'category';
    final name = json['name'] as String? ?? '';
    final description = json['description'] as String? ?? '';
    final iconName = json['iconName'] as String? ?? 'medicines';
    final colorValue = json['colorValue'] as int? ?? 0xFF1F108E;
    final serverUpdatedAtStr =
        json['updatedAt'] as String? ?? json['serverUpdatedAt'] as String?;
    final serverUpdatedAt = serverUpdatedAtStr != null
        ? DateTime.tryParse(serverUpdatedAtStr)
        : null;

    TaxonomyGroupData? existing;
    if (serverId != null) {
      existing = await (_db.select(
        _db.taxonomyGroupsTable,
      )..where((t) => t.serverId.equals(serverId))).getSingleOrNull();
    }
    if (existing == null && clientId != null) {
      existing = await (_db.select(
        _db.taxonomyGroupsTable,
      )..where((t) => t.clientId.equals(clientId))).getSingleOrNull();
    }

    if (existing != null) {
      await (_db.update(
        _db.taxonomyGroupsTable,
      )..where((t) => t.id.equals(existing!.id))).write(
        TaxonomyGroupsTableCompanion(
          type: Value(type),
          name: Value(name),
          description: Value(description),
          iconName: Value(iconName),
          colorValue: Value(colorValue),
          serverId: Value(serverId),
          clientId: Value(clientId),
          profileId: Value(profileId),
          serverUpdatedAt: Value(serverUpdatedAt),
          syncStatus: const Value('synced'),
          isTombstone: const Value(false),
        ),
      );
    } else {
      await _db
          .into(_db.taxonomyGroupsTable)
          .insert(
            TaxonomyGroupsTableCompanion.insert(
              type: type,
              name: name,
              description: description,
              iconName: iconName,
              colorValue: colorValue,
              clientId: Value(clientId),
              serverId: Value(serverId),
              profileId: Value(profileId),
              serverUpdatedAt: Value(serverUpdatedAt),
              syncStatus: const Value('synced'),
              isTombstone: const Value(false),
            ),
          );
    }
  }

  Future<void> _applyTombstone(Map<String, dynamic> json) async {
    final entityType = json['type'] as String? ?? json['entityType'] as String?;
    final entityIdRaw = json['id'] ?? json['entityId'];
    if (entityType == null || entityIdRaw == null) return;
    final entityIdStr = entityIdRaw.toString();

    if (entityType == 'medication') {
      await (_db.update(
            _db.medicationsTable,
          )..where(
            (t) =>
                t.serverId.equals(entityIdStr) | t.clientId.equals(entityIdStr),
          ))
          .write(const MedicationsTableCompanion(isTombstone: Value(true)));
    } else if (entityType == 'schedule') {
      await (_db.update(
            _db.schedulesTable,
          )..where(
            (t) =>
                t.serverId.equals(entityIdStr) | t.clientId.equals(entityIdStr),
          ))
          .write(const SchedulesTableCompanion(isTombstone: Value(true)));
    } else if (entityType == 'dose_event') {
      await (_db.update(
            _db.doseEventsTable,
          )..where(
            (t) =>
                t.serverId.equals(entityIdStr) | t.clientId.equals(entityIdStr),
          ))
          .write(const DoseEventsTableCompanion(isTombstone: Value(true)));
    } else if (entityType == 'taxonomy_group') {
      await (_db.update(
            _db.taxonomyGroupsTable,
          )..where(
            (t) =>
                t.serverId.equals(entityIdStr) | t.clientId.equals(entityIdStr),
          ))
          .write(const TaxonomyGroupsTableCompanion(isTombstone: Value(true)));
    }
  }
}
