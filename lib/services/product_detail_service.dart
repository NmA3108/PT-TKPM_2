import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product_detail_model.dart';

class ProductStockException implements Exception {
  const ProductStockException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ProductDetailService {
  ProductDetailService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _productsRef {
    return _firestore.collection('products');
  }

  CollectionReference<Map<String, dynamic>> get _cartsRef {
    return _firestore.collection('carts');
  }

  CollectionReference<Map<String, dynamic>> get _viewLogsRef {
    return _firestore.collection('behavior_logs').doc('view_logs').collection('items');
  }

  CollectionReference<Map<String, dynamic>> _sellerTaxonomyRef(String sellerId) {
    return _firestore
        .collection('sellerProductTaxonomies')
        .doc(sellerId)
        .collection('items');
  }

  CollectionReference<Map<String, dynamic>> _cartItemsRef(String userId) {
    return _cartsRef.doc(userId).collection('items');
  }

  Stream<ProductDetailModel?> watchProduct(String productId) {
    return _productsRef.doc(productId).snapshots().map((snapshot) {
      final value = snapshot.data();
      if (value == null) {
        return null;
      }

      final product = ProductDetailModel.fromFirebase(productId, value);
      if (product.status != 'active') {
        return null;
      }

      return product;
    });
  }

  Stream<List<ProductDetailModel>> watchSimilarProducts({
    required String currentProductId,
    required String categoryId,
    required String category,
  }) {
    return _productsRef.snapshots().map((snapshot) {
      final products = <ProductDetailModel>[];

      for (final doc in snapshot.docs) {
        if (doc.id == currentProductId) {
          continue;
        }

        final product = ProductDetailModel.fromFirebase(doc.id, doc.data());
        final sameCategoryId = categoryId.isNotEmpty &&
            product.categoryId.isNotEmpty &&
            product.categoryId == categoryId;
        final sameCategoryName = category.isNotEmpty &&
            product.category.toLowerCase() == category.toLowerCase();

        if (product.status == 'active' && (sameCategoryId || sameCategoryName)) {
          products.add(product);
        }
      }

      return products.take(10).toList();
    });
  }

  Stream<List<ProductDetailModel>> watchShopProducts(String sellerId) {
    return _productsRef
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snapshot) {
      final products = snapshot.docs
          .map((doc) => ProductDetailModel.fromFirebase(doc.id, doc.data()))
          .where((product) => product.status == 'active')
          .toList();
      products.sort((a, b) => b.stockQuantity.compareTo(a.stockQuantity));
      return products;
    });
  }

  Stream<List<ShopCategoryModel>> watchShopCategories(String sellerId) {
    return _sellerTaxonomyRef(sellerId).snapshots().map((snapshot) {
      final categories = <ShopCategoryModel>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final type = data['type']?.toString().trim().toLowerCase() ?? '';
        final name = data['name']?.toString().trim() ?? '';
        if (type == 'category' && name.isNotEmpty) {
          categories.add(ShopCategoryModel(id: doc.id, name: name));
        }
      }
      categories.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return categories;
    });
  }

  Stream<int> watchCartItemCount(String userId) {
    return _cartItemsRef(userId).snapshots().map((snapshot) {
      var total = 0;
      for (final doc in snapshot.docs) {
        final quantity = doc.data()['quantity'];
        if (quantity is int) {
          total += quantity;
        } else if (quantity is num) {
          total += quantity.toInt();
        }
      }
      return total;
    });
  }

  Future<void> logProductView({
    required String userId,
    required String productId,
  }) async {
    try {
      await _viewLogsRef.add({
        'userId': userId,
        'productId': productId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (_) {}
  }

  Future<void> addToCart({
    required String userId,
    required ProductDetailModel product,
    required int quantity,
    required String selectedColor,
    required String selectedClassification,
    required String selectedSize,
  }) async {
    final itemRef = _cartItemsRef(userId).doc(
      _cartItemId(
        productId: product.id,
        selectedColor: selectedColor,
        selectedClassification: selectedClassification,
        selectedSize: selectedSize,
      ),
    );
    final snapshot = await itemRef.get();
    var currentQuantity = 0;

    final item = snapshot.data();
    if (item != null) {
      final quantityValue = item['quantity'];
      if (quantityValue is int) {
        currentQuantity = quantityValue;
      } else if (quantityValue is num) {
        currentQuantity = quantityValue.toInt();
      }
    }

    final nextQuantity = currentQuantity + quantity;
    if (nextQuantity > product.stockQuantity) {
      throw const ProductStockException(
        'So luong trong gio hang vuot qua ton kho hien co.',
      );
    }

    final data = product.toCartItemMap(
      quantity: nextQuantity,
      selectedColor: selectedColor,
      selectedClassification: selectedClassification,
      selectedSize: selectedSize,
    );
    data.putIfAbsent('addedAt', () => DateTime.now().millisecondsSinceEpoch);
    await itemRef.set(data, SetOptions(merge: true));

    await _updateCartSummary(userId);
  }

  String _cartItemId({
    required String productId,
    required String selectedColor,
    required String selectedClassification,
    required String selectedSize,
  }) {
    final optionKey = [
      selectedClassification,
      selectedColor,
      selectedSize,
    ].map((value) => value.trim()).where((value) => value.isNotEmpty).join('_');
    if (optionKey.isEmpty) {
      return productId;
    }
    final safeOptionKey = optionKey.replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
    return '${productId}_$safeOptionKey';
  }

  Future<void> _updateCartSummary(String userId) async {
    final itemsSnapshot = await _cartItemsRef(userId).get();
    var totalItems = 0;
    var totalAmount = 0.0;

    for (final doc in itemsSnapshot.docs) {
      final item = doc.data();
      final quantity = item['quantity'];
      final unitPrice = item['unitPrice'];
      final itemQuantity = quantity is num ? quantity.toInt() : 0;
      final itemPrice = unitPrice is num ? unitPrice.toDouble() : 0;

      totalItems += itemQuantity;
      totalAmount += itemQuantity * itemPrice;
    }

    await _cartsRef.doc(userId).set(
      {
        'totalItems': totalItems,
        'totalAmount': totalAmount,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      SetOptions(merge: true),
    );
  }
}

class ShopCategoryModel {
  const ShopCategoryModel({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;
}
