class ProductModel {
  const ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.rating,
    required this.imageUrl,
    this.salePrice,
    this.brand,
    this.categoryId,
    this.categoryName,
    this.sellerId,
    this.shopId,
    this.stock = 0,
    this.soldCount = 0,
    this.status = 'active',
  });

  final String id;
  final String name;
  final double price;
  final double? salePrice;
  final double rating;
  final String imageUrl;
  final String? brand;
  final String? categoryId;
  final String? categoryName;
  final String? sellerId;
  final String? shopId;
  final int stock;
  final int soldCount;
  final String status;

  double get displayPrice => salePrice ?? price;

  factory ProductModel.fromFirebase(String id, Map<dynamic, dynamic> json) {
    return ProductModel(
      id: id,
      name: _readString(json, ['name', 'productName', 'title']),
      price: _readDouble(json, ['price']),
      salePrice: _readNullableDouble(json, ['salePrice', 'discountPrice']),
      rating: _readDouble(json, ['ratingAverage', 'rating', 'stars']),
      imageUrl: _readImageUrl(json),
      brand: _readNullableString(json, ['brand', 'brandName']),
      categoryId: _readNullableString(json, ['categoryId']),
      categoryName: _readNullableString(json, ['categoryName', 'category']),
      sellerId: _readNullableString(json, ['sellerId']),
      shopId: _readNullableString(json, ['shopId']),
      stock: _readInt(json, ['stock', 'quantity']),
      soldCount: _readInt(json, ['soldCount', 'sold']),
      status: _readString(json, ['status'], fallback: 'active'),
    );
  }

  bool matchesKeyword(String keyword) {
    final normalizedKeyword = keyword.trim().toLowerCase();
    if (normalizedKeyword.isEmpty) {
      return true;
    }

    return name.toLowerCase().contains(normalizedKeyword);
  }

  bool matchesPriceRange(double? minPrice, double? maxPrice) {
    final priceValue = displayPrice;
    final isAboveMin = minPrice == null || priceValue >= minPrice;
    final isBelowMax = maxPrice == null || priceValue <= maxPrice;
    return isAboveMin && isBelowMax;
  }

  bool matchesBrand(String? selectedBrand) {
    if (selectedBrand == null || selectedBrand.trim().isEmpty) {
      return true;
    }

    return (brand ?? '').toLowerCase() == selectedBrand.trim().toLowerCase();
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'salePrice': salePrice,
      'rating': rating,
      'imageUrl': imageUrl,
      'brand': brand,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'sellerId': sellerId,
      'shopId': shopId,
      'stock': stock,
      'soldCount': soldCount,
      'status': status,
    };
  }

  static String _readString(
    Map<dynamic, dynamic> json,
    List<String> keys, {
    String fallback = '',
  }) {
    return _readNullableString(json, keys) ?? fallback;
  }

  static String? _readNullableString(
    Map<dynamic, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return null;
  }

  static double _readDouble(Map<dynamic, dynamic> json, List<String> keys) {
    return _readNullableDouble(json, keys) ?? 0;
  }

  static double? _readNullableDouble(
    Map<dynamic, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value is num) {
        return value.toDouble();
      }
      if (value is String) {
        return double.tryParse(value);
      }
    }
    return null;
  }

  static int _readInt(Map<dynamic, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
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

  static String _readImageUrl(Map<dynamic, dynamic> json) {
    final directUrl = _readNullableString(json, [
      'thumbnailUrl',
      'imageUrl',
      'image',
    ]);
    if (directUrl != null) {
      return directUrl;
    }

    final imageUrls = json['imageUrls'];
    if (imageUrls is Map && imageUrls.isNotEmpty) {
      return imageUrls.values.first.toString();
    }
    if (imageUrls is List && imageUrls.isNotEmpty) {
      return imageUrls.first.toString();
    }

    return '';
  }
}
