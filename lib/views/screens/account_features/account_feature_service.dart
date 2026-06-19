import 'package:cloud_firestore/cloud_firestore.dart';

class AccountFeatureService {
  AccountFeatureService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _ordersRef {
    return _firestore.collection('orders');
  }

  CollectionReference<Map<String, dynamic>> get _sellerApplicationsRef {
    return _firestore.collection('sellerApplications');
  }

  CollectionReference<Map<String, dynamic>> get _messagesRef {
    return _firestore.collection('messages');
  }

  Stream<List<CustomerOrderModel>> watchCustomerOrders(String userId) {
    return _ordersRef
        .where('customerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final orders = snapshot.docs
          .map((doc) => CustomerOrderModel.fromMap(doc.id, doc.data()))
          .toList();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    });
  }

  Future<void> submitSellerApplication({
    required String userId,
    required String fullName,
    required String phone,
    required String shopName,
    required String address,
    required String description,
  }) async {
    final applicationRef = _sellerApplicationsRef.doc();
    final applicationId = applicationRef.id;
    final now = DateTime.now().millisecondsSinceEpoch;
    final batch = _firestore.batch();

    batch.set(applicationRef, {
      'applicationId': applicationId,
      'userId': userId,
      'fullName': fullName.trim(),
      'phone': phone.trim(),
      'shopName': shopName.trim(),
      'address': address.trim(),
      'description': description.trim(),
      'status': 'pending',
      'adminNote': '',
      'createdAt': now,
      'updatedAt': now,
    });
    batch.set(
      _firestore
          .collection('sellerApplicationsByUser')
          .doc(userId)
          .collection('applications')
          .doc(applicationId),
      {
        'status': 'pending',
        'shopName': shopName.trim(),
        'createdAt': now,
      },
    );
    batch.set(
      _firestore
          .collection('adminNotifications')
          .doc('sellerApplications')
          .collection('items')
          .doc(applicationId),
      {
        'type': 'seller_application',
        'userId': userId,
        'shopName': shopName.trim(),
        'status': 'unread',
        'createdAt': now,
      },
    );
    await batch.commit();
  }

  Stream<List<SellerConversationModel>> watchSellerConversations(
    String userId,
  ) {
    return _messagesRef
        .doc(userId)
        .collection('conversations')
        .snapshots()
        .map((snapshot) {
      final conversations = snapshot.docs
          .map((doc) => SellerConversationModel.fromMap(doc.id, doc.data()))
          .toList();
      conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return conversations;
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
    final now = DateTime.now().millisecondsSinceEpoch;
    final batch = _firestore.batch();
    batch.update(_ordersRef.doc(order.id), {
      'status': 'confirmed',
      'updatedAt': now,
    });
    batch.set(
      _firestore
          .collection('ordersByCustomer')
          .doc(order.customerId)
          .collection('orders')
          .doc(order.id),
      {
        'status': 'confirmed',
        'updatedAt': now,
      },
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  Stream<List<SellerChatMessageModel>> watchMessages({
    required String userId,
    required String sellerId,
  }) {
    return _messagesRef
        .doc(userId)
        .collection('conversations')
        .doc(sellerId)
        .collection('items')
        .snapshots()
        .map((snapshot) {
      final messages = snapshot.docs
          .map((doc) => SellerChatMessageModel.fromMap(doc.id, doc.data()))
          .toList();
      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return messages;
    });
  }

  Future<void> sendMessage({
    required String userId,
    required String sellerId,
    required String sellerName,
    required String text,
    String customerName = '',
  }) async {
    final messageId = _messagesRef.doc().id;
    final now = DateTime.now().millisecondsSinceEpoch;
    final cleanText = text.trim();
    final customerMessageRef = _messagesRef
        .doc(userId)
        .collection('conversations')
        .doc(sellerId);
    final sellerMessageRef = _firestore
        .collection('sellerMessages')
        .doc(sellerId)
        .collection('conversations')
        .doc(userId);
    final messageData = {
      'senderId': userId,
      'senderType': 'customer',
      'text': cleanText,
      'createdAt': now,
    };
    final batch = _firestore.batch();

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
    batch.set(sellerMessageRef, {
      'customerId': userId,
      'customerName': customerName.trim(),
      'lastMessage': cleanText,
      'updatedAt': now,
    }, SetOptions(merge: true));
    batch.set(
      sellerMessageRef.collection('items').doc(messageId),
      messageData,
    );
    await batch.commit();
  }
}

class CustomerOrderModel {
  const CustomerOrderModel({
    required this.id,
    required this.status,
    required this.grandTotal,
    required this.createdAt,
    required this.itemCount,
    required this.firstProductName,
  });

  final String id;
  final String status;
  final double grandTotal;
  final int createdAt;
  final int itemCount;
  final String firstProductName;

  factory CustomerOrderModel.fromMap(String id, Map<dynamic, dynamic> map) {
    final itemsValue = map['items'];
    var itemCount = 0;
    var firstProductName = 'Đơn hàng';

    if (itemsValue is Map<dynamic, dynamic>) {
      itemCount = itemsValue.length;
      for (final value in itemsValue.values) {
        if (value is Map<dynamic, dynamic>) {
          firstProductName = value['productName']?.toString() ?? firstProductName;
          break;
        }
      }
    }

    return CustomerOrderModel(
      id: id,
      status: map['status']?.toString() ?? 'pending',
      grandTotal: _readDouble(map['grandTotal']),
      createdAt: _readInt(map['createdAt']),
      itemCount: itemCount,
      firstProductName: firstProductName,
    );
  }

  String get statusLabel {
    switch (status) {
      case 'confirmed':
        return 'Cho lay hang';
      case 'shipping':
        return 'Cho giao hang';
      case 'completed':
        return 'Da giao';
      case 'cancelled':
        return 'Da huy';
      case 'pending':
      default:
        return 'Cho xac nhan';
    }
  }
}

class SellerConversationModel {
  const SellerConversationModel({
    required this.sellerId,
    required this.sellerName,
    required this.lastMessage,
    required this.updatedAt,
  });

  final String sellerId;
  final String sellerName;
  final String lastMessage;
  final int updatedAt;

  factory SellerConversationModel.fromMap(
    String sellerId,
    Map<dynamic, dynamic> map,
  ) {
    return SellerConversationModel(
      sellerId: sellerId,
      sellerName: map['sellerName']?.toString() ?? 'Seller $sellerId',
      lastMessage: map['lastMessage']?.toString() ?? '',
      updatedAt: _readInt(map['updatedAt']),
    );
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
  });

  final String id;
  final String customerId;
  final String status;
  final double grandTotal;
  final int createdAt;
  final Set<String> sellerIds;
  final String firstProductName;

  bool get canConfirm => status == 'pending';

  factory SellerOrderModel.fromMap(String id, Map<dynamic, dynamic> map) {
    final sellerIds = <String>{};
    var firstProductName = 'Đơn hàng';
    final itemsValue = map['items'];
    if (itemsValue is Map<dynamic, dynamic>) {
      for (final value in itemsValue.values) {
        if (value is Map<dynamic, dynamic>) {
          final sellerId = value['sellerId']?.toString() ?? '';
          if (sellerId.isNotEmpty) {
            sellerIds.add(sellerId);
          }
          firstProductName = value['productName']?.toString() ?? firstProductName;
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
    );
  }

  String get statusLabel {
    switch (status) {
      case 'confirmed':
        return 'Chờ lấy hàng';
      case 'shipping':
        return 'Cho giao hàng';
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

class SellerChatMessageModel {
  const SellerChatMessageModel({
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

  bool get isCustomer => senderType == 'customer';

  factory SellerChatMessageModel.fromMap(
    String id,
    Map<dynamic, dynamic> map,
  ) {
    return SellerChatMessageModel(
      id: id,
      senderId: map['senderId']?.toString() ?? '',
      senderType: map['senderType']?.toString() ?? 'seller',
      text: map['text']?.toString() ?? '',
      createdAt: _readInt(map['createdAt']),
    );
  }
}

double _readDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value) ?? 0;
  }
  return 0;
}

int _readInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? 0;
  }
  return 0;
}
