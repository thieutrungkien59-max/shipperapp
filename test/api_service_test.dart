import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shipperapp/services/api_service.dart';
import 'package:shipperapp/services/session_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await SessionService.clear();
  });

  test('adds Bearer token to authenticated requests', () async {
    await SessionService.saveSession(
      accountId: 'account-1',
      driverId: 'driver-1',
      accessToken: 'jwt-demo',
    );

    final client = MockClient((request) async {
      expect(request.headers['authorization'], 'Bearer jwt-demo');
      return http.Response(jsonEncode({'ok': true}), 200);
    });

    final response = await ApiServices(client: client).get('/api/test');
    expect(response['ok'], isTrue);
  });

  test('clears local session after 401', () async {
    await SessionService.saveSession(
      accountId: 'account-1',
      driverId: 'driver-1',
      accessToken: 'expired',
    );

    final client = MockClient(
      (_) async => http.Response(jsonEncode({'message': 'expired'}), 401),
    );

    await expectLater(
      ApiServices(client: client).get('/api/test'),
      throwsA(
        isA<ApiException>().having((error) => error.statusCode, 'status', 401),
      ),
    );

    await Future<void>.delayed(Duration.zero);
    expect(await SessionService.hasSession(), isFalse);
    expect(await SessionService.getAccessToken(), isNull);
  });

  test('maps server error messages', () async {
    final client = MockClient(
      (_) async => http.Response(jsonEncode({'message': 'bad request'}), 400),
    );

    await expectLater(
      ApiServices(client: client).post('/api/test', const {}),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'status', 400)
            .having((error) => error.message, 'message', 'bad request'),
      ),
    );
  });
}
