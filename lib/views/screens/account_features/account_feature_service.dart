import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../../main.dart';

class AccountFeatureService {
  AccountFeatureService({FirebaseDatabase? database})
      : _database = database ??
            FirebaseDatabase.instanceFor(
              app: Firebase.app(),
              databaseURL: realtimeDatabaseUrl,
            );

  final FirebaseDatabase _database;

  DatabaseReference get _ordersRef => _database.ref('orders');
  DatabaseReference get _sellerApplicationsRef {
    return _database.ref('sellerApplications');
  }

  DatabaseReference get _messagesRef => _database.ref('messages');

  Stream<List<CustomerOrderModel>> watchCustomerOrders(String userId) {
    return _ordersRef.orderByChild('customerId').equalTo(userId).onValue.map(
      (event) {
        final value = event.snapshot.value;
        if (value is! Map<dynamic, dynamic>) {
          return <CustomerOrderModel>[];
        }

        final orders = <CustomerOrderModel>[];
        for (final entry in value.entries) {
          final orderValue = entry.value;
          if (orderValue is Map<dynamic, dynamic>) {
            orders.add(
              CustomerOrderModel.fromMap(entry.key.toString(), orderValue),
            );
          }
        }
        orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return orders;
      },
    );
  }

  Future<void> submitSellerApplication({
    required String userId,
    required String fullName,
    required String phone,
    required String shopName,
    required String address,
    required String description,
  }) async {
    final applicationRef = _sellerApplicationsRef.push();
    final applicationId = applicationRef.key;
    if (applicationId == null) {
      throw Exception('Khong the tao don dang ky.');
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    await _database.ref().update({
      'sellerApplications/$applicationId': {
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
      },
      'sellerApplicationsByUser/$userId/$applicationId': {
        'status': 'pending',
        'shopName': shopName.trim(),
        'createdAt': now,
      },
      'adminNotifications/sellerApplications/$applicationId': {
        'type': 'seller_application',
        'userId': userId,
        'shopName': shopName.trim(),
        'status': 'unread',
        'createdAt': now,
      },
    });
  }

  Stream<List<SellerConversationModel>> watchSellerConversations(
    String userId,
  ) {
    return _messagesRef.child(userId).onValue.map((event) {
      final value = event.snapshot.value;
      if (value is! Map<dynamic, dynamic>) {
        return <SellerConversationModel>[];
      }

      final conversations = <SellerConversationModel>[];
      for (final entry in value.entries) {
        final conversationValue = entry.value;
        if (conversationValue is Map<dynamic, dynamic>) {
          conversations.add(
            SellerConversationModel.fromMap(
              entry.key.toString(),
              conversationValue,
            ),
          );
        }
      }
      conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return conversations;
    });
  }

  Stream<List<SellerOrderModel>> watchSellerOrders(String sellerId) {
    return _ordersRef.onValue.map((event) {
      final value = event.snapshot.value;
      if (value is! Map<dynamic, dynamic>) {
        return <SellerOrderModel>[];
      }

      final orders = <SellerOrderModel>[];
      for (final entry in value.entries) {
        final orderValue = entry.value;
        if (orderValue is Map<dynamic, dynamic>) {
          final order = SellerOrderModel.fromMap(entry.key.toString(), orderValue);
          if (order.sellerIds.contains(sellerId)) {
            orders.add(order);
          }
        }
      }
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    });
  }

  Future<void> confirmSellerOrder(SellerOrderModel order) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _database.ref().update({
      'orders/${order.id}/status': 'confirmed',
      'orders/${order.id}/updatedAt': now,
      'ordersByCustomer/${order.customerId}/${order.id}/status': 'confirmed',
      'ordersByCustomer/${order.customerId}/${order.id}/updatedAt': now,
    });
  }

  Stream<List<SellerChatMessageModel>> watchMessages({
    required String userId,
    required String sellerId,
  }) {
    return _messagesRef
        .child(userId)
        .child(sellerId)
        .child('items')
        .onValue
        .map((event) {
      final value = event.snapshot.value;
      if (value is! Map<dynamic, dynamic>) {
        return <SellerChatMessageModel>[];
      }

      final messages = <SellerChatMessageModel>[];
      for (final entry in value.entries) {
        final messageValue = entry.value;
        if (messageValue is Map<dynamic, dynamic>) {
          messages.add(
            SellerChatMessageModel.fromMap(entry.key.toString(), messageValue),
          );
        }
      }
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
    final messageRef = _messagesRef.child(userId).child(sellerId).child('items').push();
    final messageId = messageRef.key;
    if (messageId == null) {
      throw Exception('Khong the gui tin nhan.');
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    await _database.ref().update({
      'messages/$userId/$sellerId/sellerId': sellerId,
      'messages/$userId/$sellerId/sellerName': sellerName,
      'messages/$userId/$sellerId/lastMessage': text.trim(),
      'messages/$userId/$sellerId/updatedAt': now,
      'messages/$userId/$sellerId/items/$messageId': {
        'senderId': userId,
        'senderType': 'customer',
        'text': text.trim(),
        'createdAt': now,
      },
      'sellerMessages/$sellerId/$userId/customerId': userId,
      'sellerMessages/$sellerId/$userId/customerName': customerName.trim(),
      'sellerMessages/$sellerId/$userId/lastMessage': text.trim(),
      'sellerMessages/$sellerId/$userId/updatedAt': now,
      'sellerMessages/$sellerId/$userId/items/$messageId': {
        'senderId': userId,
        'senderType': 'customer',
        'text': text.trim(),
        'createdAt': now,
      },
    });
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
    var firstProductName = 'Don hang';

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
    var firstProductName = 'Don hang';
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
