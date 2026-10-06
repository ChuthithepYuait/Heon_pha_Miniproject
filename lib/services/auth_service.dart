import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class AuthService {
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    return _post(
      url: ApiConfig.login,
      body: {
        'email': email,
        'password': password,
      },
      fallbackErrorMessage: 'Login failed',
    );
  }

  Future<Map<String, dynamic>> register({
    required String firstname,
    required String lastname,
    required String email,
    required String password,
  }) async {
    return _post(
      url: ApiConfig.register,
      body: {
        'firstname': firstname,
        'lastname': lastname,
        'email': email,
        'password': password,
      },
      fallbackErrorMessage: 'Register failed',
    );
  }

  Future<Map<String, dynamic>> _post({
    required String url,
    required Map<String, dynamic> body,
    required String fallbackErrorMessage,
  }) async {
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    throw Exception(
      data['message']?.toString() ?? fallbackErrorMessage,
    );
  }
}