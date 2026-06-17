class AppUser {
  const AppUser({
    required this.uid,
    required this.mobileNumber,
    required this.role,
    required this.createdAt,
    this.fullName = '',
    this.email = '',
    this.deliveryAddress = '',
    this.paymentAccount = '',
  });

  final String uid;
  final String mobileNumber;
  final String role;
  final int createdAt;
  final String fullName;
  final String email;
  final String deliveryAddress;
  final String paymentAccount;

  factory AppUser.fromMap(String uid, Map<dynamic, dynamic> map) {
    return AppUser(
      uid: uid,
      mobileNumber: map['mobileNumber'] as String? ?? '',
      role: map['role'] as String? ?? 'Customer',
      createdAt: map['createdAt'] as int? ?? 0,
      fullName: map['fullName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      deliveryAddress: map['deliveryAddress'] as String? ?? '',
      paymentAccount: map['paymentAccount'] as String? ?? '',
    );
  }

  AppUser copyWith({
    String? fullName,
    String? email,
    String? deliveryAddress,
    String? paymentAccount,
  }) {
    return AppUser(
      uid: uid,
      mobileNumber: mobileNumber,
      role: role,
      createdAt: createdAt,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      paymentAccount: paymentAccount ?? this.paymentAccount,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'uid': uid,
      'mobileNumber': mobileNumber,
      'role': role,
      'createdAt': createdAt,
      'fullName': fullName,
      'email': email,
      'deliveryAddress': deliveryAddress,
      'paymentAccount': paymentAccount,
    };
  }
}
