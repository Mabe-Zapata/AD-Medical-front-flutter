import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:medicalbooking_portal/core/domain/app_error.dart';

/// Thin wrapper over `http.Client` for the backend REST API: base URL, bearer token,
/// JSON in and out, and RFC 9457 problem+json mapped to [AppError].
class ApiClient {
  ApiClient({
    required this._client,
    required this.baseUrl,
    this.token,
    this.onUnauthorized,
    this.timeout = const Duration(seconds: 20),
  });

  final http.Client _client;

  /// Absolute (`https://host/api/v1`) or origin-relative (`/api/v1`).
  final String baseUrl;

  /// The current bearer token, read on every call so a new session is picked up.
  final String? Function()? token;

  /// Called when the API rejects the token of a signed-in session (401).
  final void Function()? onUnauthorized;
  final Duration timeout;

  Future<Object?> get(String path, {Map<String, String>? query, String? bearer}) =>
      _send('GET', path, query: query, bearer: bearer);

  /// [authenticated] is false only for the login call, where a 401 means wrong credentials.
  Future<Object?> post(
    String path, {
    Object? body,
    Map<String, String>? headers,
    bool authenticated = true,
  }) => _send('POST', path, body: body, headers: headers, authenticated: authenticated);

  Future<Object?> put(String path, {Object? body}) => _send('PUT', path, body: body);

  Uri _uri(String path, Map<String, String>? query) {
    final base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final uri = Uri.parse('$base$path');
    // Origin-relative URLs resolve against the page, as `fetch` does in the browser.
    final absolute = uri.hasScheme ? uri : Uri.base.resolveUri(uri);
    return query == null ? absolute : absolute.replace(queryParameters: query);
  }

  Future<Object?> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
    Map<String, String>? headers,
    bool authenticated = true,
    String? bearer,
  }) async {
    final request = http.Request(method, _uri(path, query));
    request.headers['Accept'] = 'application/json';
    final current = bearer ?? token?.call();
    if (current != null) request.headers['Authorization'] = 'Bearer $current';
    if (headers != null) request.headers.addAll(headers);
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    final http.Response response;
    try {
      response = await http.Response.fromStream(await _client.send(request).timeout(timeout));
    } on TimeoutException {
      throw const AppError(ErrorKind.network, 'Request timed out');
    } on http.ClientException catch (e) {
      throw AppError(ErrorKind.network, e.message);
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.bodyBytes.isEmpty ? null : jsonDecode(utf8.decode(response.bodyBytes));
    }
    final error = _problem(response, authenticated: authenticated);
    if (response.statusCode == 401 && authenticated && current != null) onUnauthorized?.call();
    throw error;
  }

  AppError _problem(http.Response response, {required bool authenticated}) {
    String detail = 'HTTP ${response.statusCode}';
    String? correlationId;
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is Map) {
        if (body['detail'] is String) detail = body['detail'] as String;
        if (body['correlation_id'] is String) correlationId = body['correlation_id'] as String;
      }
    } on FormatException {
      // Not JSON (for example an Nginx error page): the status code is enough.
    }
    final kind = switch (response.statusCode) {
      401 => authenticated ? ErrorKind.unauthenticated : ErrorKind.invalidCredentials,
      403 => ErrorKind.forbidden,
      404 => ErrorKind.notFound,
      409 => ErrorKind.conflict,
      422 => ErrorKind.validation,
      429 => ErrorKind.rateLimited,
      // Nginx or the load balancer answer these when no replica is up, or the database is down.
      502 || 503 || 504 => ErrorKind.unavailable,
      _ => ErrorKind.unknown,
    };
    return AppError(kind, detail, correlationId: correlationId, status: response.statusCode);
  }

  void close() => _client.close();
}
