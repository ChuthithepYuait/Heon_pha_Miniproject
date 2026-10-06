import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../config/api_config.dart';
import '../models/product.dart';
import 'api_client.dart';

class ProductService {
  final ApiClient apiClient;

  ProductService({ApiClient? apiClient}) : apiClient = apiClient ?? ApiClient();

  Future<List<Product>> getProducts(String token) async {
    final response = await apiClient.get(ApiConfig.products, token: token);
    final data = jsonDecode(response.body);
    final List list = data is List ? data : (data['products'] as List);

    return list
        .map((json) => Product.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Product> getProductById(String token, int id) async {
    final response = await apiClient.get(
      ApiConfig.productById(id),
      token: token,
    );

    return Product.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Product> createProduct({
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
    final request = http.MultipartRequest('POST', Uri.parse(ApiConfig.products))
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['name'] = name
      ..fields['description'] = description ?? ''
      ..fields['barcode'] = barcode
      ..fields['stock'] = stock.toString()
      ..fields['price'] = price.toString()
      ..fields['category_id'] = categoryId.toString()
      ..fields['sizes'] = sizes.join(',')
      ..fields['status_id'] = '1';

    if (imageFile != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'photo',
          await imageFile.readAsBytes(),
          filename: imageFile.name,
        ),
      );
    }

    return _sendProductForm(request);
  }

  Future<Product> updateProduct({
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
    final request = http.MultipartRequest(
      'PUT',
      Uri.parse(ApiConfig.productById(id)),
    )..headers['Authorization'] = 'Bearer $token';

    if (name != null) request.fields['name'] = name;
    if (description != null) request.fields['description'] = description;
    if (barcode != null) request.fields['barcode'] = barcode;
    if (stock != null) request.fields['stock'] = stock.toString();
    if (price != null) request.fields['price'] = price.toString();
    if (categoryId != null) request.fields['category_id'] = categoryId.toString();
    if (sizes != null) request.fields['sizes'] = sizes.join(',');

    if (imageFile != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'photo',
          await imageFile.readAsBytes(),
          filename: imageFile.name,
        ),
      );
    }

    return _sendProductForm(request);
  }

  Future<Product> _sendProductForm(http.MultipartRequest request) async {
    final response = await apiClient.send(request);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return Product.fromJson(data['product'] as Map<String, dynamic>);
  }

  Future<void> deleteProduct(String token, int id) async {
    await apiClient.delete(ApiConfig.productById(id), token: token);
  }
}
