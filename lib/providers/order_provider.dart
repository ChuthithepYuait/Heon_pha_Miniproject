import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../services/order_service.dart';

class OrderProvider extends ChangeNotifier {
  final OrderService orderService;

  List<Order> orders = [];
  Order? selectedOrder;

  bool isLoading = false;
  String? errorMessage;

  bool isPlacingOrder = false;
  String? placeOrderError;

  OrderProvider({
    required this.orderService,
  });

  Future<void> fetchOrders(String token) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      orders = await orderService.getOrders(token);
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchOrderById(String token, int id) async {
    isLoading = true;
    errorMessage = null;
    selectedOrder = null;
    notifyListeners();

    try {
      selectedOrder = await orderService.getOrderById(token, id);
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<Order?> createOrder({
    required String token,
    required List<CartItem> items,
  }) async {
    isPlacingOrder = true;
    placeOrderError = null;
    notifyListeners();

    try {
      final order = await orderService.createOrder(token: token, items: items);

      orders = [order, ...orders];
      return order;
    } catch (e) {
      placeOrderError = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      isPlacingOrder = false;
      notifyListeners();
    }
  }
}