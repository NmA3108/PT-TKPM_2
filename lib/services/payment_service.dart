import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_account_models.dart';

class PaymentService {
  PaymentService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _paymentMethodsRef(String uid) {
    return _firestore.collection('users').doc(uid).collection('payment_methods');
  }

  Future<void> ensurePaymentMethodDefaults(String uid) async {
    final methodsRef = _paymentMethodsRef(uid);
    final snapshot = await methodsRef.get();
    final existingIds = snapshot.docs.map((doc) => doc.id).toSet();
    final batch = _firestore.batch();

    if (!existingIds.contains('momo')) {
      batch.set(methodsRef.doc('momo'), {'linked': false});
    }

    if (!existingIds.contains('bank')) {
      batch.set(methodsRef.doc('bank'), {'linked': false});
    }

    if (!existingIds.contains('momo') || !existingIds.contains('bank')) {
      await batch.commit();
    }
  }

  Stream<List<PaymentMethodModel>> watchLinkedMethods(String uid) {
    return _paymentMethodsRef(uid).snapshots().map((snapshot) {
      final methods = <PaymentMethodModel>[];

      for (final doc in snapshot.docs) {
        final type = switch (doc.id) {
          'momo' => PaymentMethodType.momo,
          'bank' => PaymentMethodType.bank,
          _ => null,
        };
        if (type == null) {
          continue;
        }

        final method = PaymentMethodModel.fromMap(type, doc.data());
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
    await _paymentMethodsRef(uid).doc('momo').set(
          PaymentMethodModel(
            type: PaymentMethodType.momo,
            linked: true,
            phoneNumber: phoneNumber.trim(),
          ).toMap(),
          SetOptions(merge: true),
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

    await _paymentMethodsRef(uid).doc('bank').set(
          PaymentMethodModel(
            type: PaymentMethodType.bank,
            linked: true,
            cardLast4: cardLast4,
            expiryDate: expiryDate.trim(),
          ).toMap(),
          SetOptions(merge: true),
        );
  }

  Future<void> unlinkPaymentMethod({
    required String uid,
    required PaymentMethodType type,
  }) async {
    await _paymentMethodsRef(uid).doc(type.name).set({
      'linked': false,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }
}
