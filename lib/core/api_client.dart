import 'dart:convert';

import 'package:http/http.dart' as http;

import 'config.dart';
import 'token_store.dart';

/// Simple HTTP client with JSON helpers and optional auth header support.
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri _uri(String path, [Map<String, String>? query]) {
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('${AppConfig.apiBaseUrl}$normalized').replace(queryParameters: query);
  }

  Future<Map<String, String>> _headers([Map<String, String>? extra]) async {
    // TODO: Load token from secure storage if needed.
    final token = TokenStore.instance.token;
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    if (extra != null) headers.addAll(extra);
    return headers;
  }

  Future<dynamic> getJson(String path, {Map<String, String>? query}) async {
    final res = await _client.get(_uri(path, query), headers: await _headers());
    return _parse(res);
  }

  Future<dynamic> postJson(String path, Object body) async {
    final res = await _client.post(
      _uri(path),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _parse(res);
  }

  Future<dynamic> putJson(String path, Object body) async {
    final res = await _client.put(
      _uri(path),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _parse(res);
  }

  Future<void> delete(String path) async {
    final res = await _client.delete(
      _uri(path),
      headers: await _headers(),
    );
    _ensureOk(res);
  }

  dynamic _parse(http.Response res) {
    _ensureOk(res);
    if (res.body.isEmpty) return null;
    return jsonDecode(res.body);
  }

  void _ensureOk(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(
        statusCode: res.statusCode,
        message: 'Request failed: ${res.request?.method} ${res.request?.url} => ${res.statusCode}',
        body: res.body,
      );
    }
  }
}

class ApiException implements Exception {
  ApiException({required this.statusCode, required this.message, this.body});
  final int statusCode;
  final String message;
  final String? body;

  @override
  String toString() => 'ApiException($statusCode): $message${body == null ? '' : '\n$body'}';
}
