import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

class CartProvider extends ChangeNotifier {
  static const _storageKey = 'cart_items';

  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => _items;

  int get totalItems =>
      _items.values.fold(0, (sum, item) => sum + item.quantity);

  int get totalPrice =>
      _items.values.fold(0, (sum, item) => sum + item.subtotal);

  bool addItem(Product product, {required String size}) {
    final normalizedSize = size.trim();
    if (product.stock <= 0) return false;
    if (product.sizes.isNotEmpty && !product.sizes.contains(normalizedSize)) {
      return false;
    }

    final key = '${product.id}|$normalizedSize';
    final existing = _items[key];

    if (existing != null) {
      if (existing.quantity >= product.stock) return false;
      existing.quantity++;
    } else {
      _items[key] = CartItem(
        product: product,
        selectedSize: normalizedSize,
      );
    }

    _persist();
    notifyListeners();
    return true;
  }

  bool increaseQuantity(String cartKey) {
    final item = _items[cartKey];
    if (item == null) return false;
    if (item.quantity >= item.product.stock) return false;

    item.quantity++;
    _persist();
    notifyListeners();
    return true;
  }

  void decreaseQuantity(String cartKey) {
    if (!_items.containsKey(cartKey)) return;

    _items[cartKey]!.quantity--;

    if (_items[cartKey]!.quantity <= 0) {
      _items.remove(cartKey);
    }

    _persist();
    notifyListeners();
  }

  void removeItem(String cartKey) {
    _items.remove(cartKey);
    _persist();
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _persist();
    notifyListeners();
  }

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_storageKey);
    if (saved == null) return;

    try {
      final list = jsonDecode(saved) as List;

      _items.clear();
      for (final raw in list) {
        final item = CartItem.fromJson(raw as Map<String, dynamic>);
        _items[item.cartKey] = item;
      }

      notifyListeners();
    } catch (_) {
      await prefs.remove(_storageKey);
    }
  }

  void syncWithProducts(List<Product> products) {
    if (products.isEmpty || _items.isEmpty) return;

    final latest = {for (final product in products) product.id: product};
    var changed = false;

    for (final cartKey in _items.keys.toList()) {
      final item = _items[cartKey]!;
      final product = latest[item.product.id];

      if (product == null) {
        _items.remove(cartKey);
        changed = true;
        continue;
      }

      final synced = item.withProduct(product);
      if (synced.quantity <= 0) {
        _items.remove(cartKey);
      } else {
        _items.remove(cartKey);
        _items[synced.cartKey] = synced;
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

    if (_items.isEmpty) {
      await prefs.remove(_storageKey);
      return;
    }

    await prefs.setString(
      _storageKey,
      jsonEncode(_items.values.map((item) => item.toJson()).toList()),
    );
  }
}
