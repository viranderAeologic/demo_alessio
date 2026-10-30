import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../errors/app_exception.dart';
import '../storage/token_storage.dart';

/// Thin wrapper around `package:http` shared by every data source.
///
/// Responsibilities:
/// * builds absolute URLs from the base URL,
/// * attaches the bearer token when one is stored,
/// * maps transport failures and non-2xx responses to [AppException]s,
/// * decodes JSON object bodies.
class ApiClient {
  ApiClient({
    required this._tokenStorage,
    http.Client? httpClient,
    this._baseUrl = ApiConstants.baseUrl,
    this._timeout = ApiConstants.requestTimeout,
  }) : _http = httpClient ?? http.Client();

  final TokenStorage _tokenStorage;
  final http.Client _http;
  final String _baseUrl;
  final Duration _timeout;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
  }) async {
    final uri = _buildUri(path, query);
    final headers = await _headers();
    return _send(() => _http.get(uri, headers: headers));
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = _buildUri(path, null);
    final headers = await _headers(json: true);
    return _send(
      () => _http.post(uri, headers: headers, body: jsonEncode(body ?? {})),
    );
  }

  Uri _buildUri(String path, Map<String, String>? query) {
    return Uri.parse('$_baseUrl$path').replace(queryParameters: query);
  }

  Future<Map<String, String>> _headers({bool json = false}) async {
    final headers = <String, String>{
      HttpHeaders.acceptHeader: 'application/json',
      if (json) HttpHeaders.contentTypeHeader: 'application/json',
    };
    final token = await _tokenStorage.readToken();
    if (token != null && token.isNotEmpty) {
      headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
    }
    return headers;
  }

  Future<Map<String, dynamic>> _send(
    Future<http.Response> Function() request,
  ) async {
    final http.Response response;
    try {
      response = await request().timeout(_timeout);
    } on SocketException {
      throw const NetworkException();
    } on TimeoutException {
      throw const NetworkException('The request timed out. Please try again.');
    } on http.ClientException {
      throw const NetworkException();
    }

    final status = response.statusCode;
    if (status == HttpStatus.unauthorized || status == HttpStatus.forbidden) {
      throw UnauthorizedException(
        _extractMessage(response.body) ?? 'Invalid username or password.',
      );
    }
    if (status < 200 || status >= 300) {
      throw ServerException(
        status,
        _extractMessage(response.body) ?? 'Request failed with status $status.',
      );
    }

    return _decodeObject(response.body);
  }

  Map<String, dynamic> _decodeObject(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
    } on FormatException {
      // fall through
    }
    throw const ParseException();
  }

  /// DummyJSON returns `{"message": "..."}` on errors; use it when present.
  String? _extractMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'];
        if (message is String && message.isNotEmpty) return message;
      }
    } on FormatException {
      // ignore – body is not JSON
    }
    return null;
  }
}
