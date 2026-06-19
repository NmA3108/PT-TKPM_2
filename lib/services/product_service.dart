import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product_model.dart';

class ProductService {
  ProductService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _productsRef {
    return _firestore.collection('products');
  }

  CollectionReference<Map<String, dynamic>> _searchHistoryRef(String userId) {
    return _firestore.collection('searchHistories').doc(userId).collection('items');
  }

  Stream<List<ProductModel>> watchProducts() {
    return _productsRef.snapshots().map((snapshot) {
      final products = snapshot.docs
          .map((doc) => ProductModel.fromFirebase(doc.id, doc.data()))
          .where((product) => product.status == 'active')
          .toList();

      products.sort((a, b) => b.soldCount.compareTo(a.soldCount));
      return products;
    });
  }

  Stream<List<ProductModel>> searchProducts(String keyword) {
    return watchProducts().map(
      (products) =>
          products.where((product) => product.matchesKeyword(keyword)).toList(),
    );
  }

  Stream<List<ProductModel>> filterProducts({
    double? minPrice,
    double? maxPrice,
    String? brand,
  }) {
    return watchProducts().map(
      (products) => products.where((product) {
        return product.matchesPriceRange(minPrice, maxPrice) &&
            product.matchesBrand(brand);
      }).toList(),
    );
  }

  Stream<List<ProductModel>> watchFilteredProducts({
    String keyword = '',
    double? minPrice,
    double? maxPrice,
    String? brand,
  }) {
    return watchProducts().map(
      (products) => products.where((product) {
        return product.matchesKeyword(keyword) &&
            product.matchesPriceRange(minPrice, maxPrice) &&
            product.matchesBrand(brand);
      }).toList(),
    );
  }

  Stream<List<String>> watchSearchHistory(String userId) {
    return _searchHistoryRef(userId).snapshots().map((snapshot) {
      final docs = [...snapshot.docs];
      docs.sort((a, b) {
        final aTime = _readInt(a.data()['updatedAt']);
        final bTime = _readInt(b.data()['updatedAt']);
        return bTime.compareTo(aTime);
      });
      final items = docs
          .map((doc) => doc.data()['keyword']?.toString().trim() ?? '')
          .where((keyword) => keyword.isNotEmpty)
          .toList();
      return items.take(8).toList();
    });
  }

  Future<void> saveSearchKeyword({
    required String userId,
    required String keyword,
  }) async {
    final cleanKeyword = keyword.trim();
    if (cleanKeyword.isEmpty) {
      return;
    }
    await _searchHistoryRef(userId).doc(cleanKeyword.toLowerCase()).set({
      'keyword': cleanKeyword,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }
}

int _readInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
