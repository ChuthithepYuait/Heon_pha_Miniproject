import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:3000';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

  static String get login => '$baseUrl/api/auth/login';
  static String get register => '$baseUrl/api/auth/register';
  static String get products => '$baseUrl/api/products';
  static String productById(int id) => '$baseUrl/api/products/$id';

  // feature.md A2 — Order API
  static String get orders => '$baseUrl/api/orders';
  static String orderById(int id) => '$baseUrl/api/orders/$id';

  static String imageUrl(String? filename) {
    if (filename == null || filename.isEmpty) return '';
    return '$baseUrl/uploads/images/$filename';
  }
}