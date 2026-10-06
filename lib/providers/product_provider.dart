import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product.dart';
import '../services/product_service.dart';

// Challenge 2 (plan.md ข้อ 57 / planV2.md ข้อ 59): Sort Product
enum ProductSortOption { none, priceLowHigh, priceHighLow, nameAZ }

class ProductProvider extends ChangeNotifier {
  final ProductService productService;

  List<Product> products = [];
  Product? selectedProduct;

  bool isLoading = false;
  String? errorMessage;

  String searchText = '';
  int? selectedCategoryId; // null = All
  ProductSortOption sortOption = ProductSortOption.none;

  ProductProvider({
    required this.productService,
  });

  List<Product> get filteredProducts {
    var list = products;

    if (selectedCategoryId != null) {
      list = list
          .where((product) => product.categoryId == selectedCategoryId)
          .toList();
    }

    if (searchText.isNotEmpty) {
      final query = searchText.toLowerCase();
      list = list
          .where((product) => product.name.toLowerCase().contains(query))
          .toList();
    }
    switch (sortOption) {
      case ProductSortOption.none:
        break;
      case ProductSortOption.priceLowHigh:
        list = [...list]..sort((a, b) => a.price.compareTo(b.price));
      case ProductSortOption.priceHighLow:
        list = [...list]..sort((a, b) => b.price.compareTo(a.price));
      case ProductSortOption.nameAZ:
        list = [...list]..sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
    }

    return list;
  }

  void setSearchText(String value) {
    searchText = value;
    notifyListeners();
  }

  void setCategory(int? categoryId) {
    selectedCategoryId = categoryId;
    notifyListeners();
  }

  void setSortOption(ProductSortOption option) {
    sortOption = option;
    notifyListeners();
  }

  Future<void> fetchProducts(String token) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      products = await productService.getProducts(token);
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshProducts(String token) => fetchProducts(token);

  Future<void> fetchProductById(String token, int id) async {
    isLoading = true;
    errorMessage = null;
    selectedProduct = null;
    notifyListeners();

    try {
      selectedProduct = await productService.getProductById(token, id);
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  bool isSaving = false;
  String? adminErrorMessage;

  Future<bool> createProduct({
    required String token,
    required String name,
    String? description,
    required String barcode,
    required int stock,
    required int price,
    required int categoryId,
    required List<String> sizes,
    XFile? imageFile,
  }) async {
    isSaving = true;
    adminErrorMessage = null;
    notifyListeners();

    try {
      final product = await productService.createProduct(
        token: token,
        name: name,
        description: description,
        barcode: barcode,
        stock: stock,
        price: price,
        categoryId: categoryId,
        sizes: sizes,
        imageFile: imageFile,
      );
      products = [product, ...products];
      return true;
    } catch (e) {
      adminErrorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> updateProduct({
    required String token,
    required int id,
    String? name,
    String? description,
    String? barcode,
    int? stock,
    int? price,
    int? categoryId,
    List<String>? sizes,
    XFile? imageFile,
  }) async {
    isSaving = true;
    adminErrorMessage = null;
    notifyListeners();

    try {
      final updated = await productService.updateProduct(
        token: token,
        id: id,
        name: name,
        description: description,
        barcode: barcode,
        stock: stock,
        price: price,
        categoryId: categoryId,
        sizes: sizes,
        imageFile: imageFile,
      );
      products = [
        for (final p in products) if (p.id == id) updated else p,
      ];
      return true;
    } catch (e) {
      adminErrorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> deleteProduct(String token, int id) async {
    isSaving = true;
    adminErrorMessage = null;
    notifyListeners();

    try {
      await productService.deleteProduct(token, id);
      products = products.where((p) => p.id != id).toList();
      return true;
    } catch (e) {
      adminErrorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}