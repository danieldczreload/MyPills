import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:my_pills/core/config/env_config.dart';
import 'package:my_pills/core/network/http_error_body.dart';
import 'package:my_pills/core/storage/token_storage.dart';
import 'package:my_pills/core/utils/log.dart';

/// Central API HTTP client powered by Dio with JWT auth interceptor and
/// single-flight token refresh mutex.
class ApiClient {
  ApiClient({
    required TokenStorage tokenStorage,
    String? baseUrl,
    Dio? dio,
    VoidCallback? onUnauthenticated,
  }) : _tokenStorage = tokenStorage,
       _onUnauthenticated = onUnauthenticated,
       _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: baseUrl ?? EnvConfig.apiBaseUrl,
               connectTimeout: const Duration(seconds: 15),
               receiveTimeout: const Duration(seconds: 15),
               headers: {
                 'Content-Type': 'application/json',
                 'Accept': 'application/json',
               },
             ),
           ) {
    // Accept self-signed certs only in debug and only for loopback hosts so
    // production/release never bypasses TLS validation.
    if (kDebugMode &&
        !kIsWeb &&
        _dio.httpClientAdapter is IOHttpClientAdapter) {
      (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient()
          ..badCertificateCallback = (cert, host, port) {
            return host == 'localhost' ||
                host == '127.0.0.1' ||
                host == '10.0.2.2';
          };
        return client;
      };
    }
    // Auth must run before the debug logger so a recovered 401 is logged
    // as the retried 200, not as a false ERROR.
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onError: _onError,
      ),
    );
    if (kDebugMode) {
      _dio.interceptors.add(_DebugHttpLogInterceptor());
    }
  }

  final Dio _dio;
  final TokenStorage _tokenStorage;
  final VoidCallback? _onUnauthenticated;

  Completer<bool>? _refreshCompleter;

  Dio get dio => _dio;

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final requiresAuth = options.extra['requiresAuth'] != false;
    if (requiresAuth) {
      final token = await _tokenStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 &&
        err.requestOptions.extra['requiresAuth'] != false &&
        err.requestOptions.path != '/auth/refresh') {
      if (kDebugMode && _refreshCompleter == null) {
        mlog('mypills.http', '401 — refreshing access token');
      }
      final success = await _refreshTokenSingleFlight();
      if (success) {
        final newAccessToken = await _tokenStorage.getAccessToken();
        final requestOptions = err.requestOptions;
        requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
        try {
          final response = await _dio.fetch<dynamic>(requestOptions);
          return handler.resolve(response);
        } on DioException catch (e) {
          return handler.next(e);
        }
      }
      await _tokenStorage.clearTokens();
      _onUnauthenticated?.call();
    }
    handler.next(err);
  }

  Future<bool> _refreshTokenSingleFlight() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<bool>();

    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        _refreshCompleter!.complete(false);
        return false;
      }

      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
        options: Options(extra: {'requiresAuth': false}),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!;
        final newAccessToken =
            (data['token'] ?? data['accessToken']) as String?;
        final newRefreshToken = data['refreshToken'] as String?;

        if (newAccessToken != null && newRefreshToken != null) {
          await _tokenStorage.saveTokens(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
          );
          _refreshCompleter!.complete(true);
          return true;
        }
      }
      _refreshCompleter!.complete(false);
      return false;
    } catch (_) {
      _refreshCompleter!.complete(false);
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }
}

/// Compact request/response tracer used only in debug builds.
/// Does not log headers or bodies so tokens never hit the console.
class _DebugHttpLogInterceptor extends Interceptor {
  static const _startedAtKey = 'devLogStartedAt';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startedAtKey] = DateTime.now();
    mlog('mypills.http', '→ ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final started = response.requestOptions.extra[_startedAtKey];
    final elapsed = started is DateTime
        ? ' (${DateTime.now().difference(started).inMilliseconds}ms)'
        : '';
    mlog(
      'mypills.http',
      '← ${response.statusCode} ${response.requestOptions.method} '
          '${response.requestOptions.uri}$elapsed',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final summary = summarizeHttpErrorBody(err.response?.data);
    final line =
        '${err.requestOptions.method} ${err.requestOptions.uri} '
        'failed: ${err.type.name} status=${err.response?.statusCode}'
        '${summary.isEmpty ? '' : ' body=$summary'}';
    if (err.requestOptions.extra[kHttpBestEffortExtra] == true) {
      mlog('mypills.http', '$line (best-effort)');
    } else {
      mlogError('mypills.http', line);
    }
    handler.next(err);
  }
}
