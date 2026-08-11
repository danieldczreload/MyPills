import 'package:dio/dio.dart';
import 'package:my_pills/core/errors/failure.dart';
import 'package:my_pills/core/network/api_client.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/core/storage/token_storage.dart';
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

  @override
  Future<Result<AuthUser>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
        options: Options(extra: {'requiresAuth': false}),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!;
        final accessToken = data['accessToken'] as String?;
        final refreshToken = data['refreshToken'] as String?;
        final userJson = data['user'] as Map<String, dynamic>?;

        if (accessToken != null && refreshToken != null && userJson != null) {
          await _tokenStorage.saveTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
          );
          return Result.success(AuthUser.fromJson(userJson));
        }
      }
      return const Result.failure(
        Failure.server(statusCode: 500, message: 'Invalid response format'),
      );
    } on DioException catch (e) {
      return Result.failure(_mapDioException(e));
    } catch (e, st) {
      return Result.failure(Failure.unexpected(error: e, stackTrace: st));
    }
  }

  @override
  Future<Result<AuthUser>> register({
    required String email,
    required String password,
    String? name,
  }) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
          if (name != null) 'name': name,
        },
        options: Options(extra: {'requiresAuth': false}),
      );

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data != null) {
        final data = response.data!;
        final accessToken = data['accessToken'] as String?;
        final refreshToken = data['refreshToken'] as String?;
        final userJson = data['user'] as Map<String, dynamic>?;

        if (accessToken != null && refreshToken != null && userJson != null) {
          await _tokenStorage.saveTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
          );
          return Result.success(AuthUser.fromJson(userJson));
        }
      }
      return const Result.failure(
        Failure.server(statusCode: 500, message: 'Invalid response format'),
      );
    } on DioException catch (e) {
      return Result.failure(_mapDioException(e));
    } catch (e, st) {
      return Result.failure(Failure.unexpected(error: e, stackTrace: st));
    }
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
        return Result.success(AuthUser.fromJson(response.data!));
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
}
