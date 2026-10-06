import 'dart:convert';
import 'package:http/http.dart' as http;

/// โยนเมื่อ Backend ตอบ 401 — แปลว่า session ใช้ไม่ได้แล้ว ไม่ใช่ว่า request ผิด
class UnauthorizedException implements Exception {
  final String message;

  UnauthorizedException(this.message);

  @override
  String toString() => message;
}

/// โยนเมื่อ Backend ตอบ status code อื่นที่ไม่ใช่ 2xx
class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class ApiClient {

  static void Function()? onUnauthorized;

  final http.Client _client;

  // รับ http.Client เข้ามาได้เพื่อให้เขียน test ได้โดยไม่ต้องยิง HTTP จริง
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> _headers(String? token, {bool json = true}) => {
        if (json) 'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<http.Response> get(String url, {String? token}) async {
    return _check(await _client.get(Uri.parse(url), headers: _headers(token)));
  }

  Future<http.Response> post(
    String url, {
    String? token,
    Object? body,
  }) async {
    return _check(await _client.post(
      Uri.parse(url),
      headers: _headers(token),
      body: body == null ? null : jsonEncode(body),
    ));
  }

  Future<http.Response> delete(String url, {String? token}) async {
    return _check(
      await _client.delete(Uri.parse(url), headers: _headers(token, json: false)),
    );
  }

  Future<http.Response> send(http.MultipartRequest request) async {
    final streamed = await _client.send(request);
    return _check(await http.Response.fromStream(streamed));
  }

  http.Response _check(http.Response response) {
    if (response.statusCode == 401) {
    
      onUnauthorized?.call();
      throw UnauthorizedException(
        _messageOf(response) ?? 'Session expired, please log in again',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        response.statusCode,
        _messageOf(response) ?? 'Request failed (${response.statusCode})',
      );
    }

    return response;
  }

  String? _messageOf(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
    } catch (_) {
    }
    return null;
  }
}