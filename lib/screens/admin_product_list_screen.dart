import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/api_config.dart';
import '../config/categories.dart';
import '../models/product.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import 'admin_product_form_screen.dart';

class AdminProductListScreen extends StatefulWidget {
  const AdminProductListScreen({super.key});

  @override
  State<AdminProductListScreen> createState() => _AdminProductListScreenState();
}

class _AdminProductListScreenState extends State<AdminProductListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _guardThenLoad());
  }

  void _guardThenLoad() {
    final auth = context.read<AuthProvider>();

    if (!(auth.user?.isAdmin ?? false)) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Admin role required'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    _loadProducts();
  }

  void _loadProducts() {
    final token = context.read<AuthProvider>().token;
    if (token != null) {
      context.read<ProductProvider>().fetchProducts(token);
    }
  }

  Future<void> _confirmDelete(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Delete "${product.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ลบสินค้า'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    final provider = context.read<ProductProvider>();
    final success = await provider.deleteProduct(token, product.id);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Deleted ${product.name}'
              : (provider.adminErrorMessage ?? 'Delete failed'),
        ),
      ),
    );
  }

  Future<void> _openForm({Product? product}) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AdminProductFormScreen(product: product),
      ),
    );

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(product == null ? 'Product created' : 'Product updated'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('จัดการสินค้า')),
      body: _buildBody(provider),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        tooltip: 'เพิ่มสินค้า',
        child: const Icon(Icons.add),
      ),
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
      return const Center(child: Text('No products yet'));
    }

    return RefreshIndicator(
      onRefresh: () async => _loadProducts(),
      child: ListView.separated(
        itemCount: provider.products.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final product = provider.products[index];

          return ListTile(
            leading: _ProductThumbnail(imageUrl: ApiConfig.imageUrl(product.image)),
            title: Text(product.name),
            subtitle: Text(
              '฿${product.price} · ${ProductCategory.names[product.categoryId] ?? 'ไม่ทราบหมวดหมู่'} · Stock: ${product.stock} · Size: ${product.sizes.isEmpty ? '-' : product.sizes.join(', ')}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'แก้ไข',
                  onPressed: () => _openForm(product: product),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'ลบ',
                  onPressed: () => _confirmDelete(product),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProductThumbnail extends StatelessWidget {
  final String imageUrl;

  const _ProductThumbnail({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: 40,
        height: 40,
        child: imageUrl.isEmpty
            ? _placeholder(context)
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _placeholder(context),
              ),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.coffee,
        size: 20,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}