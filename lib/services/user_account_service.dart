import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_account_models.dart';

class UserAccountService {
  UserAccountService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _userRef(String uid) {
    return _firestore.collection('users').doc(uid);
  }

  CollectionReference<Map<String, dynamic>> _addressesRef(String uid) {
    return _userRef(uid).collection('addresses');
  }

  Stream<UserProfileModel> watchProfile(String uid) {
    return _userRef(uid).snapshots().map((snapshot) {
      final value = snapshot.data();
      if (value != null) {
        return UserProfileModel.fromMap(value);
      }
      return const UserProfileModel(fullName: '', phoneNumber: '', email: '');
    });
  }

  Future<void> updateProfile({
    required String uid,
    required UserProfileModel profile,
  }) async {
    await _userRef(uid).set(profile.toMap(), SetOptions(merge: true));
  }

  Stream<List<UserAddressModel>> watchAddresses(String uid) {
    return _addressesRef(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => UserAddressModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<String> addAddress({
    required String uid,
    required UserAddressModel address,
  }) async {
    final ref = await _addressesRef(uid).add(address.toMap());
    return ref.id;
  }

  Future<void> deleteAddress({
    required String uid,
    required String addressId,
  }) async {
    await _addressesRef(uid).doc(addressId).delete();
  }
}
