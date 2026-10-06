class OrderItem {
  final int productId;
  final String productName;
  final String size;
  final int unitPrice;
  final int quantity;
  final int subtotal;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.size,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: _toInt(json['product_id']),
      productName: json['product_name'] ?? '',
      size: json['size']?.toString() ?? '',
      unitPrice: _toInt(json['unit_price']),
      quantity: _toInt(json['quantity']),
      subtotal: _toInt(json['subtotal']),
    );
  }
}

class Order {
  final int id;
  final String status;
  final int totalPrice;
  final DateTime? createdAt;
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.status,
    required this.totalPrice,
    this.createdAt,
    this.items = const [],
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];

    return Order(
      id: _toInt(json['id']),
      status: json['status'] ?? 'confirmed',
      totalPrice: _toInt(json['total_price']),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      items: rawItems is List
          ? rawItems
              .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
              .toList()
          : const [],
    );
  }

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
}

int _toInt(dynamic value) {
  if (value is int) return value;
  return int.parse(value.toString());
}
