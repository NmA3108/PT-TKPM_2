class UserProfileModel {
  const UserProfileModel({
    required this.fullName,
    required this.phoneNumber,
    required this.email,
  });

  final String fullName;
  final String phoneNumber;
  final String email;

  factory UserProfileModel.fromMap(Map<dynamic, dynamic> map) {
    return UserProfileModel(
      fullName: map['fullName'] as String? ?? '',
      phoneNumber: map['phoneNumber'] as String? ?? '',
      email: map['email'] as String? ?? '',
    );
  }

  Map<String, Object?> toMap() {
    return {
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'email': email,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };
  }
}

class UserAddressModel {
  const UserAddressModel({
    required this.id,
    required this.receiverName,
    required this.phoneNumber,
    required this.detailAddress,
  });

  final String id;
  final String receiverName;
  final String phoneNumber;
  final String detailAddress;

  factory UserAddressModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return UserAddressModel(
      id: id,
      receiverName: map['receiverName'] as String? ?? '',
      phoneNumber: map['phoneNumber'] as String? ?? '',
      detailAddress: map['detailAddress'] as String? ?? '',
    );
  }

  Map<String, Object?> toMap() {
    return {
      'receiverName': receiverName,
      'phoneNumber': phoneNumber,
      'detailAddress': detailAddress,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    };
  }
}

enum PaymentMethodType {
  momo,
  bank,
}

class PaymentMethodModel {
  const PaymentMethodModel({
    required this.type,
    required this.linked,
    this.phoneNumber = '',
    this.cardLast4 = '',
    this.expiryDate = '',
  });

  final PaymentMethodType type;
  final bool linked;
  final String phoneNumber;
  final String cardLast4;
  final String expiryDate;

  String get key {
    switch (type) {
      case PaymentMethodType.momo:
        return 'momo';
      case PaymentMethodType.bank:
        return 'bank';
    }
  }

  String get title {
    switch (type) {
      case PaymentMethodType.momo:
        return 'Ví điện tử MoMo';
      case PaymentMethodType.bank:
        return 'Thẻ Ngân hàng (Visa/Mastercard)';
    }
  }

  String get subtitle {
    switch (type) {
      case PaymentMethodType.momo:
        return phoneNumber.isEmpty ? 'Đã liên kết' : phoneNumber;
      case PaymentMethodType.bank:
        return cardLast4.isEmpty ? 'Đã liên kết' : '**** **** **** $cardLast4';
    }
  }

  factory PaymentMethodModel.fromMap(
    PaymentMethodType type,
    Map<dynamic, dynamic> map,
  ) {
    return PaymentMethodModel(
      type: type,
      linked: map['linked'] as bool? ?? false,
      phoneNumber: map['phoneNumber'] as String? ?? '',
      cardLast4: map['cardLast4'] as String? ?? '',
      expiryDate: map['expiryDate'] as String? ?? '',
    );
  }

  Map<String, Object?> toMap() {
    return {
      'linked': linked,
      if (phoneNumber.isNotEmpty) 'phoneNumber': phoneNumber,
      if (cardLast4.isNotEmpty) 'cardLast4': cardLast4,
      if (expiryDate.isNotEmpty) 'expiryDate': expiryDate,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };
  }
}
