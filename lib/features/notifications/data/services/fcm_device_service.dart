import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:my_pills/core/errors/failure.dart';
import 'package:my_pills/core/network/api_client.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/core/utils/log.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service responsible for managing Firebase Cloud Messaging (FCM),
/// device token registration, and remote test push delivery.
class FcmDeviceService {
  FcmDeviceService(this._apiClient, [this._prefs]);

  final ApiClient _apiClient;
  final SharedPreferences? _prefs;
  static const _deviceIdKey = 'backend_fcm_device_id';
  static const _lastRegisteredTokenKey = 'last_registered_fcm_token';

  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundMessageSub;

  /// Initializes FCM listeners and requests notification permissions.
  Future<void> initialize({
    void Function(RemoteMessage message)? onForegroundMessage,
  }) async {
    try {
      final messaging = FirebaseMessaging.instance;

      // Request notification permissions
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      mlog(
        'mypills.fcm',
        'FCM permission status: ${settings.authorizationStatus}',
      );

      // Listen for token refresh
      _tokenRefreshSub?.cancel();
      _tokenRefreshSub = messaging.onTokenRefresh.listen((newToken) {
        mlog('mypills.fcm', 'FCM token refreshed');
        unawaited(registerDevice(fcmToken: newToken));
      });

      // Listen for foreground push messages
      if (onForegroundMessage != null) {
        _foregroundMessageSub?.cancel();
        _foregroundMessageSub = FirebaseMessaging.onMessage.listen(
          onForegroundMessage,
        );
      }

      // Initial token sync
      await syncCurrentToken();
    } catch (e, st) {
      mlog('mypills.fcm', 'Failed to initialize FCM: $e\n$st');
    }
  }

  /// Obtains current token and registers it if not already registered.
  Future<Result<String>> syncCurrentToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) {
        return const Result.failure(
          Failure.server(
            statusCode: 400,
            message: 'FCM token is null or empty',
          ),
        );
      }

      final lastToken = _prefs?.getString(_lastRegisteredTokenKey);
      final registeredDeviceId = _prefs?.getString(_deviceIdKey);

      if (token == lastToken && registeredDeviceId != null) {
        return Result.success(registeredDeviceId);
      }

      return await registerDevice(fcmToken: token);
    } catch (e, st) {
      return Result.failure(Failure.unexpected(error: e, stackTrace: st));
    }
  }

  /// Registers the FCM device token with `POST /devices`.
  Future<Result<String>> registerDevice({
    required String fcmToken,
    String? locale,
  }) async {
    try {
      final String platform;
      if (kIsWeb) {
        platform = 'web';
      } else if (Platform.isAndroid) {
        platform = 'android';
      } else if (Platform.isIOS) {
        platform = 'ios';
      } else {
        platform = 'unknown';
      }
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/devices',
        data: {
          'fcmToken': fcmToken,
          'platform': platform,
          'locale': _resolveLocale(locale),
        },
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final deviceId = response.data?['id']?.toString() ?? '';
        if (deviceId.isNotEmpty && _prefs != null) {
          await _prefs!.setString(_deviceIdKey, deviceId);
          await _prefs!.setString(_lastRegisteredTokenKey, fcmToken);
        }
        return Result.success(deviceId);
      }

      return Result.failure(
        Failure.server(
          statusCode: response.statusCode ?? 500,
          message: 'Failed to register device',
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

  /// Sends a test push notification from backend via `POST /notifications/test-push`.
  Future<Result<Map<String, dynamic>>> sendTestPush({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/notifications/test-push',
        data: {
          'title': title,
          'body': body,
          if (data != null) 'data': data,
        },
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return Result.success(response.data ?? {});
      }

      return Result.failure(
        Failure.server(
          statusCode: response.statusCode ?? 500,
          message: 'Failed to send test push',
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

  /// Deregisters the FCM device with `DELETE /devices/{deviceId}`.
  Future<Result<void>> deregisterDevice([String? deviceId]) async {
    try {
      final targetId = deviceId ?? _prefs?.getString(_deviceIdKey);
      if (targetId == null || targetId.isEmpty) {
        return const Result.success(null);
      }

      final response = await _apiClient.dio.delete<void>('/devices/$targetId');
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        await _prefs?.remove(_deviceIdKey);
        await _prefs?.remove(_lastRegisteredTokenKey);
        return const Result.success(null);
      }
      return Result.failure(
        Failure.server(
          statusCode: response.statusCode ?? 500,
          message: 'Failed to deregister device',
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

  void dispose() {
    _tokenRefreshSub?.cancel();
    _foregroundMessageSub?.cancel();
  }

  /// API requires `^[a-z]{2}(?:-[A-Z]{2})?$` (e.g. `es` or `es-MX`).
  static String _resolveLocale(String? locale) {
    final raw = (locale == null || locale.isEmpty)
        ? (kIsWeb ? 'es' : Platform.localeName)
        : locale;
    final normalized = raw.replaceAll('_', '-');
    final match = RegExp(
      r'^([A-Za-z]{2})(?:-([A-Za-z]{2}))?',
    ).firstMatch(normalized);
    if (match == null) return 'es';
    final lang = match.group(1)!.toLowerCase();
    final region = match.group(2);
    if (region == null || region.isEmpty) return lang;
    return '$lang-${region.toUpperCase()}';
  }
}
