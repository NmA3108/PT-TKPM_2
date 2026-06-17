class CartItemModel {
  const CartItemModel({
    required this.productId,
    required this.productName,
    required this.thumbnailUrl,
    required this.unitPrice,
    required this.quantity,
    required this.selectedColor,
    required this.selectedSize,
    required this.sellerId,
    required this.shopId,
  });

  final String productId;
  final String productName;
  final String thumbnailUrl;
  final double unitPrice;
  final int quantity;
  final String selectedColor;
  final String selectedSize;
  final String sellerId;
  final String shopId;

  double get subtotal => unitPrice * quantity;

  factory CartItemModel.fromMap(String productId, Map<dynamic, dynamic> map) {
    return CartItemModel(
      productId: productId,
      productName: map['productName'] as String? ?? '',
      thumbnailUrl: map['thumbnailUrl'] as String? ?? '',
      unitPrice: _readDouble(map['unitPrice']),
      quantity: _readInt(map['quantity']),
      selectedColor: map['selectedColor'] as String? ?? '',
      selectedSize: map['selectedSize'] as String? ?? '',
      sellerId: map['sellerId'] as String? ?? '',
      shopId: map['shopId'] as String? ?? '',
    );
  }

  Map<String, Object?> toOrderMap() {
    return {
      'productId': productId,
      'sellerId': sellerId,
      'shopId': shopId,
      'productName': productName,
      'thumbnailUrl': thumbnailUrl,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'selectedColor': selectedColor,
      'selectedSize': selectedSize,
      'subtotal': subtotal,
    };
  }

  static double _readDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }

  static int _readInt(Object? value) {
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
}

class CheckoutDraft {
  const CheckoutDraft({
    required this.items,
    required this.subtotal,
    required this.shippingFee,
    required this.discountTotal,
    required this.grandTotal,
    required this.addressId,
    required this.receiverName,
    required this.receiverPhone,
    required this.addressDetail,
    required this.paymentMethod,
    required this.voucherCode,
  });

  final List<CartItemModel> items;
  final double subtotal;
  final double shippingFee;
  final double discountTotal;
  final double grandTotal;
  final String addressId;
  final String receiverName;
  final String receiverPhone;
  final String addressDetail;
  final String paymentMethod;
  final String voucherCode;
}
