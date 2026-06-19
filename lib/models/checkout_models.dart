class CartItemModel {
  const CartItemModel({
    required this.cartItemId,
    required this.productId,
    required this.productName,
    required this.thumbnailUrl,
    required this.unitPrice,
    required this.quantity,
    required this.selectedColor,
    required this.selectedClassification,
    required this.selectedSize,
    required this.sellerId,
    required this.shopId,
    required this.shopName,
  });

  final String cartItemId;
  final String productId;
  final String productName;
  final String thumbnailUrl;
  final double unitPrice;
  final int quantity;
  final String selectedColor;
  final String selectedClassification;
  final String selectedSize;
  final String sellerId;
  final String shopId;
  final String shopName;

  double get subtotal => unitPrice * quantity;

  factory CartItemModel.fromMap(String productId, Map<dynamic, dynamic> map) {
    return CartItemModel(
      cartItemId: productId,
      productId: map['productId'] as String? ?? productId,
      productName: map['productName'] as String? ?? '',
      thumbnailUrl: map['thumbnailUrl'] as String? ?? '',
      unitPrice: _readDouble(map['unitPrice']),
      quantity: _readInt(map['quantity']),
      selectedColor: map['selectedColor'] as String? ?? '',
      selectedClassification: map['selectedClassification'] as String? ?? '',
      selectedSize: map['selectedSize'] as String? ?? '',
      sellerId: map['sellerId'] as String? ?? '',
      shopId: map['shopId'] as String? ?? '',
      shopName: map['shopName'] as String? ?? '',
    );
  }

  Map<String, Object?> toOrderMap() {
    return {
      'productId': productId,
      'sellerId': sellerId,
      'shopId': shopId,
      'shopName': shopName,
      'productName': productName,
      'thumbnailUrl': thumbnailUrl,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'selectedColor': selectedColor,
      'selectedClassification': selectedClassification,
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
