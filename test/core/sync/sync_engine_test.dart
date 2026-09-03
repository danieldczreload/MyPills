import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_pills/core/db/app_database.dart';
import 'package:my_pills/core/network/api_client.dart';
import 'package:my_pills/core/sync/sync_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/sqlite_support.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockDio extends Mock implements Dio {}

void main() {
  if (!hasSqliteRuntime()) {
    test('SyncEngine tests skipped without sqlite runtime', () {}, skip: true);
    return;
  }

  late AppDatabase db;
  late MockApiClient mockApiClient;
  late MockDio mockDio;
  late SharedPreferences prefs;
  late SyncEngine syncEngine;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    mockApiClient = MockApiClient();
    mockDio = MockDio();
    when(() => mockApiClient.dio).thenReturn(mockDio);
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    syncEngine = SyncEngine(
      apiClient: mockApiClient,
      db: db,
      prefs: prefs,
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('SyncEngine instantiates correctly', () {
    expect(syncEngine, isNotNull);
  });

  test('syncProfile applies medication JSON without dosage', () async {
    when(
      () => mockDio.get<Map<String, dynamic>>('/profiles/profile-1/sync'),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/profiles/profile-1/sync'),
        statusCode: 200,
        data: {
          'medications': [
            {
              'id': 'med-1',
              'name': 'Ibuprofeno',
              'instructions': 'Con comida',
              'form': 'pill',
              'colorToken': 'sky',
              'clientId': 'c-1',
              'updatedAt': '2026-09-02T12:00:00Z',
            },
          ],
          'schedules': [
            {
              'id': 'sch-1',
              'medicationId': 'med-1',
              'type': 'daily',
              'startDate': '2026-09-02',
              'dose': {'amount': 400, 'unit': 'mg', 'display': '400 mg'},
              'timesOfDay': [
                {'hour': 8, 'minute': 0},
              ],
              'clientId': 's-1',
            },
          ],
          'doseEvents': [
            {
              'id': 'de-1',
              'scheduleId': 'sch-1',
              'medicationId': 'med-1',
              'scheduledAt': '2026-09-02T08:00:00Z',
              'status': 'pending',
              'dose': {'amount': 400, 'unit': 'mg', 'display': '400 mg'},
              'clientId': 'd-1',
            },
          ],
        },
      ),
    );

    final result = await syncEngine.syncProfile('profile-1');

    expect(result.isSuccess, isTrue);
    final meds = await db.select(db.medicationsTable).get();
    expect(meds, hasLength(1));
    expect(meds.single.name, 'Ibuprofeno');
    expect(meds.single.category, 'General');
    final schedules = await db.select(db.schedulesTable).get();
    expect(schedules.single.doseDisplay, '400 mg');
    expect(schedules.single.doseUnit, 'mg');
    final events = await db.select(db.doseEventsTable).get();
    expect(events.single.doseDisplay, '400 mg');
  });

  test('syncProfile accepts dose: null on schedule and doseEvent', () async {
    when(
      () => mockDio.get<Map<String, dynamic>>('/profiles/profile-1/sync'),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/profiles/profile-1/sync'),
        statusCode: 200,
        data: {
          'medications': [
            {
              'id': 'med-1',
              'name': 'Ibuprofeno',
              'form': 'pill',
              'colorToken': 'sky',
              'clientId': 'c-1',
            },
          ],
          'schedules': [
            {
              'id': 'sch-1',
              'medicationId': 'med-1',
              'type': 'daily',
              'startDate': '2026-09-02',
              'dose': null,
              'timesOfDay': [
                {'hour': 8, 'minute': 0},
              ],
              'clientId': 's-1',
            },
          ],
          'doseEvents': [
            {
              'id': 'de-1',
              'scheduleId': 'sch-1',
              'medicationId': 'med-1',
              'scheduledAt': '2026-09-02T08:00:00Z',
              'status': 'pending',
              'dose': null,
              'clientId': 'd-1',
            },
          ],
        },
      ),
    );

    final result = await syncEngine.syncProfile('profile-1');

    expect(result.isSuccess, isTrue);
    final schedules = await db.select(db.schedulesTable).get();
    expect(schedules.single.doseAmount, isNull);
    final events = await db.select(db.doseEventsTable).get();
    expect(events.single.doseAmount, isNull);
  });
}
