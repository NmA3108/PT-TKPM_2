import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthService {
  AuthService({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  CollectionReference<Map<String, dynamic>> get _usersRef {
    return _firestore.collection('users');
  }

  CollectionReference<Map<String, dynamic>> get _usersByPhoneRef {
    return _firestore.collection('usersByPhone');
  }

  CollectionReference<Map<String, dynamic>> get _usersByEmailRef {
    return _firestore.collection('usersByEmail');
  }

  CollectionReference<Map<String, dynamic>> get _userRolesRef {
    return _firestore.collection('userRoles');
  }

  Stream<AppUser?> watchUser(String uid) {
    late StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>
        userSubscription;
    late StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>
        roleSubscription;
    Map<String, dynamic>? userData;
    Map<String, dynamic>? roleData;

    final controller = StreamController<AppUser?>();

    void emitUser() {
      final data = userData;
      if (data == null) {
        return;
      }

      final mergedData = Map<String, dynamic>.from(data);
      mergedData['role'] = _effectiveRole(
        data['role']?.toString(),
        roleData?['role']?.toString(),
      );
      controller.add(AppUser.fromMap(uid, mergedData));
    }

    controller.onListen = () {
      userSubscription = _usersRef.doc(uid).snapshots().listen(
        (snapshot) {
          userData = snapshot.data();
          emitUser();
        },
        onError: controller.addError,
      );
      roleSubscription = _userRolesRef.doc(uid).snapshots().listen(
        (snapshot) {
          roleData = snapshot.data();
          emitUser();
        },
        onError: controller.addError,
      );
    };

    controller.onCancel = () async {
      await userSubscription.cancel();
      await roleSubscription.cancel();
    };

    return controller.stream;
  }

  Future<AppUser> register({
    required String mobileNumber,
    String? email,
    required String password,
  }) async {
    final normalizedPhone = _normalizeMobileNumber(mobileNumber);
    final normalizedEmail = _normalizeEmail(email ?? '');
    if (normalizedPhone.isEmpty && normalizedEmail.isEmpty) {
      throw const AuthException('Vui lòng nhập số điện thoại hoặc email.');
    }

    if (normalizedPhone.isNotEmpty) {
      final existingUid = await _findUidByPhone(normalizedPhone);
      if (existingUid != null) {
        throw const AuthException('Số điện thoại đã được đăng ký.');
      }
    }

    if (normalizedEmail.isNotEmpty) {
      final existingUid = await _findUidByEmail(normalizedEmail);
      if (existingUid != null) {
        throw const AuthException('Email đã được đăng ký.');
      }
    }

    final firebaseUser = normalizedEmail.isEmpty
        ? null
        : await _createFirebaseEmailUser(
            email: normalizedEmail,
            password: password,
          );
    final uid = firebaseUser?.uid ?? _usersRef.doc().id;
    final now = DateTime.now().millisecondsSinceEpoch;
    final salt = _createSalt();
    final passwordHash = _hashPassword(password, salt);
    final defaultName = 'Customer${_randomDigits()}';

    final userData = {
      'uid': uid,
      'mobileNumber': normalizedPhone,
      'email': normalizedEmail,
      'fullName': defaultName,
      'authProvider': normalizedEmail.isEmpty ? 'custom_phone' : 'firebase_email',
      'passwordHash': passwordHash,
      'passwordSalt': salt,
      'role': 'Customer',
      'status': 'active',
      'createdAt': now,
      'updatedAt': now,
    };

    final batch = _firestore.batch();
    batch.set(_usersRef.doc(uid), userData);
    if (normalizedPhone.isNotEmpty) {
      batch.set(_usersByPhoneRef.doc(normalizedPhone), {'uid': uid});
    }
    if (normalizedEmail.isNotEmpty) {
      batch.set(_usersByEmailRef.doc(normalizedEmail), {'uid': uid});
    }
    batch.set(_userRolesRef.doc(uid), {'role': 'Customer'});
    await batch.commit();

    return AppUser.fromMap(uid, userData);
  }

  Future<AppUser> login({
    required String mobileNumber,
    required String password,
  }) async {
    final loginIdentifier = mobileNumber.trim();
    final normalizedEmail = _normalizeEmail(loginIdentifier);
    final uid = normalizedEmail.contains('@')
        ? await _signInFirebaseEmailUser(
            email: normalizedEmail,
            password: password,
          )
        : await _findUidByLoginIdentifier(loginIdentifier);
    if (uid == null || uid.isEmpty) {
      throw const AuthException('Tài khoản hoặc mật khẩu không đúng.');
    }

    final userSnapshot = await _usersRef.doc(uid).get();
    final userValue = userSnapshot.data();

    if (userValue == null) {
      throw const AuthException('Tài khoản không tồn tại.');
    }

    if (userValue['status'] != 'active') {
      throw const AuthException('Tài khoản đã bị khóa hoặc tạm dừng.');
    }

    final salt = userValue['passwordSalt'] as String? ?? '';
    final storedHash = userValue['passwordHash'] as String? ?? '';
    final inputHash = _hashPassword(password, salt);

    if (storedHash != inputHash) {
      throw const AuthException('Tài khoản hoặc mật khẩu không đúng.');
    }

    return _userFromMapWithRole(uid, userValue);
  }

  Future<AppUser> updateAccount({
    required String uid,
    String? fullName,
    String? email,
    String? deliveryAddress,
    String? paymentAccount,
  }) async {
    final currentSnapshot = await _usersRef.doc(uid).get();
    final currentData = currentSnapshot.data();
    if (currentData == null) {
      throw const AuthException('Tài khoản không tồn tại.');
    }

    final updates = <String, Object?>{
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };
    var normalizedEmail = '';

    if (fullName != null) {
      updates['fullName'] = fullName.trim();
    }
    if (email != null) {
      normalizedEmail = _normalizeEmail(email);
      final existingUid = await _findUidByEmail(normalizedEmail);
      if (existingUid != null && existingUid != uid) {
        throw const AuthException('Email đã được đăng ký.');
      }
      updates['email'] = normalizedEmail;
    }
    if (deliveryAddress != null) {
      updates['deliveryAddress'] = deliveryAddress.trim();
    }
    if (paymentAccount != null) {
      updates['paymentAccount'] = paymentAccount.trim();
    }

    final batch = _firestore.batch();
    batch.update(_usersRef.doc(uid), updates);
    if (email != null) {
      final oldEmail = currentData['email']?.toString() ?? '';
      if (oldEmail.isNotEmpty && oldEmail != normalizedEmail) {
        batch.delete(_usersByEmailRef.doc(oldEmail));
      }
      if (normalizedEmail.isNotEmpty) {
        batch.set(_usersByEmailRef.doc(normalizedEmail), {'uid': uid});
      }
    }
    await batch.commit();
    return _loadUser(uid);
  }

  Future<void> changePassword({
    required String uid,
    required String currentPassword,
    required String newPassword,
  }) async {
    final snapshot = await _usersRef.doc(uid).get();
    final value = snapshot.data();

    if (value == null) {
      throw const AuthException('Tài khoản không tồn tại.');
    }

    final salt = value['passwordSalt'] as String? ?? '';
    final storedHash = value['passwordHash'] as String? ?? '';
    final inputHash = _hashPassword(currentPassword, salt);

    if (inputHash != storedHash) {
      throw const AuthException('Mật khẩu hiện tại không đúng.');
    }

    final newSalt = _createSalt();
    await _usersRef.doc(uid).update({
      'passwordSalt': newSalt,
      'passwordHash': _hashPassword(newPassword, newSalt),
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });

    final user = _firebaseAuth.currentUser;
    if (user != null && user.uid == uid && user.email != null) {
      await user.updatePassword(newPassword);
    }
  }

  Future<void> deleteAccount(String uid) async {
    final snapshot = await _usersRef.doc(uid).get();
    final value = snapshot.data();

    if (value == null) {
      throw const AuthException('Tài khoản không tồn tại.');
    }

    final phone = value['mobileNumber']?.toString();
    final email = value['email']?.toString();
    final batch = _firestore.batch();
    batch.update(_usersRef.doc(uid), {
      'status': 'deleted',
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
    if (phone != null && phone.isNotEmpty) {
      batch.delete(_usersByPhoneRef.doc(phone));
    }
    if (email != null && email.isNotEmpty) {
      batch.delete(_usersByEmailRef.doc(email));
    }
    batch.delete(_userRolesRef.doc(uid));
    await batch.commit();
  }

  Future<AppUser> _loadUser(String uid) async {
    final snapshot = await _usersRef.doc(uid).get();
    final value = snapshot.data();

    if (value == null) {
      throw const AuthException('Không thể tải thông tin tài khoản.');
    }

    return _userFromMapWithRole(uid, value);
  }

  Future<AppUser> _userFromMapWithRole(
    String uid,
    Map<dynamic, dynamic> value,
  ) async {
    final data = Map<String, dynamic>.from(value);
    final roleSnapshot = await _userRolesRef.doc(uid).get();
    data['role'] = _effectiveRole(
      data['role']?.toString(),
      roleSnapshot.data()?['role']?.toString(),
    );
    return AppUser.fromMap(uid, data);
  }

  String _effectiveRole(String? userRole, String? indexedRole) {
    if (_isSellerRole(userRole) || _isSellerRole(indexedRole)) {
      return 'Seller';
    }
    if (userRole != null && userRole.trim().isNotEmpty) {
      return userRole;
    }
    if (indexedRole != null && indexedRole.trim().isNotEmpty) {
      return indexedRole;
    }
    return 'Customer';
  }

  bool _isSellerRole(String? role) {
    final normalized = role?.trim().toLowerCase();
    return normalized == 'seller' ||
        normalized == 'nguoi ban' ||
        normalized == 'người bán';
  }

  Future<String?> _findUidByPhone(String normalizedPhone) async {
    if (normalizedPhone.isEmpty) {
      return null;
    }

    final uidSnapshot = await _usersByPhoneRef.doc(normalizedPhone).get();
    final uidData = uidSnapshot.data();
    final uidFromIndex = uidData?['uid']?.toString() ??
        uidData?['userId']?.toString() ??
        uidData?['value']?.toString();

    if (uidFromIndex != null && uidFromIndex.isNotEmpty) {
      return uidFromIndex;
    }

    final userQuery = await _usersRef
        .where('mobileNumber', isEqualTo: normalizedPhone)
        .limit(1)
        .get();

    if (userQuery.docs.isEmpty) {
      return null;
    }

    return userQuery.docs.first.id;
  }

  Future<String?> _findUidByEmail(String normalizedEmail) async {
    if (normalizedEmail.isEmpty) {
      return null;
    }

    final uidSnapshot = await _usersByEmailRef.doc(normalizedEmail).get();
    final uidData = uidSnapshot.data();
    final uidFromIndex = uidData?['uid']?.toString() ??
        uidData?['userId']?.toString() ??
        uidData?['value']?.toString();

    if (uidFromIndex != null && uidFromIndex.isNotEmpty) {
      return uidFromIndex;
    }

    final userQuery = await _usersRef
        .where('email', isEqualTo: normalizedEmail)
        .limit(1)
        .get();

    if (userQuery.docs.isEmpty) {
      return null;
    }

    return userQuery.docs.first.id;
  }

  Future<String?> _findUidByLoginIdentifier(String value) async {
    final normalizedEmail = _normalizeEmail(value);
    if (normalizedEmail.contains('@')) {
      return _findUidByEmail(normalizedEmail);
    }

    final normalizedPhone = _normalizeMobileNumber(value);
    final uidByPhone = await _findUidByPhone(normalizedPhone);
    if (uidByPhone != null) {
      return uidByPhone;
    }

    if (normalizedEmail.isNotEmpty) {
      return _findUidByEmail(normalizedEmail);
    }
    return null;
  }

  String _normalizeMobileNumber(String value) {
    return value.replaceAll(RegExp(r'\D'), '');
  }

  String _normalizeEmail(String value) {
    return value.trim().toLowerCase();
  }

  Future<User> _createFirebaseEmailUser({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthException('Không thể tạo tài khoản Firebase Auth.');
      }
      return user;
    } on FirebaseAuthException catch (error) {
      throw AuthException(_firebaseAuthErrorMessage(error));
    }
  }

  Future<String?> _signInFirebaseEmailUser({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user?.uid;
      if (uid != null && uid.isNotEmpty) {
        return uid;
      }
    } on FirebaseAuthException catch (error) {
      if (error.code != 'user-not-found' &&
          error.code != 'invalid-credential' &&
          error.code != 'wrong-password') {
        throw AuthException(_firebaseAuthErrorMessage(error));
      }
    }

    return _findUidByEmail(email);
  }

  String _firebaseAuthErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'Email da duoc dang ky.';
      case 'invalid-email':
        return 'Email khong hop le.';
      case 'weak-password':
        return 'Mat khau qua yeu.';
      case 'operation-not-allowed':
        return 'Firebase Authentication chua bat Email/Password.';
      case 'user-disabled':
        return 'Tai khoan da bi khoa.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Tai khoan hoac mat khau khong dung.';
      default:
        return error.message ?? 'Firebase Authentication bi loi.';
    }
  }

  String _createSalt() {
    final random = Random.secure();
    final values = List<int>.generate(16, (_) => random.nextInt(256));
    return base64UrlEncode(values);
  }

  String _randomDigits() {
    final random = Random.secure();
    return (100 + random.nextInt(900)).toString();
  }

  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode('$salt:$password');
    return sha256.convert(bytes).toString();
  }
}
