class Product {
  final int id;
  final String name;
  final String? description;
  final String? image;
  final int stock;
  final int price;
  final int categoryId;
  final String? barcode;
  final List<String> sizes;

  Product({
    required this.id,
    required this.name,
    this.description,
    this.image,
    required this.stock,
    required this.price,
    required this.categoryId,
    this.barcode,
    this.sizes = const [],
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawSizes = json['sizes'];
    final parsedSizes = <String>[];

    if (rawSizes is List) {
      parsedSizes.addAll(
        rawSizes
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty),
      );
    } else if (rawSizes != null) {
      parsedSizes.addAll(
        rawSizes
            .toString()
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty),
      );
    }

    return Product(
      id: _toInt(json['id']),
      name: json['name'] ?? '',
      description: json['description'],
      image: json['image'],
      stock: _toInt(json['stock']),
      price: _toInt(json['price']),
      categoryId: _toInt(json['category_id']),
      barcode: json['barcode']?.toString(),
      sizes: List.unmodifiable(parsedSizes),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'image': image,
        'stock': stock,
        'price': price,
        'category_id': categoryId,
        'barcode': barcode,
        'sizes': sizes,
      };

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.parse(value.toString());
  }
}
