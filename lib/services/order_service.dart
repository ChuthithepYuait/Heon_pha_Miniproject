import 'dart:convert';
import '../config/api_config.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import 'api_client.dart';

class OrderService {
  final ApiClient apiClient;

  OrderService({ApiClient? apiClient}) : apiClient = apiClient ?? ApiClient();

  Future<Order> createOrder({
    required String token,
    required List<CartItem> items,
  }) async {
    final response = await apiClient.post(
      ApiConfig.orders,
      token: token,
      body: {
        'items': items
            .map((item) => {
                  'product_id': item.product.id,
                  'quantity': item.quantity,
                  'size': item.selectedSize,
                })
            .toList(),
      },
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return Order.fromJson(data['order'] as Map<String, dynamic>);
  }

  Future<List<Order>> getOrders(String token) async {
    final response = await apiClient.get(ApiConfig.orders, token: token);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final list = data['orders'] as List;

    return list
        .map((json) => Order.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Order> getOrderById(String token, int id) async {
    final response = await apiClient.get(
      ApiConfig.orderById(id),
      token: token,
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return Order.fromJson(data['order'] as Map<String, dynamic>);
  }
}
