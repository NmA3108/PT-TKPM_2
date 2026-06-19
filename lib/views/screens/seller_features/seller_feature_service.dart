import 'package:cloud_firestore/cloud_firestore.dart';

class SellerFeatureService {
  SellerFeatureService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _ordersRef {
    return _firestore.collection('orders');
  }

  CollectionReference<Map<String, dynamic>> get _sellerMessagesRef {
    return _firestore.collection('sellerMessages');
  }

  CollectionReference<Map<String, dynamic>> get _usersRef {
    return _firestore.collection('users');
  }

  CollectionReference<Map<String, dynamic>> _promotionsRef(String sellerId) {
    return _firestore.collection('sellerPromotions').doc(sellerId).collection('items');
  }

  Stream<List<SellerPromotionModel>> watchPromotions(String sellerId) {
    return _promotionsRef(sellerId).snapshots().map((snapshot) {
      final promotions = snapshot.docs
          .map((doc) => SellerPromotionModel.fromMap(doc.id, doc.data()))
          .toList();
      promotions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return promotions;
    });
  }

  Future<void> createPromotion({
    required String sellerId,
    required String code,
    required String title,
    required String discountType,
    required double discountValue,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _promotionsRef(sellerId).doc().set({
      'code': code.trim().toUpperCase(),
      'title': title.trim(),
      'discountType': discountType,
      'discountValue': discountValue,
      'isActive': true,
      'createdAt': now,
      'updatedAt': now,
    });
  }

  Future<void> togglePromotion({
    required String sellerId,
    required SellerPromotionModel promotion,
  }) async {
    await _promotionsRef(sellerId).doc(promotion.id).update({
      'isActive': !promotion.isActive,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Stream<List<SellerOrderModel>> watchSellerOrders(String sellerId) {
    return _ordersRef.snapshots().map((snapshot) {
      final orders = <SellerOrderModel>[];

      for (final doc in snapshot.docs) {
        final order = SellerOrderModel.fromMap(doc.id, doc.data());
        if (order.sellerIds.contains(sellerId)) {
          orders.add(order);
        }
      }

      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    });
  }

  Future<void> confirmSellerOrder(SellerOrderModel order) async {
    await updateSellerOrderStatus(order, 'confirmed');
  }

  Future<void> updateSellerOrderStatus(
    SellerOrderModel order,
    String newStatus,
  ) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final batch = _firestore.batch();

    batch.update(_ordersRef.doc(order.id), {
      'status': newStatus,
      'updatedAt': now,
    });
    batch.set(
      _firestore
          .collection('ordersByCustomer')
          .doc(order.customerId)
          .collection('orders')
          .doc(order.id),
      {
        'status': newStatus,
        'updatedAt': now,
      },
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  Stream<List<SellerCustomerConversationModel>> watchCustomerConversations(
    String sellerId,
  ) {
    return _sellerMessagesRef
        .doc(sellerId)
        .collection('conversations')
        .snapshots()
        .asyncMap((snapshot) async {
      final conversations = <SellerCustomerConversationModel>[];

      for (final doc in snapshot.docs) {
        final customerId = doc.id;
        Map<String, dynamic>? profileData;
        try {
          final profile = await _usersRef.doc(customerId).get();
          profileData = profile.data();
        } catch (_) {}
        conversations.add(
          SellerCustomerConversationModel.fromMap(
            customerId,
            doc.data(),
            displayName: _customerDisplayName(customerId, profileData),
          ),
        );
      }

      conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return conversations;
    });
  }

  String _customerDisplayName(
    String customerId,
    Map<dynamic, dynamic>? profile,
  ) {
    final fullName = profile?['fullName']?.toString().trim() ?? '';
    final generatedName = RegExp(r'^(Customer|Seller)(\d{3})$').firstMatch(
      fullName,
    );
    if (generatedName != null) {
      return 'Customer${generatedName.group(2)}';
    }
    if (fullName.isNotEmpty) {
      return fullName;
    }

    var hash = 0;
    for (final unit in customerId.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return 'Customer${(hash % 900 + 100)}';
  }

  Stream<List<SellerCustomerMessageModel>> watchCustomerMessages({
    required String sellerId,
    required String customerId,
  }) {
    return _sellerMessagesRef
        .doc(sellerId)
        .collection('conversations')
        .doc(customerId)
        .collection('items')
        .snapshots()
        .map((snapshot) {
      final messages = snapshot.docs
          .map((doc) => SellerCustomerMessageModel.fromMap(doc.id, doc.data()))
          .toList();

      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return messages;
    });
  }

  Future<void> sendCustomerMessage({
    required String sellerId,
    required String customerId,
    required String sellerName,
    required String text,
  }) async {
    final messageId = _sellerMessagesRef.doc().id;
    final now = DateTime.now().millisecondsSinceEpoch;
    final cleanText = text.trim();
    final sellerMessageRef = _sellerMessagesRef
        .doc(sellerId)
        .collection('conversations')
        .doc(customerId);
    final customerMessageRef = _firestore
        .collection('messages')
        .doc(customerId)
        .collection('conversations')
        .doc(sellerId);
    final messageData = {
      'senderId': sellerId,
      'senderType': 'seller',
      'text': cleanText,
      'createdAt': now,
    };
    final batch = _firestore.batch();

    batch.set(sellerMessageRef, {
      'customerId': customerId,
      'lastMessage': cleanText,
      'updatedAt': now,
    }, SetOptions(merge: true));
    batch.set(
      sellerMessageRef.collection('items').doc(messageId),
      messageData,
    );
    batch.set(customerMessageRef, {
      'sellerId': sellerId,
      'sellerName': sellerName,
      'lastMessage': cleanText,
      'updatedAt': now,
    }, SetOptions(merge: true));
    batch.set(
      customerMessageRef.collection('items').doc(messageId),
      messageData,
    );
    await batch.commit();
  }
}

class SellerOrderModel {
  const SellerOrderModel({
    required this.id,
    required this.customerId,
    required this.status,
    required this.grandTotal,
    required this.createdAt,
    required this.sellerIds,
    required this.firstProductName,
    required this.itemCount,
  });

  final String id;
  final String customerId;
  final String status;
  final double grandTotal;
  final int createdAt;
  final Set<String> sellerIds;
  final String firstProductName;
  final int itemCount;

  bool get canConfirm => status == 'pending';

  factory SellerOrderModel.fromMap(String id, Map<dynamic, dynamic> map) {
    final sellerIds = <String>{};
    var firstProductName = 'Đơn hàng';
    var itemCount = 0;

    final itemsValue = map['items'];

    if (itemsValue is Map<dynamic, dynamic>) {
      itemCount = itemsValue.length;

      for (final value in itemsValue.values) {
        if (value is Map<dynamic, dynamic>) {
          final sellerId = value['sellerId']?.toString() ?? '';

          if (sellerId.isNotEmpty) {
            sellerIds.add(sellerId);
          }

          firstProductName =
              value['productName']?.toString() ?? firstProductName;
        }
      }
    }

    return SellerOrderModel(
      id: id,
      customerId: map['customerId']?.toString() ?? '',
      status: map['status']?.toString() ?? 'pending',
      grandTotal: _readDouble(map['grandTotal']),
      createdAt: _readInt(map['createdAt']),
      sellerIds: sellerIds,
      firstProductName: firstProductName,
      itemCount: itemCount,
    );
  }

  String get statusLabel {
    switch (status) {
      case 'confirmed':
        return 'Đã xác nhận';
      case 'packed':
        return 'Đang đóng gói';
      case 'shipping':
        return 'Đang giao hàng';
      case 'delivered':
      case 'completed':
        return 'Đã giao';
      case 'cancelled':
        return 'Đã hủy';
      case 'pending':
      default:
        return 'Cho xác nhận';
    }
  }
}

class SellerPromotionModel {
  const SellerPromotionModel({
    required this.id,
    required this.code,
    required this.title,
    required this.discountType,
    required this.discountValue,
    required this.isActive,
    required this.updatedAt,
  });

  final String id;
  final String code;
  final String title;
  final String discountType;
  final double discountValue;
  final bool isActive;
  final int updatedAt;

  String get discountLabel {
    if (discountType == 'percent') {
      return '${discountValue.toStringAsFixed(0)}%';
    }
    return '${discountValue.toStringAsFixed(0)} VND';
  }

  factory SellerPromotionModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return SellerPromotionModel(
      id: id,
      code: map['code']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      discountType: map['discountType']?.toString() ?? 'percent',
      discountValue: _readDouble(map['discountValue']),
      isActive: map['isActive'] == true,
      updatedAt: _readInt(map['updatedAt']),
    );
  }
}

class SellerCustomerConversationModel {
  const SellerCustomerConversationModel({
    required this.customerId,
    required this.customerName,
    required this.lastMessage,
    required this.updatedAt,
  });

  final String customerId;
  final String customerName;
  final String lastMessage;
  final int updatedAt;

  factory SellerCustomerConversationModel.fromMap(
    String customerId,
    Map<dynamic, dynamic> map,
    {String? displayName}
  ) {
    final customerName = map['customerName']?.toString().trim() ?? '';

    return SellerCustomerConversationModel(
      customerId: customerId,
      customerName: displayName ?? (customerName.isEmpty
          ? 'Customer${_fallbackDigits(customerId)}'
          : customerName),
      lastMessage: map['lastMessage']?.toString() ?? '',
      updatedAt: _readInt(map['updatedAt']),
    );
  }
}

String _fallbackDigits(String value) {
  var hash = 0;
  for (final unit in value.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return (hash % 900 + 100).toString();
}

class SellerCustomerMessageModel {
  const SellerCustomerMessageModel({
    required this.id,
    required this.senderId,
    required this.senderType,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String senderId;
  final String senderType;
  final String text;
  final int createdAt;

  bool get isSeller => senderType == 'seller';

  factory SellerCustomerMessageModel.fromMap(
    String id,
    Map<dynamic, dynamic> map,
  ) {
    return SellerCustomerMessageModel(
      id: id,
      senderId: map['senderId']?.toString() ?? '',
      senderType: map['senderType']?.toString() ?? 'customer',
      text: map['text']?.toString() ?? '',
      createdAt: _readInt(map['createdAt']),
    );
  }
}

double _readDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

int _readInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
