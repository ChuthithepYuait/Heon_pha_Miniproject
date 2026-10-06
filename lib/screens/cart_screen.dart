import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../providers/product_provider.dart';
import '../widgets/cart_item_tile.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  Future<void> _confirmOrder(BuildContext context) async {
    final cart = context.read<CartProvider>();
    final orderProvider = context.read<OrderProvider>();
    final token = context.read<AuthProvider>().token;

    if (token == null) return;

    final order = await orderProvider.createOrder(
      token: token,
      items: cart.items.values.toList(),
    );

    if (!context.mounted) return;

    if (order == null) {
      // ล้มเหลว — ตะกร้าต้องยังอยู่ครบเพื่อให้แก้จำนวนแล้วลองใหม่ได้
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(orderProvider.placeOrderError ?? 'Cannot create order'),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    cart.clearCart();

    context.read<ProductProvider>().fetchProducts(token);

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Order Confirmed'),
        content: Text(
          'Order #${order.id}\n'
          'Total: ฿${order.totalPrice}\n\n'
          'Thank you for your order.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (context.mounted) {
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final isPlacingOrder = context.watch<OrderProvider>().isPlacingOrder;
    final items = cart.items.values.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: items.isEmpty
          ? const Center(child: Text('Your cart is empty'))
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) =>
                  CartItemTile(cartItem: items[index]),
            ),
      bottomNavigationBar: items.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Items: ${cart.totalItems}'),
                        Text(
                          'Total: ฿${cart.totalPrice}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(

                        onPressed: isPlacingOrder
                            ? null
                            : () => _confirmOrder(context),
                        child: isPlacingOrder
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Confirm Order'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}