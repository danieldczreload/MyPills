import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:my_pills/core/errors/failure.dart';
import 'package:my_pills/core/network/api_client.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/features/schedules/domain/entities/dose_unit.dart';
import 'package:my_pills/features/schedules/domain/repositories/dose_unit_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fetches `GET /dose-units` and caches the catalog locally.
class CachedDoseUnitRepository implements DoseUnitRepository {
  CachedDoseUnitRepository({
    required ApiClient apiClient,
    required SharedPreferences prefs,
  }) : _apiClient = apiClient,
       _prefs = prefs;

  final ApiClient _apiClient;
  final SharedPreferences _prefs;

  static const _cacheKey = 'dose_units_json';
  static const _cachedAtKey = 'dose_units_cached_at';
  static const _ttl = Duration(days: 7);

  List<DoseUnit>? _memory;

  @override
  Future<Result<List<DoseUnit>>> getAll() async {
    if (_memory != null) {
      return Result.success(_memory!);
    }

    final cached = _readCache();
    final cachedAt = _cachedAt();
    final cacheIsFresh =
        cached != null &&
        cachedAt != null &&
        DateTime.now().toUtc().difference(cachedAt) < _ttl;

    if (cacheIsFresh) {
      _memory = cached;
      return Result.success(cached);
    }

    try {
      final response = await _apiClient.dio.get<List<dynamic>>('/dose-units');
      if (response.statusCode == 200 && response.data != null) {
        final units = response.data!
            .whereType<Map<dynamic, dynamic>>()
            .map((item) => DoseUnit.fromJson(Map<String, dynamic>.from(item)))
            .toList(growable: false);
        _memory = units;
        await _writeCache(units);
        return Result.success(units);
      }
      if (cached != null) {
        _memory = cached;
        return Result.success(cached);
      }
      return Result.failure(
        Failure.server(
          statusCode: response.statusCode ?? 500,
          message: 'Invalid dose-units response',
        ),
      );
    } on DioException catch (e) {
      if (cached != null) {
        _memory = cached;
        return Result.success(cached);
      }
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
      if (cached != null) {
        _memory = cached;
        return Result.success(cached);
      }
      return Result.failure(Failure.unexpected(error: e, stackTrace: st));
    }
  }

  List<DoseUnit>? _readCache() {
    final raw = _prefs.getString(_cacheKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map<dynamic, dynamic>>()
          .map((item) => DoseUnit.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false);
    } on Object {
      return null;
    }
  }

  DateTime? _cachedAt() {
    final raw = _prefs.getString(_cachedAtKey);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> _writeCache(List<DoseUnit> units) async {
    final payload = units
        .map(
          (u) => {
            'code': u.code,
            'symbol': u.symbol,
            'name': u.name,
            'kind': u.kind,
            'suggestedForForms': u.suggestedForForms,
          },
        )
        .toList(growable: false);
    await _prefs.setString(_cacheKey, jsonEncode(payload));
    await _prefs.setString(
      _cachedAtKey,
      DateTime.now().toUtc().toIso8601String(),
    );
  }
}
