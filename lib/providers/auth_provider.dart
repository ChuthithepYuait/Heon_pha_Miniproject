import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  final AuthService authService;

  String? token;
  User? user;

  bool isLoading = false;
  String? errorMessage;

  AuthProvider({
    required this.authService,
  });

  bool get isAuthenticated => token != null;

  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString(_tokenKey);
    final savedUserJson = prefs.getString(_userKey);

    if (savedToken != null && savedUserJson != null) {
      if (!_tokenHasUserId(savedToken)) {
        await _clearSession();
        return;
      }

      token = savedToken;
      user = User.fromJson(
        jsonDecode(savedUserJson) as Map<String, dynamic>,
      );
      notifyListeners();
    }
  }

  static bool _tokenHasUserId(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;

      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      ) as Map<String, dynamic>;

      return payload['id'] != null;
    } catch (_) {
      return false;
    }
  }

  Future<bool> login(
    String email,
    String password,
  ) async {
    return _authenticate(
      () => authService.login(
        email: email,
        password: password,
      ),
    );
  }

  Future<bool> register({
    required String firstname,
    required String lastname,
    required String email,
    required String password,
  }) async {
    return _authenticate(
      () => authService.register(
        firstname: firstname,
        lastname: lastname,
        email: email,
        password: password,
      ),
    );
  }

  Future<bool> _authenticate(
    Future<Map<String, dynamic>> Function() request,
  ) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final data = await request();

      token = data['token'];
      user = User.fromJson(data['user']);

      await _saveSession();

      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token!);
    await prefs.setString(_userKey, jsonEncode(user!.toJson()));
  }

  void logout() {
    token = null;
    user = null;
    notifyListeners();
    _clearSession();
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }
}