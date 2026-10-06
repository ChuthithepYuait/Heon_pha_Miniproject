import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/api_config.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/favorite_provider.dart';

Future<String?> pickProductSize(BuildContext context, Product product) async {
  if (product.sizes.length <= 1) {
    return product.sizes.isEmpty ? '' : product.sizes.first;
  }

  var selected = product.sizes.first;

  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'เลือก Size',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: product.sizes.map((size) {
                      return ChoiceChip(
                        label: Text(size),
                        selected: selected == size,
                        onSelected: (_) {
                          setSheetState(() => selected = size);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: () => Navigator.pop(sheetContext, selected),
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('เพิ่มลงตะกร้า'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late String _selectedSize;

  @override
  void initState() {
    super.initState();
    _selectedSize =
        widget.product.sizes.isEmpty ? '' : widget.product.sizes.first;
  }

  Future<void> _addToCart() async {
    if (widget.product.sizes.length > 1 && _selectedSize.isEmpty) {
      final selected = await pickProductSize(context, widget.product);
      if (selected == null || !mounted) return;
      _selectedSize = selected;
    }

    final added = context.read<CartProvider>().addItem(
          widget.product,
          size: _selectedSize,
        );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          added
              ? 'เพิ่ม ${widget.product.name} (Size $_selectedSize) แล้ว'
              : 'สินค้า ${widget.product.name} มีไม่เพียงพอ',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final imageUrl = ApiConfig.imageUrl(product.image);

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        actions: [
          Consumer<FavoriteProvider>(
            builder: (context, favorites, _) {
              final isFavorite = favorites.isFavorite(product.id);
              return IconButton(
                onPressed: () => favorites.toggleFavorite(product),
                icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
                color: isFavorite ? Colors.red : null,
                tooltip: isFavorite ? 'ลบออกจากรายการโปรด' : 'เพิ่มรายการโปรด',
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.2,
              child: imageUrl.isEmpty
                  ? _placeholder(context)
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) =>
                          _placeholder(context),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '฿${product.price}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 18),
                  if (product.sizes.isNotEmpty) ...[
                    Text(
                      'Size',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: product.sizes.map((size) {
                        return ChoiceChip(
                          label: Text(size),
                          selected: _selectedSize == size,
                          onSelected: (_) {
                            setState(() => _selectedSize = size);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                  ],
                  if (product.description != null &&
                      product.description!.isNotEmpty) ...[
                    Text(
                      product.description!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    'คงเหลือ: ${product.stock} ชิ้น',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: product.stock <= 0 ? null : _addToCart,
              icon: const Icon(Icons.add_shopping_cart),
              label: Text(
                product.stock <= 0 ? 'สินค้าหมด' : 'เพิ่มลงตะกร้า',
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.checkroom,
        size: 64,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
