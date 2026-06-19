import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/checkout_models.dart';

class CheckoutException implements Exception {
  const CheckoutException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CheckoutService {
  CheckoutService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _productsRef {
    return _firestore.collection('products');
  }

  CollectionReference<Map<String, dynamic>> get _cartsRef {
    return _firestore.collection('carts');
  }

  CollectionReference<Map<String, dynamic>> get _ordersRef {
    return _firestore.collection('orders');
  }

  CollectionReference<Map<String, dynamic>> _cartItemsRef(String userId) {
    return _cartsRef.doc(userId).collection('items');
  }

  Stream<List<CartItemModel>> watchCartItems(String userId) {
    return _cartItemsRef(userId).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => CartItemModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<void> updateCartItemQuantity({
    required String userId,
    required CartItemModel item,
    required int quantity,
  }) async {
    if (quantity <= 0) {
      await removeCartItem(userId: userId, productId: item.cartItemId);
      return;
    }

    final stock = await _readProductStock(item.productId);
    if (quantity > stock) {
      throw const CheckoutException('Số lượng yêu cầu vượt quá tồn kho.');
    }

    await _cartItemsRef(userId).doc(item.cartItemId).set(
      {
        'quantity': quantity,
        'subtotal': item.unitPrice * quantity,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      SetOptions(merge: true),
    );
    await updateCartSummary(userId);
  }

  Future<void> removeCartItem({
    required String userId,
    required String productId,
  }) async {
    await _cartItemsRef(userId).doc(productId).delete();
    await updateCartSummary(userId);
  }

  Future<void> updateCartSummary(String userId) async {
    final snapshot = await _cartItemsRef(userId).get();
    var totalItems = 0;
    var totalAmount = 0.0;

    for (final doc in snapshot.docs) {
      final item = CartItemModel.fromMap(doc.id, doc.data());
      totalItems += item.quantity;
      totalAmount += item.subtotal;
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

  Future<String> createOrderFromCart({
    required String userId,
    required CheckoutDraft draft,
  }) async {
    if (draft.items.isEmpty) {
      throw const CheckoutException('Giỏ hàng đang trống.');
    }

    final quantitiesByProduct = <String, int>{};
    final namesByProduct = <String, String>{};
    for (final item in draft.items) {
      quantitiesByProduct[item.productId] =
          (quantitiesByProduct[item.productId] ?? 0) + item.quantity;
      namesByProduct[item.productId] = item.productName;
    }

    final nextStocks = <String, int>{};
    for (final entry in quantitiesByProduct.entries) {
      final stock = await _readProductStock(entry.key);
      if (entry.value > stock) {
        throw CheckoutException(
          '${namesByProduct[entry.key] ?? 'Sản phẩm'} không đủ số lượng tồn kho.',
        );
      }
      nextStocks[entry.key] = stock - entry.value;
    }

    if (draft.paymentMethod != 'cod') {
      await Future<void>.delayed(const Duration(seconds: 1));
    }

    final orderRef = _ordersRef.doc();
    final orderId = orderRef.id;
    final now = DateTime.now().millisecondsSinceEpoch;
    final orderItems = <String, Object?>{};
    final batch = _firestore.batch();

    for (final item in draft.items) {
      orderItems[item.cartItemId] = item.toOrderMap();
      batch.delete(_cartItemsRef(userId).doc(item.cartItemId));
    }

    for (final entry in nextStocks.entries) {
      batch.update(_productsRef.doc(entry.key), {
        'stock': entry.value,
        'stock_quantity': entry.value,
      });
    }

    final orderData = {
      'customerId': userId,
      'status': 'pending',
      'paymentStatus': draft.paymentMethod == 'cod' ? 'unpaid' : 'paid',
      'paymentMethod': draft.paymentMethod,
      'shippingAddress': {
        'addressId': draft.addressId,
        'receiverName': draft.receiverName,
        'phone': draft.receiverPhone,
        'detailAddress': draft.addressDetail,
      },
      'items': orderItems,
      'subtotal': draft.subtotal,
      'shippingFee': draft.shippingFee,
      'discountTotal': draft.discountTotal,
      'grandTotal': draft.grandTotal,
      'voucherCode': draft.voucherCode,
      'createdAt': now,
      'updatedAt': now,
    };

    batch.set(orderRef, orderData);
    batch.set(
      _firestore
          .collection('ordersByCustomer')
          .doc(userId)
          .collection('orders')
          .doc(orderId),
      {
        'status': 'pending',
        'grandTotal': draft.grandTotal,
        'createdAt': now,
      },
    );
    batch.set(
      _cartsRef.doc(userId),
      {
        'totalItems': 0,
        'totalAmount': 0,
        'updatedAt': now,
      },
      SetOptions(merge: true),
    );

    await batch.commit();
    return orderId;
  }

  Future<int> _readProductStock(String productId) async {
    final snapshot = await _productsRef.doc(productId).get();
    final value = snapshot.data();
    if (value == null || value['status'] != 'active') {
      throw const CheckoutException('Sản phẩm không còn tồn tại.');
    }

    final stockValue = value['stock_quantity'] ?? value['stock'];
    if (stockValue is int) {
      return stockValue;
    }
    if (stockValue is num) {
      return stockValue.toInt();
    }
    if (stockValue is String) {
      return int.tryParse(stockValue) ?? 0;
    }
    return 0;
  }
}
