import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/favorite_provider.dart';
import '../widgets/product_card.dart';
import 'product_detail_screen.dart';

class FavoriteScreen extends StatelessWidget {
  const FavoriteScreen({super.key});

  Future<void> _addToCart(BuildContext context, Product product) async {
    final size = await pickProductSize(context, product);
    if (size == null || !context.mounted) return;

    final added = context.read<CartProvider>().addItem(product, size: size);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          added
              ? 'เพิ่ม ${product.name} (Size $size) แล้ว'
              : 'สินค้า ${product.name} มีไม่เพียงพอ',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoriteProvider>().favorites;

    return Scaffold(
      appBar: AppBar(title: const Text('รายการโปรด')),
      body: favorites.isEmpty
          ? const Center(child: Text('ยังไม่มีรายการโปรด'))
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final product = favorites[index];
                return ProductCard(
                  product: product,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(product: product),
                    ),
                  ),
                  onAddToCart: () => _addToCart(context, product),
                );
              },
            ),
    );
  }
}
