import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../../main.dart';

class SellerFeatureService {
  SellerFeatureService({FirebaseDatabase? database})
      : _database = database ??
            FirebaseDatabase.instanceFor(
              app: Firebase.app(),
              databaseURL: realtimeDatabaseUrl,
            );

  final FirebaseDatabase _database;

  DatabaseReference get _ordersRef => _database.ref('orders');
  DatabaseReference get _sellerMessagesRef => _database.ref('sellerMessages');

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
          final order = SellerOrderModel.fromMap(
            entry.key.toString(),
            orderValue,
          );

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
    await updateSellerOrderStatus(order, 'confirmed');
  }

  Future<void> updateSellerOrderStatus(
    SellerOrderModel order,
    String newStatus,
  ) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await _database.ref().update({
      'orders/${order.id}/status': newStatus,
      'orders/${order.id}/updatedAt': now,
      'ordersByCustomer/${order.customerId}/${order.id}/status': newStatus,
      'ordersByCustomer/${order.customerId}/${order.id}/updatedAt': now,
    });
  }

  Stream<List<SellerCustomerConversationModel>> watchCustomerConversations(
    String sellerId,
  ) {
    return _sellerMessagesRef.child(sellerId).onValue.map((event) {
      final value = event.snapshot.value;
      if (value is! Map<dynamic, dynamic>) {
        return <SellerCustomerConversationModel>[];
      }

      final conversations = <SellerCustomerConversationModel>[];

      for (final entry in value.entries) {
        final conversationValue = entry.value;

        if (conversationValue is Map<dynamic, dynamic>) {
          conversations.add(
            SellerCustomerConversationModel.fromMap(
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

  Stream<List<SellerCustomerMessageModel>> watchCustomerMessages({
    required String sellerId,
    required String customerId,
  }) {
    return _sellerMessagesRef
        .child(sellerId)
        .child(customerId)
        .child('items')
        .onValue
        .map((event) {
      final value = event.snapshot.value;
      if (value is! Map<dynamic, dynamic>) {
        return <SellerCustomerMessageModel>[];
      }

      final messages = <SellerCustomerMessageModel>[];

      for (final entry in value.entries) {
        final messageValue = entry.value;

        if (messageValue is Map<dynamic, dynamic>) {
          messages.add(
            SellerCustomerMessageModel.fromMap(
              entry.key.toString(),
              messageValue,
            ),
          );
        }
      }

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
    final messageRef = _sellerMessagesRef
        .child(sellerId)
        .child(customerId)
        .child('items')
        .push();

    final messageId = messageRef.key;
    if (messageId == null) {
      throw Exception('Không thể gửi tin nhắn.');
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final cleanText = text.trim();

    await _database.ref().update({
      'sellerMessages/$sellerId/$customerId/customerId': customerId,
      'sellerMessages/$sellerId/$customerId/lastMessage': cleanText,
      'sellerMessages/$sellerId/$customerId/updatedAt': now,
      'sellerMessages/$sellerId/$customerId/items/$messageId': {
        'senderId': sellerId,
        'senderType': 'seller',
        'text': cleanText,
        'createdAt': now,
      },
      'messages/$customerId/$sellerId/sellerId': sellerId,
      'messages/$customerId/$sellerId/sellerName': sellerName,
      'messages/$customerId/$sellerId/lastMessage': cleanText,
      'messages/$customerId/$sellerId/updatedAt': now,
      'messages/$customerId/$sellerId/items/$messageId': {
        'senderId': sellerId,
        'senderType': 'seller',
        'text': cleanText,
        'createdAt': now,
      },
    });
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
        return 'Chờ xác nhận';
    }
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
  ) {
    final customerName = map['customerName']?.toString().trim() ?? '';

    return SellerCustomerConversationModel(
      customerId: customerId,
      customerName:
          customerName.isEmpty ? 'Khách hàng $customerId' : customerName,
      lastMessage: map['lastMessage']?.toString() ?? '',
      updatedAt: _readInt(map['updatedAt']),
    );
  }
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