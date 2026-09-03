import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_pills/core/network/api_client.dart';
import 'package:my_pills/core/storage/token_storage.dart';

class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this.onFetch);

  final Future<ResponseBody> Function(RequestOptions options) onFetch;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return onFetch(options);
  }
}

ResponseBody _json(int status, Map<String, dynamic> data) {
  return ResponseBody.fromString(
    jsonEncode(data),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('401 is recovered via refresh and does not throw', () async {
    FlutterSecureStorage.setMockInitialValues({
      'mypills_access_token': 'old-token',
      'mypills_refresh_token': 'refresh-token',
    });
    final storage = TokenStorage();
    var meCalls = 0;
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1'))
      ..httpClientAdapter = _ScriptedAdapter((options) async {
        if (options.path.endsWith('/auth/refresh')) {
          return _json(200, {
            'token': 'new-token',
            'refreshToken': 'new-refresh',
          });
        }
        meCalls += 1;
        if (options.headers['Authorization'] == 'Bearer new-token') {
          return _json(200, {'id': 'u1', 'email': 'a@b.c'});
        }
        return _json(401, {
          'error': {
            'type': 'UNAUTHORIZED',
            'message': 'Invalid token payload.',
          },
        });
      });

    final client = ApiClient(tokenStorage: storage, dio: dio);
    final response = await client.dio.get<Map<String, dynamic>>('/me');

    expect(response.statusCode, 200);
    expect(response.data!['id'], 'u1');
    expect(await storage.getAccessToken(), 'new-token');
    expect(meCalls, 2);
  });
}
