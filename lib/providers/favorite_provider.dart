import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';

class FavoriteProvider extends ChangeNotifier {
  static const _storageKey = 'favorite_products';

  final Map<int, Product> _favorites = {};

  List<Product> get favorites => _favorites.values.toList();

  bool isFavorite(int productId) => _favorites.containsKey(productId);

  void toggleFavorite(Product product) {
    if (_favorites.containsKey(product.id)) {
      _favorites.remove(product.id);
    } else {
      _favorites[product.id] = product;
    }

    _persist();
    notifyListeners();
  }

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_storageKey);
    if (saved == null) return;

    try {
      final list = jsonDecode(saved) as List;

      _favorites.clear();
      for (final raw in list) {
        final product = Product.fromJson(raw as Map<String, dynamic>);
        _favorites[product.id] = product;
      }

      notifyListeners();
    } catch (_) {
      await prefs.remove(_storageKey);
    }
  }

  void syncWithProducts(List<Product> products) {
    if (products.isEmpty || _favorites.isEmpty) return;

    final latest = {for (final product in products) product.id: product};
    var changed = false;

    for (final productId in _favorites.keys.toList()) {
      final product = latest[productId];

      if (product == null) {
        _favorites.remove(productId);
      } else {
        _favorites[productId] = product;
      }
      changed = true;
    }

    if (changed) {
      _persist();
      notifyListeners();
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();

    if (_favorites.isEmpty) {
      await prefs.remove(_storageKey);
      return;
    }

    await prefs.setString(
      _storageKey,
      jsonEncode(_favorites.values.map((product) => product.toJson()).toList()),
    );
  }
}