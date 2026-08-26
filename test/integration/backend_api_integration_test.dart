import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_pills/core/config/env_config.dart';
import 'package:my_pills/core/network/api_client.dart';
import 'package:my_pills/core/result/result.dart';
import 'package:my_pills/core/storage/token_storage.dart';
import 'package:my_pills/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:my_pills/features/calendar_integration/data/services/pkce_calendar_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;

  late TokenStorage tokenStorage;
  late ApiClient apiClient;
  late AuthRepositoryImpl authRepository;

  setUp(() async {
    HttpOverrides.global = null;
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    tokenStorage = TokenStorage();
    apiClient = ApiClient(
      tokenStorage: tokenStorage,
      baseUrl: EnvConfig.apiBaseUrl,
    );
    authRepository = AuthRepositoryImpl(
      apiClient: apiClient,
      tokenStorage: tokenStorage,
    );
  });

  group('Real Backend API Integration Tests', () {
    test(
      'End-to-end Auth, Profile, Medication, Schedule, and DoseEvent flow',
      () async {
        try {
          // 1. Authenticate with dev Google ID token
          final authResult = await authRepository.loginWithGoogle(
            'valid-integration@example.com',
          );
          if (authResult is FailureResult) {
            // Integration debugging print
            // ignore: avoid_print
            print('Auth error: ${(authResult as FailureResult).failure}');
          }
          expect(
            authResult.isSuccess,
            isTrue,
            reason: 'Google dev auth failed: $authResult',
          );
          final user = authResult.valueOrNull!;
          expect(user.email, equals('integration@example.com'));

          // 2. Fetch authenticated user details via /me
          final meResult = await authRepository.getCurrentUser();
          expect(meResult.isSuccess, isTrue, reason: '/me endpoint failed');
          expect(
            meResult.valueOrNull!.email,
            equals('integration@example.com'),
          );

          // 3. Create a patient profile
          final profileResp = await apiClient.dio.post<Map<String, dynamic>>(
            '/profiles',
            data: {
              'name': 'Integration Patient',
              'birthDate': '1995-06-20',
              'gender': 'female',
            },
          );
          expect(profileResp.statusCode, equals(201));
          final profileId = profileResp.data!['id'] as String;
          expect(profileId, isNotEmpty);

          final uuid = const Uuid();
          final medClientId = uuid.v4();
          final schedClientId = uuid.v4();
          final doseClientId = uuid.v4();

          // 4. Create a medication for profile
          final medResp = await apiClient.dio.post<Map<String, dynamic>>(
            '/profiles/$profileId/medications',
            data: {
              'name': 'Amoxicilina',
              'dosage': '500mg',
              'instructions': 'Tomar cada 8 horas con comida',
              'clientId': medClientId,
            },
          );
          expect(medResp.statusCode, equals(201));
          final medId = medResp.data!['id'] as String;
          expect(medId, isNotEmpty);

          // 5. Create a schedule for medication
          final schedResp = await apiClient.dio.post<Map<String, dynamic>>(
            '/profiles/$profileId/schedules',
            data: {
              'medicationId': medId,
              'type': 'daily',
              'startDate': DateTime.now().toUtc().toIso8601String(),
              'timesOfDay': [
                {'hour': 8, 'minute': 0},
                {'hour': 16, 'minute': 0},
                {'hour': 0, 'minute': 0},
              ],
              'clientId': schedClientId,
            },
          );
          expect(schedResp.statusCode, equals(201));
          final schedId = schedResp.data!['id'] as String;
          expect(schedId, isNotEmpty);

          // 6. Track dose event
          final doseResp = await apiClient.dio.post<Map<String, dynamic>>(
            '/profiles/$profileId/dose-events',
            data: {
              'scheduleId': schedId,
              'scheduledAt': DateTime.now().toUtc().toIso8601String(),
              'status': 'taken',
              'takenAt': DateTime.now().toUtc().toIso8601String(),
              'clientId': doseClientId,
            },
          );
          expect(doseResp.statusCode, equals(201));
          final doseId = doseResp.data!['id'] as String;
          expect(doseId, isNotEmpty);

          // 7. Perform delta sync
          final syncResp = await apiClient.dio.get<Map<String, dynamic>>(
            '/profiles/$profileId/sync',
          );
          expect(syncResp.statusCode, equals(200));
          final syncData = syncResp.data!;
          expect(syncData['medications'], isNotEmpty);
          expect(syncData['schedules'], isNotEmpty);

          // 8. Test FCM Device Token Registration & Deregistration
          final fcmToken = 'test-fcm-token-${uuid.v4()}';
          final devRegResp = await apiClient.dio.post<Map<String, dynamic>>(
            '/devices',
            data: {
              'fcmToken': fcmToken,
              'platform': 'android',
              'locale': 'es-MX',
            },
          );
          expect(devRegResp.statusCode, equals(201));
          final deviceId = devRegResp.data!['id'] as String;
          expect(deviceId, isNotEmpty);

          final devDeregResp = await apiClient.dio.delete<void>(
            '/devices/$deviceId',
          );
          expect(devDeregResp.statusCode, equals(204));

          // 9. Test Notification Preferences Update
          final prefResp = await apiClient.dio.patch<Map<String, dynamic>>(
            '/notifications/preferences',
            data: {
              'doseRemindersEnabled': true,
              'missedDoseNudgesEnabled': true,
              'refillAlertsEnabled': false,
            },
          );
          expect(prefResp.statusCode, equals(200));

          // 10. Test Cloud Calendar Authorization Initiation (Google & Outlook)
          final pkceService = PkceCalendarService(apiClient);
          final verifier = pkceService.generateCodeVerifier();
          final challenge = pkceService.generateCodeChallenge(verifier);

          final googleAuthResp = await apiClient.dio.post<Map<String, dynamic>>(
            '/calendars/google/authorize',
            data: {
              'profileId': profileId,
              'codeVerifier': verifier,
              'codeChallenge': challenge,
            },
          );
          expect(googleAuthResp.statusCode, equals(200));
          expect(googleAuthResp.data!['authorizationUrl'], isNotEmpty);

          final microsoftAuthResp = await apiClient.dio
              .post<Map<String, dynamic>>(
                '/calendars/microsoft/authorize',
                data: {
                  'profileId': profileId,
                  'codeVerifier': verifier,
                  'codeChallenge': challenge,
                },
              );
          expect(microsoftAuthResp.statusCode, equals(200));
          expect(microsoftAuthResp.data!['authorizationUrl'], isNotEmpty);

          // 11. Fetch Calendar Connections for Profile
          final calConnResp = await apiClient.dio.get<List<dynamic>>(
            '/calendars',
            queryParameters: {'profileId': profileId},
          );
          expect(calConnResp.statusCode, equals(200));
        } on DioException catch (e) {
          // Integration debugging print
          // ignore: avoid_print
          print('DioException response data: ${e.response?.data}');
          rethrow;
        }
      },
    );
  });
}
