import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:my_pills/core/db/app_database.dart';
import 'package:my_pills/core/errors/failure.dart';
import 'package:my_pills/core/network/api_client.dart';
import 'package:my_pills/core/result/result.dart';
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
        final tombstones = (data['tombstones'] as List<dynamic>?) ?? [];

        final nowIso = DateTime.now().toUtc().toIso8601String();

        await _db.transaction(() async {
          // 1. Process Upserts: Medications -> Schedules -> DoseEvents
          for (final med in medications) {
            if (med is Map<String, dynamic>) {
              await _upsertMedication(med);
            }
          }
          for (final sched in schedules) {
            if (sched is Map<String, dynamic>) {
              await _upsertSchedule(sched);
            }
          }
          for (final dose in doseEvents) {
            if (dose is Map<String, dynamic>) {
              await _upsertDoseEvent(dose);
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

  Future<bool> _executeOutboxOp(OutboxData op) async {
    try {
      final payload = jsonDecode(op.payloadJson) as Map<String, dynamic>;
      late Response<dynamic> response;

      if (op.action == 'CREATE') {
        response = await _apiClient.dio.post<dynamic>(
          '/profiles/${op.profileId}/${op.entityType}s',
          data: payload,
        );
      } else if (op.action == 'UPDATE') {
        response = await _apiClient.dio.patch<dynamic>(
          '/profiles/${op.profileId}/${op.entityType}s/${op.entityId}',
          data: payload,
        );
      } else if (op.action == 'DELETE') {
        response = await _apiClient.dio.delete<dynamic>(
          '/profiles/${op.profileId}/${op.entityType}s/${op.entityId}',
        );
      }

      return response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300;
    } catch (_) {
      return false;
    }
  }

  Future<void> _upsertMedication(Map<String, dynamic> json) async {
    // Stub for entity mapping & insertion into MedicationsTable
  }

  Future<void> _upsertSchedule(Map<String, dynamic> json) async {
    // Stub for entity mapping & insertion into SchedulesTable
  }

  Future<void> _upsertDoseEvent(Map<String, dynamic> json) async {
    // Stub for entity mapping & insertion into DoseEventsTable
  }

  Future<void> _applyTombstone(Map<String, dynamic> json) async {
    // Stub for tombstone processing
  }
}
