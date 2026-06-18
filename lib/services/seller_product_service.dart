import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../main.dart';
import '../models/product_model.dart';

class SellerProductService {
  SellerProductService({
    FirebaseDatabase? database,
    FirebaseStorage? storage,
    FirebaseAuth? auth,
  })  : _database = database ??
            FirebaseDatabase.instanceFor(
              app: Firebase.app(),
              databaseURL: realtimeDatabaseUrl,
            ),
        _storage = storage ?? FirebaseStorage.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseDatabase _database;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  DatabaseReference get _productsRef => _database.ref('products');
  DatabaseReference get _productsBySellerRef {
    return _database.ref('productsBySeller');
  }

  Stream<List<ProductModel>> watchSellerProducts(String sellerId) {
    return _productsRef
        .orderByChild('sellerId')
        .equalTo(sellerId)
        .onValue
        .map((event) {
      final value = event.snapshot.value;
      if (value is! Map<dynamic, dynamic>) {
        return <ProductModel>[];
      }

      final products = <ProductModel>[];
      for (final entry in value.entries) {
        final productValue = entry.value;
        if (productValue is Map<dynamic, dynamic>) {
          products.add(
            ProductModel.fromFirebase(entry.key.toString(), productValue),
          );
        }
      }

      products.sort((a, b) => b.soldCount.compareTo(a.soldCount));
      return products;
    });
  }

  Future<String> uploadProductImage({
    required String sellerId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    await _ensureFirebaseAuthSession();

    final extension = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : 'jpg';
    final safeExtension = extension == 'png' || extension == 'webp'
        ? extension
        : 'jpeg';
    final now = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage.ref(
      'seller_products/$sellerId/product_$now.$safeExtension',
    );

    try {
      await ref.putData(
        bytes,
        SettableMetadata(
          contentType: 'image/$safeExtension',
          customMetadata: {
            'sellerId': sellerId,
          },
        ),
      );
      return ref.getDownloadURL();
    } on FirebaseException catch (error) {
      throw Exception(_storageErrorMessage(error));
    }
  }

  Future<void> _ensureFirebaseAuthSession() async {
    if (_auth.currentUser != null) {
      return;
    }

    try {
      await _auth.signInAnonymously();
    } on FirebaseAuthException catch (error) {
      if (error.code == 'operation-not-allowed') {
        throw Exception(
          'Firebase Auth chưa bật Anonymous sign-in. Hãy bật Authentication > Sign-in method > Anonymous để upload ảnh.',
        );
      }
      throw Exception('Không thể tạo phiên upload ảnh: ${error.message}');
    }
  }

  String _storageErrorMessage(FirebaseException error) {
    if (error.code == 'unauthorized') {
      return 'Firebase Storage từ chối upload. Hãy kiểm tra Storage Rules cho phép user đã đăng nhập ghi vào seller_products/.';
    }
    if (error.code == 'quota-exceeded') {
      return 'Firebase Storage đã vượt hạn mức.';
    }
    if (error.code == 'canceled') {
      return 'Upload ảnh đã bị hủy.';
    }
    return error.message ?? 'Upload ảnh thất bại.';
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
    required String thumbnailUrl,
  }) async {
    final productRef = _productsRef.push();
    final productId = productRef.key;
    if (productId == null) {
      throw Exception('Không thể tạo mã sản phẩm.');
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final data = {
      'sellerId': sellerId,
      'shopId': shopId,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'category': categoryName,
      'name': name.trim(),
      'description': description.trim(),
      'price': price,
      'salePrice': price,
      'stock': stock,
      'stock_quantity': stock,
      'thumbnailUrl': thumbnailUrl.trim(),
      'imageUrls': {
        'image_001': thumbnailUrl.trim(),
      },
      'colors': ['Mặc định'],
      'sizes': ['Free size'],
      'ratingAverage': 0,
      'soldCount': 0,
      'status': 'active',
      'createdAt': now,
      'updatedAt': now,
    };

    await _database.ref().update({
      'products/$productId': data,
      'productsBySeller/$sellerId/$productId': {
        'categoryId': categoryId,
        'price': price,
        'stock': stock,
        'status': 'active',
        'createdAt': now,
      },
    });
  }

  Future<void> updateProduct({
    required ProductModel product,
    required String name,
    required double price,
    required int stock,
    required String categoryName,
    required String thumbnailUrl,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final updates = {
      'name': name.trim(),
      'price': price,
      'salePrice': price,
      'stock': stock,
      'stock_quantity': stock,
      'categoryName': categoryName.trim(),
      'category': categoryName.trim(),
      'thumbnailUrl': thumbnailUrl.trim(),
      'imageUrls/image_001': thumbnailUrl.trim(),
      'updatedAt': now,
    };

    await _productsRef.child(product.id).update(updates);

    final sellerId = product.sellerId;
    if (sellerId != null && sellerId.isNotEmpty) {
      await _productsBySellerRef.child(sellerId).child(product.id).update({
        'price': price,
        'stock': stock,
        'updatedAt': now,
      });
    }
  }

  Future<void> hideProduct(ProductModel product) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _productsRef.child(product.id).update({
      'status': 'hidden',
      'updatedAt': now,
    });

    final sellerId = product.sellerId;
    if (sellerId != null && sellerId.isNotEmpty) {
      await _productsBySellerRef.child(sellerId).child(product.id).update({
        'status': 'hidden',
        'updatedAt': now,
      });
    }
  }
}
