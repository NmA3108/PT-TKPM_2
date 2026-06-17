import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/product_model.dart';

const realtimeDatabaseUrl =
    'https://tmdt-e5958-default-rtdb.asia-southeast1.firebasedatabase.app/';

class ProductService {
  ProductService({FirebaseDatabase? database})
    : _database =
          database ??
          FirebaseDatabase.instanceFor(
            app: Firebase.app(),
            databaseURL: realtimeDatabaseUrl,
          );

  final FirebaseDatabase _database;

  DatabaseReference get _productsRef => _database.ref('products');

  Stream<List<ProductModel>> watchProducts() {
    return _productsRef.onValue.map((event) {
      final value = event.snapshot.value;
      if (value is! Map<dynamic, dynamic>) {
        return <ProductModel>[];
      }

      final products = <ProductModel>[];
      for (final entry in value.entries) {
        final productValue = entry.value;
        if (productValue is Map<dynamic, dynamic>) {
          final product = ProductModel.fromFirebase(
            entry.key.toString(),
            productValue,
          );
          if (product.status == 'active') {
            products.add(product);
          }
        }
      }

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
}
