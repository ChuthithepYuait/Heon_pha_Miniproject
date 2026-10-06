import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cart_item.dart';
import '../providers/cart_provider.dart';

class CartItemTile extends StatelessWidget {
  final CartItem cartItem;

  const CartItemTile({super.key, required this.cartItem});

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();

    final sizeText = cartItem.selectedSize.isEmpty
        ? ''
        : 'Size: ${cartItem.selectedSize}';

    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.checkroom)),
      title: Text(cartItem.product.name),
      subtitle: Text(
        [
          '฿${cartItem.product.price} each',
          if (sizeText.isNotEmpty) sizeText,
        ].join(' • '),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: () => cart.decreaseQuantity(cartItem.cartKey),
          ),
          Text('${cartItem.quantity}'),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              final increased = cart.increaseQuantity(cartItem.cartKey);
              if (!increased) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Only ${cartItem.product.stock} in stock'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            },
          ),
          const SizedBox(width: 8),
          Text(
            '฿${cartItem.subtotal}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
