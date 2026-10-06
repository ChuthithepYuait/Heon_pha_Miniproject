import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/favorite_provider.dart';
import '../providers/product_provider.dart';
import '../widgets/product_card.dart';
import '../widgets/product_filter_bar.dart';
import 'product_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProducts());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    final productProvider = context.read<ProductProvider>();
    await productProvider.fetchProducts(token);

    if (!mounted) return;

    context.read<CartProvider>().syncWithProducts(productProvider.products);
    context.read<FavoriteProvider>().syncWithProducts(productProvider.products);
  }

  void _handleLogout() {
    context.read<AuthProvider>().logout();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  void _addToCart(Product product) {
    pickProductSize(context, product).then((size) {
      if (size == null || !mounted) return;
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Coffee'),
        actions: [
          // Challenge 1 (plan.md ข้อ 57): ทางเข้าหน้า Favorite
          Consumer<FavoriteProvider>(
            builder: (context, favorites, _) => _BadgeIconButton(
              icon: Icons.favorite_border,
              count: favorites.favorites.length,
              tooltip: 'Favorites',
              onPressed: () => Navigator.pushNamed(context, '/favorites'),
            ),
          ),
          Consumer<CartProvider>(
            builder: (context, cart, _) => _BadgeIconButton(
              icon: Icons.shopping_cart,
              count: cart.totalItems,
              tooltip: 'Cart',
              onPressed: () => Navigator.pushNamed(context, '/cart'),
            ),
          ),
          if (user?.isAdmin ?? false)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings_outlined),
              tooltip: 'Manage Products',
              onPressed: () => Navigator.pushNamed(context, '/admin'),
            ),
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'My Orders',
            onPressed: () => Navigator.pushNamed(context, '/orders'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _buildBody(productProvider),
    );
  }
  Widget _buildBody(ProductProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(provider.errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _loadProducts, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (provider.products.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('No coffee menu available'),
            const SizedBox(height: 12),
            FilledButton(onPressed: _loadProducts, child: const Text('Refresh')),
          ],
        ),
      );
    }
    final filtered = provider.filteredProducts;

    return Column(
      children: [
        ProductFilterBar(
          searchController: _searchController,
          onSearchChanged: provider.setSearchText,
          selectedCategoryId: provider.selectedCategoryId,
          onCategorySelected: provider.setCategory,
          sortOption: provider.sortOption,
          onSortSelected: provider.setSortOption,
        ),
        Expanded(
          child: filtered.isEmpty
              ? _buildNoResults(provider)
              : RefreshIndicator(
                  onRefresh: () async {
                    final token = context.read<AuthProvider>().token;
                    if (token != null) {
                      await context.read<ProductProvider>().refreshProducts(token);
                    }
                  },
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final product = filtered[index];
                      return ProductCard(
                        product: product,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductDetailScreen(product: product),
                          ),
                        ),
                        onAddToCart: () => _addToCart(product),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildNoResults(ProductProvider provider) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('No products match your search'),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              _searchController.clear();
              provider.setSearchText('');
              provider.setCategory(null);
            },
            child: const Text('Clear filters'),
          ),
        ],
      ),
    );
  }
}

class _BadgeIconButton extends StatelessWidget {
  final IconData icon;
  final int count;
  final String tooltip;
  final VoidCallback onPressed;

  const _BadgeIconButton({
    required this.icon,
    required this.count,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: Icon(icon),
          tooltip: tooltip,
          onPressed: onPressed,
        ),
        if (count > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                '$count',
                style: const TextStyle(color: Colors.white, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
