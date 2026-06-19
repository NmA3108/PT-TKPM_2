import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import '../models/product_model.dart';

class SellerProductService {
  SellerProductService({
    FirebaseFirestore? firestore,
    http.Client? httpClient,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _httpClient = httpClient ?? http.Client();

  final FirebaseFirestore _firestore;
  final http.Client _httpClient;
  static const String _cloudinaryCloudName = 'dmiw7nywy';
  static const String _cloudinaryUploadPreset = 'imgs_vid';
  static const int _maxProductImageBytes = 4 * 1024 * 1024;

  CollectionReference<Map<String, dynamic>> get _productsRef {
    return _firestore.collection('products');
  }

  CollectionReference<Map<String, dynamic>> get _productsBySellerRef {
    return _firestore.collection('productsBySeller');
  }

  CollectionReference<Map<String, dynamic>> _taxonomyRef(String sellerId) {
    return _firestore
        .collection('sellerProductTaxonomies')
        .doc(sellerId)
        .collection('items');
  }

  Stream<List<SellerProductTaxonomy>> watchSellerTaxonomies(String sellerId) {
    return _taxonomyRef(sellerId).snapshots().map((snapshot) {
      final items = snapshot.docs
          .map((doc) => SellerProductTaxonomy.fromMap(doc.id, doc.data()))
          .toList();
      items.sort((a, b) {
        final typeCompare = a.type.compareTo(b.type);
        if (typeCompare != 0) {
          return typeCompare;
        }
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      return items;
    });
  }

  Future<SellerProductTaxonomy> createTaxonomy({
    required String sellerId,
    required String name,
    required String type,
  }) async {
    final normalizedName = name.trim();
    final normalizedType = SellerProductTaxonomy.normalizeType(type);
    if (normalizedName.isEmpty) {
      throw Exception('Ten danh muc hoac phan loai khong duoc de trong.');
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final ref = _taxonomyRef(sellerId).doc();
    await ref.set({
      'name': normalizedName,
      'type': normalizedType,
      'createdAt': now,
      'updatedAt': now,
    });

    return SellerProductTaxonomy(
      id: ref.id,
      name: normalizedName,
      type: normalizedType,
    );
  }

  Stream<List<ProductModel>> watchSellerProducts(String sellerId) {
    return _productsRef
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snapshot) {
      final products = snapshot.docs
          .map((doc) => ProductModel.fromFirebase(doc.id, doc.data()))
          .toList();

      products.sort((a, b) => b.soldCount.compareTo(a.soldCount));
      return products;
    });
  }

  Future<String> uploadProductImage({
    required String sellerId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (bytes.lengthInBytes > _maxProductImageBytes) {
      throw Exception(
        'Anh san pham qua lon. Vui long chon anh nho hon 4MB.',
      );
    }

    final extension = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : 'jpg';
    final safeExtension = switch (extension) {
      'png' => 'png',
      'webp' => 'webp',
      'jpg' || 'jpeg' => 'jpeg',
      _ => 'jpeg',
    };
    final now = DateTime.now().millisecondsSinceEpoch;
    final uploadUri = Uri.https(
      'api.cloudinary.com',
      '/v1_1/$_cloudinaryCloudName/image/upload',
    );

    try {
      final request = http.MultipartRequest('POST', uploadUri)
        ..fields['upload_preset'] = _cloudinaryUploadPreset
        ..fields['folder'] = 'seller_products/$sellerId'
        ..fields['public_id'] = 'product_$now'
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: 'product_$now.$safeExtension',
          ),
        );

      final streamedResponse = await _httpClient
          .send(request)
          .timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);
      final body = jsonDecode(response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(_cloudinaryErrorMessage(body));
      }

      if (body is Map<String, dynamic>) {
        final secureUrl = body['secure_url']?.toString() ?? '';
        if (secureUrl.startsWith('https://')) {
          return secureUrl;
        }
      }

      throw Exception('Cloudinary khong tra ve URL anh hop le.');
    } on TimeoutException {
      throw Exception('Ket noi Cloudinary qua thoi gian cho. Vui long thu lai.');
    } on FormatException {
      throw Exception('Cloudinary tra ve du lieu khong hop le.');
    } on Exception {
      rethrow;
    }
  }

  String _cloudinaryErrorMessage(Object? body) {
    if (body is Map<String, dynamic>) {
      final error = body['error'];
      if (error is Map<String, dynamic>) {
        final message = error['message']?.toString();
        if (message != null && message.isNotEmpty) {
          return 'Cloudinary upload that bai: $message';
        }
      }
    }
    return 'Cloudinary upload that bai.';
  }

  Future<void> createProduct({
    required String sellerId,
    required String shopId,
    required String name,
    required String description,
    required double price,
    required int stock,
    required String categoryId,
    required String categoryName,
    String? classificationId,
    String? classificationName,
    List<String> classifications = const [],
    List<String> sizes = const [],
    required String thumbnailUrl,
    List<String> imageUrls = const [],
  }) async {
    _validateStorageImageUrl(thumbnailUrl);
    final normalizedImages = _normalizeImageUrls(thumbnailUrl, imageUrls);
    final normalizedClassifications = _normalizeStrings([
      ...classifications,
      if (classificationName != null) classificationName,
    ]);
    final normalizedSizes = _normalizeStrings(sizes);

    final productRef = _productsRef.doc();
    final productId = productRef.id;
    final now = DateTime.now().millisecondsSinceEpoch;
    final data = {
      'sellerId': sellerId,
      'shopId': shopId,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'category': categoryName,
      'classificationId': classificationId?.trim() ?? '',
      'classificationName': classificationName?.trim() ?? '',
      'classifications': normalizedClassifications,
      'name': name.trim(),
      'description': description.trim(),
      'price': price,
      'salePrice': price,
      'stock': stock,
      'stock_quantity': stock,
      'thumbnailUrl': thumbnailUrl.trim(),
      'imageUrls': _imageMap(normalizedImages),
      'colors': ['Mac dinh'],
      'sizes': normalizedSizes,
      'ratingAverage': 0,
      'soldCount': 0,
      'status': 'active',
      'createdAt': now,
      'updatedAt': now,
    };

    final batch = _firestore.batch();
    batch.set(productRef, data);
    batch.set(
      _productsBySellerRef.doc(sellerId).collection('products').doc(productId),
      {
        'categoryId': categoryId,
        'categoryName': categoryName,
        'classificationId': classificationId?.trim() ?? '',
        'classificationName': classificationName?.trim() ?? '',
        'classifications': normalizedClassifications,
        'price': price,
        'stock': stock,
        'status': 'active',
        'createdAt': now,
      },
    );
    await batch.commit();
  }

  Future<void> updateProduct({
    required ProductModel product,
    required String name,
    required double price,
    required int stock,
    required String categoryId,
    required String categoryName,
    String? classificationId,
    String? classificationName,
    List<String> classifications = const [],
    List<String> sizes = const [],
    required String thumbnailUrl,
    List<String> imageUrls = const [],
  }) async {
    _validateStorageImageUrl(thumbnailUrl);
    final normalizedImages = _normalizeImageUrls(thumbnailUrl, imageUrls);
    final normalizedClassifications = _normalizeStrings([
      ...classifications,
      if (classificationName != null) classificationName,
    ]);
    final normalizedSizes = _normalizeStrings(sizes);

    final now = DateTime.now().millisecondsSinceEpoch;
    final updates = {
      'name': name.trim(),
      'price': price,
      'salePrice': price,
      'stock': stock,
      'stock_quantity': stock,
      'categoryId': categoryId.trim(),
      'categoryName': categoryName.trim(),
      'category': categoryName.trim(),
      'classificationId': classificationId?.trim() ?? '',
      'classificationName': classificationName?.trim() ?? '',
      'classifications': normalizedClassifications,
      'sizes': normalizedSizes,
      'thumbnailUrl': thumbnailUrl.trim(),
      'imageUrls': _imageMap(normalizedImages),
      'updatedAt': now,
    };

    final batch = _firestore.batch();
    batch.update(_productsRef.doc(product.id), updates);

    final sellerId = product.sellerId;
    if (sellerId != null && sellerId.isNotEmpty) {
      batch.update(
        _productsBySellerRef.doc(sellerId).collection('products').doc(product.id),
        {
          'categoryId': categoryId.trim(),
          'categoryName': categoryName.trim(),
          'classificationId': classificationId?.trim() ?? '',
          'classificationName': classificationName?.trim() ?? '',
          'classifications': normalizedClassifications,
          'price': price,
          'stock': stock,
          'updatedAt': now,
        },
      );
    }
    await batch.commit();
  }

  Future<void> hideProduct(ProductModel product) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final batch = _firestore.batch();
    batch.update(_productsRef.doc(product.id), {
      'status': 'hidden',
      'updatedAt': now,
    });

    final sellerId = product.sellerId;
    if (sellerId != null && sellerId.isNotEmpty) {
      batch.update(
        _productsBySellerRef.doc(sellerId).collection('products').doc(product.id),
        {
          'status': 'hidden',
          'updatedAt': now,
        },
      );
    }
    await batch.commit();
  }

  void _validateStorageImageUrl(String imageUrl) {
    final value = imageUrl.trim();
    if (value.startsWith('data:image')) {
      throw Exception('Anh san pham phai duoc upload len Cloudinary.');
    }
    if (!value.startsWith('http://') && !value.startsWith('https://')) {
      throw Exception('Duong dan anh san pham khong hop le.');
    }
  }

  List<String> _normalizeImageUrls(String thumbnailUrl, List<String> imageUrls) {
    final urls = <String>[thumbnailUrl.trim(), ...imageUrls.map((url) => url.trim())]
        .where((url) => url.isNotEmpty)
        .toSet()
        .toList();
    for (final url in urls) {
      _validateStorageImageUrl(url);
    }
    return urls;
  }

  Map<String, String> _imageMap(List<String> urls) {
    final map = <String, String>{};
    for (var index = 0; index < urls.length; index++) {
      map['image_${(index + 1).toString().padLeft(3, '0')}'] = urls[index];
    }
    return map;
  }

  List<String> _normalizeStrings(List<String> values) {
    return values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
  }
}

class SellerProductTaxonomy {
  const SellerProductTaxonomy({
    required this.id,
    required this.name,
    required this.type,
  });

  final String id;
  final String name;
  final String type;

  bool get isCategory => type == 'category';
  bool get isClassification => type == 'classification';

  static String normalizeType(String value) {
    return value.trim().toLowerCase() == 'classification'
        ? 'classification'
        : 'category';
  }

  factory SellerProductTaxonomy.fromMap(
    String id,
    Map<dynamic, dynamic> map,
  ) {
    return SellerProductTaxonomy(
      id: id,
      name: map['name']?.toString() ?? '',
      type: normalizeType(map['type']?.toString() ?? ''),
    );
  }
}
