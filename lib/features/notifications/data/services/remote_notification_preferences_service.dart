import 'package:dio/dio.dart';
import 'package:my_pills/core/errors/failure.dart';
import 'package:my_pills/core/network/api_client.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/features/notifications/domain/entities/notification_preferences.dart';

/// Service responsible for syncing notification preferences with the backend.
class RemoteNotificationPreferencesService {
  RemoteNotificationPreferencesService(this._apiClient);

  final ApiClient _apiClient;

  /// Fetches notification preferences from `GET /notifications/preferences`.
  Future<Result<NotificationPreferences>> getPreferences() async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/notifications/preferences',
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300 &&
          response.data != null) {
        final data = response.data!;
        final prefs = NotificationPreferences(
          pushNotificationsEnabled:
              data['doseRemindersEnabled'] as bool? ?? true,
          inAppBannersEnabled: data['inAppBannersEnabled'] as bool? ?? true,
          reminderMinutesBefore:
              (data['reminderMinutesBefore'] as num?)?.toInt() ?? 0,
        );
        return Result.success(prefs);
      }

      return Result.failure(
        Failure.server(
          statusCode: response.statusCode ?? 500,
          message: 'Failed to fetch notification preferences',
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

  /// Updates notification preferences with `PATCH /notifications/preferences`.
  Future<Result<void>> updatePreferences(NotificationPreferences prefs) async {
    try {
      final response = await _apiClient.dio.patch<Map<String, dynamic>>(
        '/notifications/preferences',
        data: {
          'doseRemindersEnabled': prefs.pushNotificationsEnabled,
          'inAppBannersEnabled': prefs.inAppBannersEnabled,
          'reminderMinutesBefore': prefs.reminderMinutesBefore,
        },
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return const Result.success(null);
      }

      return Result.failure(
        Failure.server(
          statusCode: response.statusCode ?? 500,
          message: 'Failed to update notification preferences',
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
}
