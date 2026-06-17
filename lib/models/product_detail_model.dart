class ProductDetailModel {
  const ProductDetailModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.ratingAverage,
    required this.stockQuantity,
    required this.imageUrl,
    required this.imageUrls,
    required this.category,
    required this.categoryId,
    required this.sellerId,
    required this.shopId,
    required this.status,
    required this.colors,
    required this.sizes,
  });

  final String id;
  final String name;
  final String description;
  final double price;
  final double ratingAverage;
  final int stockQuantity;
  final String imageUrl;
  final List<String> imageUrls;
  final String category;
  final String categoryId;
  final String sellerId;
  final String shopId;
  final String status;
  final List<String> colors;
  final List<String> sizes;

  bool get isAvailable {
    return status == 'active' && stockQuantity > 0;
  }

  factory ProductDetailModel.fromFirebase(
    String id,
    Map<dynamic, dynamic> map,
  ) {
    final images = _readImageUrls(map);

    return ProductDetailModel(
      id: id,
      name: _readString(map, ['name', 'productName', 'title']),
      description: _readString(map, ['description', 'detail', 'desc']),
      price: _readDouble(map, ['salePrice', 'discountPrice', 'price']),
      ratingAverage: _readDouble(map, ['ratingAverage', 'rating', 'stars']),
      stockQuantity: _readInt(map, ['stock_quantity', 'stock', 'quantity']),
      imageUrl: images.isEmpty ? '' : images.first,
      imageUrls: images,
      category: _readString(map, ['category', 'categoryName']),
      categoryId: _readString(map, ['categoryId']),
      sellerId: _readString(map, ['sellerId']),
      shopId: _readString(map, ['shopId']),
      status: _readString(map, ['status'], fallback: 'active'),
      colors: _readStringList(map, ['colors', 'colorOptions']),
      sizes: _readStringList(map, ['sizes', 'sizeOptions']),
    );
  }

  Map<String, Object?> toCartItemMap({
    required int quantity,
    required String selectedColor,
    required String selectedSize,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;

    return {
      'sellerId': sellerId,
      'shopId': shopId,
      'productName': name,
      'thumbnailUrl': imageUrl,
      'unitPrice': price,
      'quantity': quantity,
      'selectedColor': selectedColor,
      'selectedSize': selectedSize,
      'subtotal': price * quantity,
      'updatedAt': now,
    };
  }

  static String _readString(
    Map<dynamic, dynamic> map,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = map[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return fallback;
  }

  static double _readDouble(Map<dynamic, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is num) {
        return value.toDouble();
      }
      if (value is String) {
        return double.tryParse(value) ?? 0;
      }
    }
    return 0;
  }

  static int _readInt(Map<dynamic, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is int) {
        return value;
      }
      if (value is num) {
        return value.toInt();
      }
      if (value is String) {
        return int.tryParse(value) ?? 0;
      }
    }
    return 0;
  }

  static List<String> _readImageUrls(Map<dynamic, dynamic> map) {
    final images = <String>[];
    final thumbnail = _readString(map, ['thumbnailUrl', 'imageUrl', 'image']);
    if (thumbnail.isNotEmpty) {
      images.add(thumbnail);
    }

    final imageUrls = map['imageUrls'];
    if (imageUrls is Map) {
      images.addAll(
        imageUrls.values.map((value) => value.toString()).where(
              (value) => value.trim().isNotEmpty,
            ),
      );
    }
    if (imageUrls is List) {
      images.addAll(
        imageUrls.map((value) => value.toString()).where(
              (value) => value.trim().isNotEmpty,
            ),
      );
    }

    return images.toSet().toList();
  }

  static List<String> _readStringList(
    Map<dynamic, dynamic> map,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = map[key];
      if (value is List) {
        return value
            .map((item) => item.toString())
            .where((item) => item.trim().isNotEmpty)
            .toList();
      }
      if (value is Map) {
        return value.values
            .map((item) => item.toString())
            .where((item) => item.trim().isNotEmpty)
            .toList();
      }
    }
    return const [];
  }
}
