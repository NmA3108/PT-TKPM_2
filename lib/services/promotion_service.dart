import 'package:cloud_firestore/cloud_firestore.dart';

class PromotionService {
  PromotionService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<PromotionDiscount?> findActivePromotion({
    required String code,
    required Set<String> sellerIds,
  }) async {
    final cleanCode = code.trim().toUpperCase();
    final cleanSellerIds = sellerIds
        .map((sellerId) => sellerId.trim())
        .where((sellerId) => sellerId.isNotEmpty)
        .toSet();
    if (cleanCode.isEmpty || cleanSellerIds.isEmpty) {
      return null;
    }

    final snapshot = await _firestore
        .collectionGroup('items')
        .get();

    for (final doc in snapshot.docs) {
      final sellerId = doc.reference.parent.parent?.id ?? '';
      final data = doc.data();
      final promotionCode = data['code']?.toString().trim().toUpperCase() ?? '';
      if (promotionCode != cleanCode ||
          !cleanSellerIds.contains(sellerId) ||
          data['isActive'] != true) {
        continue;
      }
      return PromotionDiscount.fromMap(data);
    }
    return null;
  }
}

class PromotionDiscount {
  const PromotionDiscount({
    required this.type,
    required this.value,
  });

  final String type;
  final double value;

  double calculate(double subtotal) {
    if (type == 'percent') {
      final percent = value.clamp(0, 100).toDouble();
      return subtotal * (percent / 100);
    }
    return value > subtotal ? subtotal : value;
  }

  factory PromotionDiscount.fromMap(Map<dynamic, dynamic> map) {
    return PromotionDiscount(
      type: map['discountType']?.toString() ?? 'percent',
      value: _readDouble(map['discountValue']),
    );
  }
}

double _readDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}
