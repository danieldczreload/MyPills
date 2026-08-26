import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:my_pills/core/config/env_config.dart';
import 'package:my_pills/core/errors/failure.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/features/auth/domain/entities/auth_user.dart';
import 'package:my_pills/features/auth/domain/repositories/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Interactive OAuth 2.0 PKCE Authorization service for Microsoft / Azure Entra ID.
class MicrosoftAuthService {
  MicrosoftAuthService({
    required Dio dio,
    required SharedPreferences prefs,
    required AuthRepository authRepository,
  }) : _dio = dio,
       _prefs = prefs,
       _authRepository = authRepository;

  final Dio _dio;
  final SharedPreferences _prefs;
  final AuthRepository _authRepository;

  static const _verifierPrefix = 'ms_auth_verifier_';

  String _generateCodeVerifier() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  String _generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  /// Builds the authorization URL to launch in browser or Custom Tab.
  Future<Uri> getAuthorizationUrl() async {
    final codeVerifier = _generateCodeVerifier();
    final codeChallenge = _generateCodeChallenge(codeVerifier);
    final state = 'ms_auth_${const Uuid().v4()}';

    await _prefs.setString('$_verifierPrefix$state', codeVerifier);
    await _prefs.setString('${_verifierPrefix}latest', codeVerifier);

    return Uri.parse(
      'https://login.microsoftonline.com/${EnvConfig.microsoftTenantId}/oauth2/v2.0/authorize',
    ).replace(
      queryParameters: {
        'client_id': EnvConfig.microsoftClientId,
        'response_type': 'code',
        'redirect_uri': EnvConfig.microsoftRedirectUri,
        'response_mode': 'query',
        'scope': 'openid profile email User.Read offline_access',
        'state': state,
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
      },
    );
  }

  /// Completes the OAuth flow by exchanging authorization code for access token,
  /// then authenticating with the MyPills backend API.
  Future<Result<AuthUser>> completeLogin({
    required String code,
    required String state,
  }) async {
    try {
      final codeVerifier =
          _prefs.getString('$_verifierPrefix$state') ??
          _prefs.getString('${_verifierPrefix}latest');

      if (codeVerifier == null) {
        return const Result.failure(
          Failure.unexpected(error: 'Missing Microsoft PKCE code verifier'),
        );
      }

      final response = await _dio.post<Map<String, dynamic>>(
        'https://login.microsoftonline.com/${EnvConfig.microsoftTenantId}/oauth2/v2.0/token',
        data: {
          'client_id': EnvConfig.microsoftClientId,
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': EnvConfig.microsoftRedirectUri,
          'code_verifier': codeVerifier,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          extra: {'requiresAuth': false},
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final accessToken = response.data!['access_token'] as String?;
        if (accessToken != null && accessToken.isNotEmpty) {
          return await _authRepository.loginWithMicrosoft(accessToken);
        }
      }

      return const Result.failure(
        Failure.server(
          statusCode: 500,
          message: 'Failed to exchange Microsoft authorization code',
        ),
      );
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
}
