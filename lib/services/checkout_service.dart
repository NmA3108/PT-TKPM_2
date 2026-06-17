import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import '../main.dart';
import '../models/checkout_models.dart';

class CheckoutException implements Exception {
  const CheckoutException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CheckoutService {
  CheckoutService({FirebaseDatabase? database})
      : _database = database ??
            FirebaseDatabase.instanceFor(
              app: Firebase.app(),
              databaseURL: realtimeDatabaseUrl,
            );

  final FirebaseDatabase _database;

  DatabaseReference get _rootRef => _database.ref();
  DatabaseReference get _productsRef => _database.ref('products');
  DatabaseReference get _cartsRef => _database.ref('carts');
  DatabaseReference get _ordersRef => _database.ref('orders');

  Stream<List<CartItemModel>> watchCartItems(String userId) {
    return _cartsRef.child(userId).child('items').onValue.map((event) {
      final value = event.snapshot.value;
      if (value is! Map<dynamic, dynamic>) {
        return <CartItemModel>[];
      }

      final items = <CartItemModel>[];
      for (final entry in value.entries) {
        final itemValue = entry.value;
        if (itemValue is Map<dynamic, dynamic>) {
          items.add(CartItemModel.fromMap(entry.key.toString(), itemValue));
        }
      }
      return items;
    });
  }

  Future<void> updateCartItemQuantity({
    required String userId,
    required CartItemModel item,
    required int quantity,
  }) async {
    if (quantity <= 0) {
      await removeCartItem(userId: userId, productId: item.productId);
      return;
    }

    final stock = await _readProductStock(item.productId);
    if (quantity > stock) {
      throw const CheckoutException('Số lượng yêu cầu vượt quá tồn kho.');
    }

    await _cartsRef
        .child(userId)
        .child('items')
        .child(item.productId)
        .update({
      'quantity': quantity,
      'subtotal': item.unitPrice * quantity,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
    await updateCartSummary(userId);
  }

  Future<void> removeCartItem({
    required String userId,
    required String productId,
  }) async {
    await _cartsRef.child(userId).child('items').child(productId).remove();
    await updateCartSummary(userId);
  }

  Future<void> updateCartSummary(String userId) async {
    final snapshot = await _cartsRef.child(userId).child('items').get();
    final value = snapshot.value;
    var totalItems = 0;
    var totalAmount = 0.0;

    if (value is Map<dynamic, dynamic>) {
      for (final itemValue in value.values) {
        if (itemValue is Map<dynamic, dynamic>) {
          final item = CartItemModel.fromMap('', itemValue);
          totalItems += item.quantity;
          totalAmount += item.subtotal;
        }
      }
    }

    await _cartsRef.child(userId).update({
      'totalItems': totalItems,
      'totalAmount': totalAmount,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<String> createOrderFromCart({
    required String userId,
    required CheckoutDraft draft,
  }) async {
    if (draft.items.isEmpty) {
      throw const CheckoutException('Giỏ hàng đang trống.');
    }

    for (final item in draft.items) {
      final stock = await _readProductStock(item.productId);
      if (item.quantity > stock) {
        throw CheckoutException('${item.productName} không đủ số lượng tồn kho.');
      }
    }

    if (draft.paymentMethod != 'cod') {
      await Future<void>.delayed(const Duration(seconds: 1));
    }

    final orderRef = _ordersRef.push();
    final orderId = orderRef.key;
    if (orderId == null) {
      throw const CheckoutException('Không thể tạo đơn hàng.');
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final updates = <String, Object?>{};
    final orderItems = <String, Object?>{};

    for (final item in draft.items) {
      orderItems[item.productId] = item.toOrderMap();
      final stock = await _readProductStock(item.productId);
      final nextStock = stock - item.quantity;
      updates['products/${item.productId}/stock'] = nextStock;
      updates['products/${item.productId}/stock_quantity'] = nextStock;
      updates['carts/$userId/items/${item.productId}'] = null;
    }

    updates['orders/$orderId'] = {
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
    updates['ordersByCustomer/$userId/$orderId'] = {
      'status': 'pending',
      'grandTotal': draft.grandTotal,
      'createdAt': now,
    };
    updates['carts/$userId/totalItems'] = 0;
    updates['carts/$userId/totalAmount'] = 0;
    updates['carts/$userId/updatedAt'] = now;

    await _rootRef.update(updates);
    return orderId;
  }

  Future<int> _readProductStock(String productId) async {
    final snapshot = await _productsRef.child(productId).get();
    final value = snapshot.value;
    if (value is! Map<dynamic, dynamic> || value['status'] != 'active') {
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
