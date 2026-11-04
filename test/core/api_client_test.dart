import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:medicalbooking_portal/core/domain/app_error.dart';
import 'package:medicalbooking_portal/core/http/api_client.dart';
import 'package:medicalbooking_portal/core/http/idempotency_key.dart';

http.Response _json(Object body, int status) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

void main() {
  ApiClient clientFor(MockClient mock, {String? token, void Function()? onUnauthorized}) => ApiClient(
    client: mock,
    baseUrl: 'http://api.test/api/v1',
    token: () => token,
    onUnauthorized: onUnauthorized,
  );

  test('sends the bearer token, JSON body and extra headers, and decodes the answer', () async {
    late http.Request seen;
    final api = clientFor(
      MockClient((request) async {
        seen = request;
        return _json({'ok': true}, 201);
      }),
      token: 'jwt',
    );

    final result = await api.post('/appointments', body: {'a': 1}, headers: {'Idempotency-Key': 'k-12345678'});

    expect(result, {'ok': true});
    expect(seen.url.toString(), 'http://api.test/api/v1/appointments');
    expect(seen.headers['Authorization'], 'Bearer jwt');
    expect(seen.headers['Idempotency-Key'], 'k-12345678');
    expect(jsonDecode(seen.body), {'a': 1});
  });

  test('an explicit bearer wins over the session token', () async {
    late http.Request seen;
    final api = clientFor(
      MockClient((request) async {
        seen = request;
        return _json({}, 200);
      }),
      token: 'session',
    );
    await api.get('/me', bearer: 'fresh');
    expect(seen.headers['Authorization'], 'Bearer fresh');
  });

  test('encodes query parameters, including the offset plus sign', () async {
    late Uri seen;
    final api = clientFor(
      MockClient((request) async {
        seen = request.url;
        return _json({'items': []}, 200);
      }),
    );
    await api.get('/availability', query: {'desde': '2026-11-03T05:00:00.000+00:00'});
    expect(seen.toString(), contains('desde=2026-11-03T05%3A00%3A00.000%2B00%3A00'));
  });

  group('maps problem+json to AppError', () {
    Future<AppError> failWith(int status, {Object? body, bool authenticated = true, String? token = 'jwt'}) async {
      final api = clientFor(MockClient((_) async => _json(body ?? {'detail': 'x'}, status)), token: token);
      try {
        authenticated ? await api.get('/x') : await api.post('/auth/login', authenticated: false);
      } on AppError catch (e) {
        return e;
      }
      fail('expected an AppError');
    }

    test('keeps the correlation id and the detail', () async {
      final error = await failWith(409, body: {'detail': 'slot taken', 'correlation_id': 'c-1'});
      expect(error.kind, ErrorKind.conflict);
      expect(error.correlationId, 'c-1');
      expect(error.message, 'slot taken');
    });

    test('status codes', () async {
      expect((await failWith(403)).kind, ErrorKind.forbidden);
      expect((await failWith(404)).kind, ErrorKind.notFound);
      expect((await failWith(422)).kind, ErrorKind.validation);
      expect((await failWith(429)).kind, ErrorKind.rateLimited);
      expect((await failWith(502)).kind, ErrorKind.unavailable);
      expect((await failWith(503)).kind, ErrorKind.unavailable);
      expect((await failWith(500)).kind, ErrorKind.unknown);
    });

    test('a 401 on login means wrong credentials, elsewhere an expired session', () async {
      expect((await failWith(401, authenticated: false, token: null)).kind, ErrorKind.invalidCredentials);
      expect((await failWith(401)).kind, ErrorKind.unauthenticated);
    });

    test('survives a non-JSON error page', () async {
      final api = clientFor(MockClient((_) async => http.Response('<html>Bad gateway</html>', 502)));
      await expectLater(api.get('/x'), throwsA(isA<AppError>().having((e) => e.kind, 'kind', ErrorKind.unavailable)));
    });
  });

  test('tells the session when the API rejects its token', () async {
    var calls = 0;
    final api = clientFor(MockClient((_) async => _json({'detail': 'x'}, 401)), token: 'jwt', onUnauthorized: () => calls++);
    await expectLater(api.get('/x'), throwsA(isA<AppError>()));
    expect(calls, 1);
  });

  test('does not end a session for a failed login attempt', () async {
    var calls = 0;
    final api = clientFor(MockClient((_) async => _json({'detail': 'x'}, 401)), onUnauthorized: () => calls++);
    await expectLater(api.post('/auth/login', authenticated: false), throwsA(isA<AppError>()));
    expect(calls, 0);
  });

  test('a connection failure is a network error', () async {
    final api = clientFor(MockClient((_) async => throw http.ClientException('offline')));
    await expectLater(api.get('/x'), throwsA(isA<AppError>().having((e) => e.kind, 'kind', ErrorKind.network)));
  });

  test('idempotency keys are unique and within the backend limits', () {
    final keys = {for (var i = 0; i < 50; i++) newIdempotencyKey()};
    expect(keys, hasLength(50));
    expect(keys.every((k) => k.length >= 8 && k.length <= 100), isTrue);
  });
}
