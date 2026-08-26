import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_pills/core/db/app_database.dart';
import 'package:my_pills/core/network/api_client.dart';
import 'package:my_pills/core/sync/sync_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late AppDatabase db;
  late MockApiClient mockApiClient;
  late SharedPreferences prefs;
  late SyncEngine syncEngine;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    mockApiClient = MockApiClient();
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
}
