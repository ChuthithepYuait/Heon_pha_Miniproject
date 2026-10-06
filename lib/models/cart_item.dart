import 'product.dart';

class CartItem {
  final Product product;
  final String selectedSize;
  int quantity;

  CartItem({
    required this.product,
    required this.selectedSize,
    this.quantity = 1,
  });

  int get subtotal => product.price * quantity;

  String get cartKey => '${product.id}|$selectedSize';

  Map<String, dynamic> toJson() => {
        'product': product.toJson(),
        'selected_size': selectedSize,
        'quantity': quantity,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final product = Product.fromJson(json['product'] as Map<String, dynamic>);
    final savedSize = json['selected_size']?.toString() ?? '';
    final selectedSize = savedSize.isNotEmpty
        ? savedSize
        : (product.sizes.isNotEmpty ? product.sizes.first : '');

    return CartItem(
      product: product,
      selectedSize: selectedSize,
      quantity: json['quantity'] as int,
    );
  }

  CartItem withProduct(Product latest) {
    final sizeStillAvailable =
        selectedSize.isEmpty || latest.sizes.isEmpty || latest.sizes.contains(selectedSize);

    final syncedSize = sizeStillAvailable
        ? selectedSize
        : latest.sizes.isNotEmpty
            ? latest.sizes.first
            : '';

    return CartItem(
      product: latest,
      selectedSize: syncedSize,
      quantity: quantity > latest.stock ? latest.stock : quantity,
    );
  }
}
