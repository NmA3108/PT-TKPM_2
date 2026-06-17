import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/user_account_models.dart';

const realtimeDatabaseUrl =
    'https://tmdt-e5958-default-rtdb.asia-southeast1.firebasedatabase.app/';

class UserAccountService {
  UserAccountService({FirebaseDatabase? database})
      : _database = database ??
            FirebaseDatabase.instanceFor(
              app: Firebase.app(),
              databaseURL: realtimeDatabaseUrl,
            );

  final FirebaseDatabase _database;

  DatabaseReference _profileRef(String uid) {
    return _database.ref('users/$uid/profile');
  }

  DatabaseReference _addressesRef(String uid) {
    return _database.ref('users/$uid/addresses');
  }

  Stream<UserProfileModel> watchProfile(String uid) {
    return _profileRef(uid).onValue.map((event) {
      final value = event.snapshot.value;
      if (value is Map<dynamic, dynamic>) {
        return UserProfileModel.fromMap(value);
      }
      return const UserProfileModel(fullName: '', phoneNumber: '', email: '');
    });
  }

  Future<void> updateProfile({
    required String uid,
    required UserProfileModel profile,
  }) async {
    await _profileRef(uid).update(profile.toMap());
  }

  Stream<List<UserAddressModel>> watchAddresses(String uid) {
    return _addressesRef(uid).onValue.map((event) {
      final value = event.snapshot.value;
      if (value is! Map<dynamic, dynamic>) {
        return <UserAddressModel>[];
      }

      final addresses = <UserAddressModel>[];
      for (final entry in value.entries) {
        final addressValue = entry.value;
        if (addressValue is Map<dynamic, dynamic>) {
          addresses.add(
            UserAddressModel.fromMap(entry.key.toString(), addressValue),
          );
        }
      }

      return addresses.reversed.toList();
    });
  }

  Future<void> addAddress({
    required String uid,
    required UserAddressModel address,
  }) async {
    final newAddressRef = _addressesRef(uid).push();
    await newAddressRef.set(address.toMap());
  }

  Future<void> deleteAddress({
    required String uid,
    required String addressId,
  }) async {
    await _addressesRef(uid).child(addressId).remove();
  }
}
