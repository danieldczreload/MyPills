import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:my_pills/core/errors/failure.dart';
import 'package:my_pills/core/network/api_client.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PkceAuthorizeResult {
  const PkceAuthorizeResult({
    required this.state,
    required this.authorizationUrl,
    required this.codeVerifier,
  });

  final String state;
  final String authorizationUrl;
  final String codeVerifier;
}

/// Service handling OAuth 2.0 PKCE calendar authorization flow with the backend.
class PkceCalendarService {
  PkceCalendarService(this._apiClient, [this._prefs]);

  final ApiClient _apiClient;
  final SharedPreferences? _prefs;

  static const _verifierPrefix = 'pkce_verifier_';
  static const _providerPrefix = 'pkce_provider_';

  /// Generates PKCE codeVerifier (43-128 unreserved chars).
  String generateCodeVerifier() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlUrlNoPadding(bytes);
  }

  /// Derives S256 codeChallenge from codeVerifier.
  String generateCodeChallenge(String codeVerifier) {
    final bytes = utf8.encode(codeVerifier);
    final digest = sha256.convert(bytes);
    return base64UrlUrlNoPadding(digest.bytes);
  }

  String base64UrlUrlNoPadding(List<int> bytes) {
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  Future<String> _resolveServerProfileId(String profileId) async {
    if (profileId.isNotEmpty && profileId != 'default') {
      return profileId;
    }
    try {
      final profRes = await _apiClient.dio.get<List<dynamic>>('/profiles');
      if (profRes.statusCode == 200 &&
          profRes.data != null &&
          profRes.data!.isNotEmpty) {
        final first = profRes.data!.first as Map<String, dynamic>;
        final id = first['id'] as String?;
        if (id != null && id.isNotEmpty) {
          await _prefs?.setString('active_profile_id', id);
          return id;
        }
      } else {
        final name = _prefs?.getString('profile.name') ?? 'Usuario';
        final createRes = await _apiClient.dio.post<Map<String, dynamic>>(
          '/profiles',
          data: {
            'name': name,
            'birthDate': '1990-01-01',
            'gender': 'other',
            'timezone': DateTime.now().timeZoneName,
          },
        );
        if (createRes.statusCode == 201 && createRes.data != null) {
          final id = createRes.data!['id'] as String?;
          if (id != null && id.isNotEmpty) {
            await _prefs?.setString('active_profile_id', id);
            return id;
          }
        }
      }
    } catch (_) {}
    return profileId;
  }

  /// Initiates PKCE authorization for provider ('google', 'outlook', etc.).
  /// Sends `POST /calendars/{provider}/authorize` with `profileId` and `codeChallenge`.
  Future<Result<PkceAuthorizeResult>> initiateAuthorization({
    required String profileId,
    required String provider,
  }) async {
    try {
      final effectiveProfileId = await _resolveServerProfileId(profileId);
      final codeVerifier = generateCodeVerifier();
      final codeChallenge = generateCodeChallenge(codeVerifier);

      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/calendars/$provider/authorize',
        data: {
          'profileId': effectiveProfileId,
          'codeChallenge': codeChallenge,
          'codeChallengeMethod': 'S256',
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!;
        final state = data['state'] as String? ?? '';
        final authUrl = data['authorizationUrl'] as String? ?? '';

        if (_prefs != null && state.isNotEmpty) {
          await _prefs!.setString('$_verifierPrefix$state', codeVerifier);
          await _prefs!.setString('$_providerPrefix$state', provider);
          await _prefs!.setString('${_verifierPrefix}latest', codeVerifier);
          await _prefs!.setString('${_providerPrefix}latest', provider);
        }

        return Result.success(
          PkceAuthorizeResult(
            state: state,
            authorizationUrl: authUrl,
            codeVerifier: codeVerifier,
          ),
        );
      }

      return Result.failure(
        Failure.server(
          statusCode: response.statusCode ?? 500,
          message: 'Failed to initiate calendar authorization',
        ),
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

  /// Completes PKCE authorization exchange using stored codeVerifier from state.
  Future<Result<bool>> completeCallbackAuthorization({
    required String profileId,
    required String code,
    required String state,
  }) async {
    final codeVerifier =
        _prefs?.getString('$_verifierPrefix$state') ??
        _prefs?.getString('${_verifierPrefix}latest') ??
        '';
    final provider =
        _prefs?.getString('$_providerPrefix$state') ??
        _prefs?.getString('${_providerPrefix}latest') ??
        'google';

    if (codeVerifier.isEmpty) {
      return const Result.failure(
        Failure.server(
          statusCode: 400,
          message: 'Missing PKCE code verifier for callback state',
        ),
      );
    }

    final result = await connectCalendar(
      profileId: profileId,
      provider: provider,
      code: code,
      state: state,
      codeVerifier: codeVerifier,
    );

    if (_prefs != null) {
      await _prefs!.remove('$_verifierPrefix$state');
      await _prefs!.remove('$_providerPrefix$state');
    }

    return result;
  }

  /// Completes PKCE authorization exchange via deep-link redirect params.
  /// Sends `POST /calendars/{provider}/connect` with `profileId`, `code`, `state`, `codeVerifier`.
  Future<Result<bool>> connectCalendar({
    required String profileId,
    required String provider,
    required String code,
    required String state,
    required String codeVerifier,
  }) async {
    try {
      final effectiveProfileId = await _resolveServerProfileId(profileId);
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/calendars/$provider/connect',
        data: {
          'profileId': effectiveProfileId,
          'code': code,
          'state': state,
          'codeVerifier': codeVerifier,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final connected = response.data!['connected'] as bool? ?? true;
        return Result.success(connected);
      }

      return Result.failure(
        Failure.server(
          statusCode: response.statusCode ?? 500,
          message: 'Failed to connect calendar provider',
        ),
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

  /// Completes a Google native-SDK connect using the serverAuthCode issued by
  /// google_sign_in (no state/PKCE round-trip).
  /// Sends `POST /calendars/google/connect` with `profileId` and `code`.
  Future<Result<bool>> connectWithServerAuthCode({
    required String profileId,
    required String code,
  }) async {
    try {
      final effectiveProfileId = await _resolveServerProfileId(profileId);
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/calendars/google/connect',
        data: {
          'profileId': effectiveProfileId,
          'code': code,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final connected = response.data!['connected'] as bool? ?? true;
        return Result.success(connected);
      }

      return Result.failure(
        Failure.server(
          statusCode: response.statusCode ?? 500,
          message: 'Failed to connect Google Calendar',
        ),
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

  /// Disconnects a calendar provider for profileId.
  /// Sends `DELETE /calendars/{provider}?profileId=...`.
  Future<Result<void>> disconnectCalendar({
    required String profileId,
    required String provider,
  }) async {
    try {
      final effectiveProfileId = await _resolveServerProfileId(profileId);
      final response = await _apiClient.dio.delete<void>(
        '/calendars/$provider',
        queryParameters: {'profileId': effectiveProfileId},
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return const Result.success(null);
      }

      return Result.failure(
        Failure.server(
          statusCode: response.statusCode ?? 500,
          message: 'Failed to disconnect calendar provider',
        ),
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

  /// Triggers cloud calendar synchronization for profileId.
  /// Sends `POST /calendars/sync?profileId=...`.
  /// Returns the server report: `eventsCreated`, `eventsUpdated`,
  /// `linksSynced` and `skipped` reasons.
  Future<Result<Map<String, dynamic>>> syncCalendar({
    required String profileId,
  }) async {
    try {
      final effectiveProfileId = await _resolveServerProfileId(profileId);
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/calendars/sync',
        queryParameters: {'profileId': effectiveProfileId},
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return Result.success(response.data ?? const <String, dynamic>{});
      }

      return Result.failure(
        Failure.server(
          statusCode: response.statusCode ?? 500,
          message: 'Failed to sync cloud calendar',
        ),
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        return const Result.failure(Failure.network());
      }
      if (e.response?.statusCode != null && e.response!.statusCode! < 500) {
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          final error = data['error'];
          if (error is Map<String, dynamic>) {
            return Result.failure(
              Failure.server(
                statusCode: e.response!.statusCode!,
                message: _syncFailureMessage(error),
              ),
            );
          }
        }
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

  /// Fetches current calendar connections for profileId.
  /// Sends `GET /calendars?profileId=...`.
  Future<Result<List<Map<String, dynamic>>>> getConnections({
    required String profileId,
  }) async {
    try {
      final effectiveProfileId = await _resolveServerProfileId(profileId);
      final response = await _apiClient.dio.get<dynamic>(
        '/calendars',
        queryParameters: {'profileId': effectiveProfileId},
      );

      if (response.statusCode == 200 && response.data is List) {
        final list = (response.data as List)
            .whereType<Map<String, dynamic>>()
            .toList();
        return Result.success(list);
      }

      return const Result.success([]);
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

  /// Prefers the first per-link sync reason so the UI can map
  /// `REFRESH_FAILED` / `REAUTH_REQUIRED` instead of a generic 400.
  String? _syncFailureMessage(Map<String, dynamic> error) {
    final details = error['details'];
    if (details is Map<String, dynamic>) {
      final links = details['links'];
      if (links is List && links.isNotEmpty) {
        final first = links.first;
        if (first is Map && first['reason'] is String) {
          return first['reason'] as String;
        }
      }
    }
    return error['message'] as String?;
  }
}
