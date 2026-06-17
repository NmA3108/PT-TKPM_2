import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import '../main.dart';
import '../models/app_user.dart';

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthService {
  AuthService({FirebaseDatabase? database})
    : _database =
          database ??
          FirebaseDatabase.instanceFor(
            app: Firebase.app(),
            databaseURL: realtimeDatabaseUrl,
          );

  final FirebaseDatabase _database;

  DatabaseReference get _rootRef => _database.ref();
  DatabaseReference get _usersRef => _rootRef.child('users');
  DatabaseReference get _usersByPhoneRef => _rootRef.child('usersByPhone');

  Future<AppUser> register({
    required String mobileNumber,
    required String password,
  }) async {
    final normalizedPhone = _normalizeMobileNumber(mobileNumber);
    final existingUserSnapshot = await _usersByPhoneRef
        .child(normalizedPhone)
        .get();

    if (existingUserSnapshot.exists) {
      throw const AuthException('So dien thoai da duoc dang ky.');
    }

    final uid = _usersRef.push().key;
    if (uid == null) {
      throw const AuthException('Khong the tao tai khoan luc nay.');
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final salt = _createSalt();
    final passwordHash = _hashPassword(password, salt);

    final userData = {
      'uid': uid,
      'mobileNumber': normalizedPhone,
      'passwordHash': passwordHash,
      'passwordSalt': salt,
      'role': 'Customer',
      'status': 'active',
      'createdAt': now,
      'updatedAt': now,
    };

    await _rootRef.update({
      'users/$uid': userData,
      'usersByPhone/$normalizedPhone': uid,
      'userRoles/$uid': 'Customer',
    });

    return AppUser.fromMap(uid, userData);
  }

  Future<AppUser> login({
    required String mobileNumber,
    required String password,
  }) async {
    final normalizedPhone = _normalizeMobileNumber(mobileNumber);
    final uidSnapshot = await _usersByPhoneRef.child(normalizedPhone).get();

    if (!uidSnapshot.exists || uidSnapshot.value == null) {
      throw const AuthException('So dien thoai hoac mat khau khong dung.');
    }

    final uid = uidSnapshot.value.toString();
    final userSnapshot = await _usersRef.child(uid).get();
    final userValue = userSnapshot.value;

    if (userValue is! Map<dynamic, dynamic>) {
      throw const AuthException('Tai khoan khong ton tai.');
    }

    if (userValue['status'] != 'active') {
      throw const AuthException('Tai khoan da bi khoa hoac tam dung.');
    }

    final salt = userValue['passwordSalt'] as String? ?? '';
    final storedHash = userValue['passwordHash'] as String? ?? '';
    final inputHash = _hashPassword(password, salt);

    if (storedHash != inputHash) {
      throw const AuthException('So dien thoai hoac mat khau khong dung.');
    }

    return AppUser.fromMap(uid, userValue);
  }

  Future<AppUser> updateAccount({
    required String uid,
    String? fullName,
    String? email,
    String? deliveryAddress,
    String? paymentAccount,
  }) async {
    final updates = <String, Object?>{
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };

    if (fullName != null) {
      updates['fullName'] = fullName.trim();
    }
    if (email != null) {
      updates['email'] = email.trim();
    }
    if (deliveryAddress != null) {
      updates['deliveryAddress'] = deliveryAddress.trim();
    }
    if (paymentAccount != null) {
      updates['paymentAccount'] = paymentAccount.trim();
    }

    await _usersRef.child(uid).update(updates);
    return _loadUser(uid);
  }

  Future<void> changePassword({
    required String uid,
    required String currentPassword,
    required String newPassword,
  }) async {
    final snapshot = await _usersRef.child(uid).get();
    final value = snapshot.value;

    if (value is! Map<dynamic, dynamic>) {
      throw const AuthException('Tai khoan khong ton tai.');
    }

    final salt = value['passwordSalt'] as String? ?? '';
    final storedHash = value['passwordHash'] as String? ?? '';
    final inputHash = _hashPassword(currentPassword, salt);

    if (inputHash != storedHash) {
      throw const AuthException('Mat khau hien tai khong dung.');
    }

    final newSalt = _createSalt();
    await _usersRef.child(uid).update({
      'passwordSalt': newSalt,
      'passwordHash': _hashPassword(newPassword, newSalt),
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> deleteAccount(String uid) async {
    final snapshot = await _usersRef.child(uid).get();
    final value = snapshot.value;

    if (value is! Map<dynamic, dynamic>) {
      throw const AuthException('Tai khoan khong ton tai.');
    }

    final phone = value['mobileNumber']?.toString();
    await _rootRef.update({
      'users/$uid/status': 'deleted',
      'users/$uid/updatedAt': DateTime.now().millisecondsSinceEpoch,
      if (phone != null && phone.isNotEmpty) 'usersByPhone/$phone': null,
      'userRoles/$uid': null,
    });
  }

  Future<AppUser> _loadUser(String uid) async {
    final snapshot = await _usersRef.child(uid).get();
    final value = snapshot.value;

    if (value is! Map<dynamic, dynamic>) {
      throw const AuthException('Khong the tai thong tin tai khoan.');
    }

    return AppUser.fromMap(uid, value);
  }

  String _normalizeMobileNumber(String value) {
    return value.replaceAll(RegExp(r'\D'), '');
  }

  String _createSalt() {
    final random = Random.secure();
    final values = List<int>.generate(16, (_) => random.nextInt(256));
    return base64UrlEncode(values);
  }

  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode('$salt:$password');
    return sha256.convert(bytes).toString();
  }
}
