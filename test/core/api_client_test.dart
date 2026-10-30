import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:product_browser/core/errors/app_exception.dart';
import 'package:product_browser/core/network/api_client.dart';

import '../helpers/fakes.dart';

void main() {
  late InMemoryTokenStorage storage;

  setUp(() => storage = InMemoryTokenStorage());

  ApiClient clientWith(MockClientHandler handler) => ApiClient(
    tokenStorage: storage,
    httpClient: MockClient(handler),
    baseUrl: 'https://example.com',
  );

  test('GET builds the URL with query parameters and decodes JSON', () async {
    late Uri captured;
    final client = clientWith((request) async {
      captured = request.url;
      return http.Response(jsonEncode({'ok': true}), 200);
    });

    final json = await client.get(
      '/products',
      query: {'limit': '20', 'skip': '40'},
    );

    expect(json['ok'], isTrue);
    expect(
      captured.toString(),
      'https://example.com/products?limit=20&skip=40',
    );
  });

  test('attaches the bearer token when one is stored', () async {
    storage.token = 'abc';
    late Map<String, String> headers;
    final client = clientWith((request) async {
      headers = request.headers;
      return http.Response('{}', 200);
    });

    await client.get('/auth/me');

    expect(headers[HttpHeaders.authorizationHeader], 'Bearer abc');
  });

  test('omits the Authorization header without a token', () async {
    late Map<String, String> headers;
    final client = clientWith((request) async {
      headers = request.headers;
      return http.Response('{}', 200);
    });

    await client.get('/products');

    expect(headers.containsKey(HttpHeaders.authorizationHeader), isFalse);
  });

  test('POST sends a JSON body', () async {
    late String body;
    final client = clientWith((request) async {
      body = request.body;
      return http.Response('{}', 200);
    });

    await client.post('/auth/login', body: {'username': 'u', 'password': 'p'});

    expect(jsonDecode(body), {'username': 'u', 'password': 'p'});
  });

  test('maps 401 with a server message to UnauthorizedException', () async {
    final client = clientWith(
      (_) async =>
          http.Response(jsonEncode({'message': 'Invalid credentials'}), 401),
    );

    expect(
      () => client.post('/auth/login'),
      throwsA(
        isA<UnauthorizedException>().having(
          (e) => e.message,
          'message',
          'Invalid credentials',
        ),
      ),
    );
  });

  test('maps other non-2xx codes to ServerException', () async {
    final client = clientWith((_) async => http.Response('oops', 500));

    expect(
      () => client.get('/products'),
      throwsA(
        isA<ServerException>().having((e) => e.statusCode, 'status', 500),
      ),
    );
  });

  test('maps socket errors to NetworkException', () async {
    final client = clientWith((_) async => throw const SocketException('down'));

    expect(() => client.get('/products'), throwsA(isA<NetworkException>()));
  });

  test('maps a non-object body to ParseException', () async {
    final client = clientWith((_) async => http.Response('[1,2,3]', 200));

    expect(() => client.get('/products'), throwsA(isA<ParseException>()));
  });
}
