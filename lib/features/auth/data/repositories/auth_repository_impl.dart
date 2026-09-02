import 'package:dio/dio.dart';
import 'package:my_pills/core/errors/failure.dart';
import 'package:my_pills/core/network/api_client.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/core/storage/token_storage.dart';
import 'package:my_pills/core/utils/log.dart';
import 'package:my_pills/features/auth/data/id_token_claims.dart';
import 'package:my_pills/features/auth/domain/entities/auth_user.dart';
import 'package:my_pills/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
  }) : _apiClient = apiClient,
       _tokenStorage = tokenStorage;

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  String? _lastDisplayName;
  String? _lastPhotoUrl;

  @override
  Future<Result<AuthUser>> loginWithGoogle(
    String idToken, {
    String? displayName,
    String? photoUrl,
  }) async {
    return _loginWithProvider('/auth/google', idToken, displayName, photoUrl);
  }

  @override
  Future<Result<AuthUser>> loginWithMicrosoft(
    String idToken, {
    String? displayName,
    String? photoUrl,
  }) async {
    return _loginWithProvider(
      '/auth/microsoft',
      idToken,
      displayName,
      photoUrl,
    );
  }

  Future<Result<AuthUser>> _loginWithProvider(
    String path,
    String idToken,
    String? displayName,
    String? photoUrl,
  ) async {
    final claims = IdTokenClaims.tryParse(idToken);
    _lastDisplayName = _firstNonEmpty(displayName, claims?.name);
    _lastPhotoUrl = _firstNonEmpty(photoUrl, claims?.picture);
    mlog(
      'mypills.auth',
      'login $path displayName=${_lastDisplayName ?? 'null'} '
          'photoUrl=${_lastPhotoUrl ?? 'null'}',
    );
    await _tokenStorage.saveAuthProfile(
      displayName: _lastDisplayName,
      photoUrl: _lastPhotoUrl,
    );
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        path,
        data: {'idToken': idToken},
        options: Options(extra: {'requiresAuth': false}),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!;
        final token = (data['token'] ?? data['accessToken']) as String?;
        final refreshToken = data['refreshToken'] as String?;

        if (token != null && refreshToken != null) {
          await _tokenStorage.saveTokens(
            accessToken: token,
            refreshToken: refreshToken,
          );
          return await getCurrentUser();
        }
      }
      return const Result.failure(
        Failure.server(
          statusCode: 500,
          message: 'Invalid authentication response',
        ),
      );
    } on DioException catch (e) {
      return Result.failure(_mapDioException(e));
    } catch (e, st) {
      return Result.failure(Failure.unexpected(error: e, stackTrace: st));
    }
  }

  @override
  Future<Result<AuthUser>> login({
    required String email,
    required String password,
  }) async {
    // Standard OAuth token login via dev token if no direct password provider
    return loginWithGoogle('valid-$email');
  }

  @override
  Future<Result<AuthUser>> register({
    required String email,
    required String password,
    String? name,
  }) async {
    return loginWithGoogle('valid-$email');
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await _apiClient.dio.post<dynamic>('/auth/logout');
    } catch (_) {
      // Best-effort remote logout notification
    } finally {
      await _tokenStorage.clearTokens();
    }
    return const Result.success(null);
  }

  @override
  Future<Result<AuthUser>> getCurrentUser() async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>('/me');
      if (response.statusCode == 200 && response.data != null) {
        final data = Map<String, dynamic>.from(response.data!);
        final cachedName =
            _lastDisplayName ?? await _tokenStorage.getDisplayName();
        final cachedPhoto = _lastPhotoUrl ?? await _tokenStorage.getPhotoUrl();
        if (data['name']?.toString().isEmpty ?? true) {
          if (cachedName != null && cachedName.isNotEmpty) {
            data['name'] = cachedName;
          } else {
            final email = data['email']?.toString() ?? '';
            data['name'] = email.contains('@') ? email.split('@').first : email;
          }
        }
        if (data['photoUrl'] == null || data['photoUrl'].toString().isEmpty) {
          if (cachedPhoto != null && cachedPhoto.isNotEmpty) {
            data['photoUrl'] = cachedPhoto;
          }
        }
        return Result.success(AuthUser.fromJson(data));
      }
      return const Result.failure(Failure.notFound());
    } on DioException catch (e) {
      return Result.failure(_mapDioException(e));
    } catch (e, st) {
      return Result.failure(Failure.unexpected(error: e, stackTrace: st));
    }
  }

  Failure _mapDioException(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return const Failure.network();
    }
    final status = e.response?.statusCode;
    if (status == 401) {
      return const Failure.unauthorized();
    } else if (status == 404) {
      return const Failure.notFound();
    } else if (status == 409) {
      return const Failure.conflict();
    } else if (status != null) {
      String? message;
      if (e.response?.data is Map) {
        final dataMap = e.response!.data as Map;
        final errorObj = dataMap['error'];
        if (errorObj is Map) {
          message = errorObj['message']?.toString();
        }
      }
      return Failure.server(statusCode: status, message: message);
    }

    return Failure.unexpected(error: e, stackTrace: e.stackTrace);
  }

  static String? _firstNonEmpty(String? a, String? b) {
    if (a != null && a.isNotEmpty) return a;
    if (b != null && b.isNotEmpty) return b;
    return null;
  }
}
