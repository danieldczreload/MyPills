import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_pills/core/network/api_client.dart';
import 'package:my_pills/features/schedules/data/repositories/cached_dose_unit_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockDio extends Mock implements Dio {}

void main() {
  late MockApiClient mockApiClient;
  late MockDio mockDio;
  late SharedPreferences prefs;
  late CachedDoseUnitRepository repository;

  setUp(() async {
    mockApiClient = MockApiClient();
    mockDio = MockDio();
    when(() => mockApiClient.dio).thenReturn(mockDio);
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    repository = CachedDoseUnitRepository(
      apiClient: mockApiClient,
      prefs: prefs,
    );
  });

  test('fetches catalog from GET /dose-units and caches it', () async {
    when(() => mockDio.get<List<dynamic>>('/dose-units')).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/dose-units'),
        statusCode: 200,
        data: [
          {
            'code': 'mg',
            'symbol': 'mg',
            'name': 'milligram',
            'kind': 'mass',
            'suggestedForForms': ['pill'],
          },
        ],
      ),
    );

    final result = await repository.getAll();

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull, hasLength(1));
    expect(result.valueOrNull!.first.code, 'mg');
    expect(prefs.getString('dose_units_json'), isNotNull);

    final cached = await repository.getAll();
    expect(cached.valueOrNull!.first.code, 'mg');
    verify(() => mockDio.get<List<dynamic>>('/dose-units')).called(1);
  });
}
