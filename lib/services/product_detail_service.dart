import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/product_detail_model.dart';

const realtimeDatabaseUrl =
    'https://tmdt-e5958-default-rtdb.asia-southeast1.firebasedatabase.app/';

class ProductStockException implements Exception {
  const ProductStockException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ProductDetailService {
  ProductDetailService({FirebaseDatabase? database})
      : _database = database ??
            FirebaseDatabase.instanceFor(
              app: Firebase.app(),
              databaseURL: realtimeDatabaseUrl,
            );

  final FirebaseDatabase _database;

  DatabaseReference get _productsRef => _database.ref('products');
  DatabaseReference get _cartsRef => _database.ref('carts');
  DatabaseReference get _viewLogsRef {
    return _database.ref('behavior_logs/view_logs');
  }

  Stream<ProductDetailModel?> watchProduct(String productId) {
    return _productsRef.child(productId).onValue.map((event) {
      final value = event.snapshot.value;
      if (value is! Map<dynamic, dynamic>) {
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
    return _productsRef.onValue.map((event) {
      final value = event.snapshot.value;
      if (value is! Map<dynamic, dynamic>) {
        return <ProductDetailModel>[];
      }

      final products = <ProductDetailModel>[];
      for (final entry in value.entries) {
        final productValue = entry.value;
        if (entry.key.toString() == currentProductId) {
          continue;
        }

        if (productValue is! Map<dynamic, dynamic>) {
          continue;
        }

        final product = ProductDetailModel.fromFirebase(
          entry.key.toString(),
          productValue,
        );
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

  Stream<int> watchCartItemCount(String userId) {
    return _cartsRef.child(userId).child('items').onValue.map((event) {
      final value = event.snapshot.value;
      if (value is! Map<dynamic, dynamic>) {
        return 0;
      }

      var total = 0;
      for (final item in value.values) {
        if (item is Map<dynamic, dynamic>) {
          final quantity = item['quantity'];
          if (quantity is int) {
            total += quantity;
          } else if (quantity is num) {
            total += quantity.toInt();
          }
        }
      }
      return total;
    });
  }

  Future<void> logProductView({
    required String userId,
    required String productId,
  }) async {
    await _viewLogsRef.push().set({
      'userId': userId,
      'productId': productId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> addToCart({
    required String userId,
    required ProductDetailModel product,
    required int quantity,
    required String selectedColor,
    required String selectedSize,
  }) async {
    final itemRef = _cartsRef.child(userId).child('items').child(product.id);
    final snapshot = await itemRef.get();
    var currentQuantity = 0;

    if (snapshot.value is Map<dynamic, dynamic>) {
      final item = snapshot.value as Map<dynamic, dynamic>;
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
        'Số lượng trong giỏ hàng vượt quá tồn kho hiện có.',
      );
    }

    await itemRef.update(
      product.toCartItemMap(
        quantity: nextQuantity,
        selectedColor: selectedColor,
        selectedSize: selectedSize,
      )..putIfAbsent(
          'addedAt',
          () => DateTime.now().millisecondsSinceEpoch,
        ),
    );

    await _updateCartSummary(userId);
  }

  Future<void> _updateCartSummary(String userId) async {
    final itemsSnapshot = await _cartsRef.child(userId).child('items').get();
    final value = itemsSnapshot.value;
    var totalItems = 0;
    var totalAmount = 0.0;

    if (value is Map<dynamic, dynamic>) {
      for (final item in value.values) {
        if (item is Map<dynamic, dynamic>) {
          final quantity = item['quantity'];
          final unitPrice = item['unitPrice'];
          final itemQuantity = quantity is num ? quantity.toInt() : 0;
          final itemPrice = unitPrice is num ? unitPrice.toDouble() : 0;

          totalItems += itemQuantity;
          totalAmount += itemQuantity * itemPrice;
        }
      }
    }

    await _cartsRef.child(userId).update({
      'totalItems': totalItems,
      'totalAmount': totalAmount,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }
}
