import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/user_account_models.dart';

const realtimeDatabaseUrl =
    'https://tmdt-e5958-default-rtdb.asia-southeast1.firebasedatabase.app/';

class PaymentService {
  PaymentService({FirebaseDatabase? database})
      : _database = database ??
            FirebaseDatabase.instanceFor(
              app: Firebase.app(),
              databaseURL: realtimeDatabaseUrl,
            );

  final FirebaseDatabase _database;

  DatabaseReference _paymentMethodsRef(String uid) {
    return _database.ref('users/$uid/payment_methods');
  }

  Future<void> ensurePaymentMethodDefaults(String uid) async {
    final snapshot = await _paymentMethodsRef(uid).get();
    final value = snapshot.value;
    final updates = <String, Object?>{};

    if (value is! Map<dynamic, dynamic> || value['momo'] is! Map) {
      updates['momo/linked'] = false;
    }

    if (value is! Map<dynamic, dynamic> || value['bank'] is! Map) {
      updates['bank/linked'] = false;
    }

    if (updates.isNotEmpty) {
      await _paymentMethodsRef(uid).update(updates);
    }
  }

  Stream<List<PaymentMethodModel>> watchLinkedMethods(String uid) {
    return _paymentMethodsRef(uid).onValue.map((event) {
      final value = event.snapshot.value;
      if (value is! Map<dynamic, dynamic>) {
        return <PaymentMethodModel>[];
      }

      final methods = <PaymentMethodModel>[];
      final momo = value['momo'];
      final bank = value['bank'];

      if (momo is Map<dynamic, dynamic>) {
        final method = PaymentMethodModel.fromMap(
          PaymentMethodType.momo,
          momo,
        );
        if (method.linked) {
          methods.add(method);
        }
      }

      if (bank is Map<dynamic, dynamic>) {
        final method = PaymentMethodModel.fromMap(
          PaymentMethodType.bank,
          bank,
        );
        if (method.linked) {
          methods.add(method);
        }
      }

      return methods;
    });
  }

  Future<void> linkMomo({
    required String uid,
    required String phoneNumber,
  }) async {
    await _paymentMethodsRef(uid).child('momo').update(
          PaymentMethodModel(
            type: PaymentMethodType.momo,
            linked: true,
            phoneNumber: phoneNumber.trim(),
          ).toMap(),
        );
  }

  Future<void> linkBankCard({
    required String uid,
    required String cardNumber,
    required String expiryDate,
  }) async {
    final normalizedCardNumber = cardNumber.replaceAll(' ', '');
    final cardLast4 = normalizedCardNumber.length <= 4
        ? normalizedCardNumber
        : normalizedCardNumber.substring(normalizedCardNumber.length - 4);

    await _paymentMethodsRef(uid).child('bank').update(
          PaymentMethodModel(
            type: PaymentMethodType.bank,
            linked: true,
            cardLast4: cardLast4,
            expiryDate: expiryDate.trim(),
          ).toMap(),
        );
  }

  Future<void> unlinkPaymentMethod({
    required String uid,
    required PaymentMethodType type,
  }) async {
    switch (type) {
      case PaymentMethodType.momo:
        await _paymentMethodsRef(uid).child('momo').set({
          'linked': false,
        });
        return;
      case PaymentMethodType.bank:
        await _paymentMethodsRef(uid).child('bank').set({
          'linked': false,
        });
        return;
    }
  }
}
