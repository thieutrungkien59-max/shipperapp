import 'dart:convert';
import 'package:http/http.dart' as http;

import '../core/config/app_config.dart';
import 'session_service.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.body});

  final String message;
  final int? statusCode;
  final dynamic body;

  @override
  String toString() => message;
}

class ApiServices {
  ApiServices({http.Client? client, Duration? timeout})
    : _client = client ?? http.Client(),
      _timeout = timeout ?? const Duration(seconds: 20);

  final http.Client _client;
  final Duration _timeout;

  static String get baseUrl => AppConfig.apiBaseUrl;

  Future<Map<String, String>> _buildHeaders() async {
    final token = await SessionService.getAccessToken();
    return <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
      'ngrok-skip-browser-warning': 'true',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> get(String endpoint) async {
    return _send('GET', endpoint);
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    return _send('POST', endpoint, body: body);
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    return _send('PUT', endpoint, body: body);
  }

  Future<dynamic> patch(String endpoint, Map<String, dynamic> body) async {
    return _send('PATCH', endpoint, body: body);
  }

  Future<dynamic> delete(String endpoint, {Map<String, dynamic>? body}) async {
    return _send('DELETE', endpoint, body: body);
  }

  Future<dynamic> _send(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final url = AppConfig.resolve(endpoint);
    try {
      final headers = await _buildHeaders();
      final encodedBody = body == null ? null : jsonEncode(body);
      final http.Response response;

      switch (method) {
        case 'GET':
          response = await _client.get(url, headers: headers).timeout(_timeout);
          break;
        case 'POST':
          response = await _client
              .post(url, headers: headers, body: encodedBody)
              .timeout(_timeout);
          break;
        case 'PUT':
          response = await _client
              .put(url, headers: headers, body: encodedBody)
              .timeout(_timeout);
          break;
        case 'PATCH':
          response = await _client
              .patch(url, headers: headers, body: encodedBody)
              .timeout(_timeout);
          break;
        case 'DELETE':
          response = await _client
              .delete(url, headers: headers, body: encodedBody)
              .timeout(_timeout);
          break;
        default:
          throw ArgumentError.value(
            method,
            'method',
            'Unsupported HTTP method',
          );
      }

      return await _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Lỗi kết nối mạng tới $baseUrl: $e');
    }
  }

  Future<dynamic> _handleResponse(http.Response response) async {
    final decoded = _decodeBody(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    if (response.statusCode == 401) {
      await SessionService.clear();
    }

    final serverMessage = _extractMessage(decoded);
    final message = switch (response.statusCode) {
      400 => serverMessage ?? 'Yêu cầu không hợp lệ (400)',
      401 =>
        serverMessage ?? 'Sai thông tin đăng nhập hoặc phiên đã hết hạn (401)',
      403 => serverMessage ?? 'Không có quyền truy cập (403)',
      404 => serverMessage ?? 'Không tìm thấy API hoặc dữ liệu (404)',
      >= 500 =>
        serverMessage == null
            ? 'Lỗi máy chủ (${response.statusCode})'
            : 'Lỗi máy chủ (${response.statusCode}): $serverMessage',
      _ => serverMessage ?? 'Đã xảy ra lỗi: ${response.statusCode}',
    };

    throw ApiException(message, statusCode: response.statusCode, body: decoded);
  }

  dynamic _decodeBody(String body) {
    if (body.trim().isEmpty) return null;
    try {
      return jsonDecode(body);
    } catch (_) {
      return body;
    }
  }

  String? _extractMessage(dynamic decoded) {
    if (decoded is Map) {
      return (decoded['message'] ?? decoded['title'] ?? decoded['error'])
          ?.toString();
    }
    if (decoded is String && decoded.trim().isNotEmpty) return decoded.trim();
    return null;
  }
}
