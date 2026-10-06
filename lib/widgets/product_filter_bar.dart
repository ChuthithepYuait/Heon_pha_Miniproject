import 'package:flutter/material.dart';
import '../config/categories.dart';
import '../providers/product_provider.dart';

// planV2.md ข้อ 56 Session 5 ชั่วโมงที่ 2-3: Search Field + Category FilterChip
// + Challenge 2 (plan.md ข้อ 57): Sort — รวมไว้ใน Widget เดียวเพื่อลด Code ซ้ำใน HomeScreen
class ProductFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final int? selectedCategoryId;
  final ValueChanged<int?> onCategorySelected;
  final ProductSortOption sortOption;
  final ValueChanged<ProductSortOption> onSortSelected;

  const ProductFilterBar({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.selectedCategoryId,
    required this.onCategorySelected,
    required this.sortOption,
    required this.onSortSelected,
  });

  static const _sortLabels = {
    ProductSortOption.none: 'Default order',
    ProductSortOption.priceLowHigh: 'Price: Low to High',
    ProductSortOption.priceHighLow: 'Price: High to Low',
    ProductSortOption.nameAZ: 'Name: A to Z',
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search coffee menu...',
              isDense: true,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        searchController.clear();
                        onSearchChanged('');
                      },
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      ChoiceChip(
                        label: const Text('All'),
                        selected: selectedCategoryId == null,
                        onSelected: (_) => onCategorySelected(null),
                      ),
                      for (final entry in ProductCategory.names.entries)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: ChoiceChip(
                            label: Text(entry.value),
                            selected: selectedCategoryId == entry.key,
                            onSelected: (_) => onCategorySelected(entry.key),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              PopupMenuButton<ProductSortOption>(
                tooltip: 'Sort',
                initialValue: sortOption,
                onSelected: onSortSelected,
                icon: Icon(
                  Icons.sort,
                  color: sortOption == ProductSortOption.none
                      ? null
                      : Theme.of(context).colorScheme.primary,
                ),
                itemBuilder: (context) => [
                  for (final entry in _sortLabels.entries)
                    PopupMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}