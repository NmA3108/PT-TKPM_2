import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../models/app_user.dart';
import '../../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._authService);

  final AuthService _authService;

  AppUser? _currentUser;
  StreamSubscription<AppUser?>? _currentUserSubscription;
  bool _isLoading = false;
  String? _errorMessage;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  Future<bool> register({
    required String mobileNumber,
    String? email,
    required String password,
  }) async {
    return _runAuthAction(
      () => _authService.register(
        mobileNumber: mobileNumber,
        email: email,
        password: password,
      ),
    );
  }

  Future<bool> login({
    required String mobileNumber,
    required String password,
  }) async {
    return _runAuthAction(
      () => _authService.login(mobileNumber: mobileNumber, password: password),
    );
  }

  Future<bool> updateAccount({
    String? fullName,
    String? email,
    String? deliveryAddress,
    String? paymentAccount,
  }) async {
    final user = _currentUser;
    if (user == null) {
      _errorMessage = 'Ban chua dang nhap.';
      notifyListeners();
      return false;
    }

    return _runAccountAction(() async {
      _currentUser = await _authService.updateAccount(
        uid: user.uid,
        fullName: fullName,
        email: email,
        deliveryAddress: deliveryAddress,
        paymentAccount: paymentAccount,
      );
    });
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _currentUser;
    if (user == null) {
      _errorMessage = 'Ban chua dang nhap.';
      notifyListeners();
      return false;
    }

    return _runAccountAction(
      () => _authService.changePassword(
        uid: user.uid,
        currentPassword: currentPassword,
        newPassword: newPassword,
      ),
    );
  }

  Future<bool> deleteAccount() async {
    final user = _currentUser;
    if (user == null) {
      _errorMessage = 'Ban chua dang nhap.';
      notifyListeners();
      return false;
    }

    final success = await _runAccountAction(
      () => _authService.deleteAccount(user.uid),
    );

    if (success) {
      logout();
    }

    return success;
  }

  void logout() {
    _stopWatchingCurrentUser();
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> _runAuthAction(Future<AppUser> Function() action) async {
    _setLoading(true);
    try {
      _currentUser = await action();
      _watchCurrentUser(_currentUser!.uid);
      _errorMessage = null;
      return true;
    } on AuthException catch (error) {
      _errorMessage = error.message;
      return false;
    } on FirebaseException catch (error) {
      _errorMessage = _firebaseErrorMessage(error);
      return false;
    } catch (_) {
      _errorMessage = 'Da co loi xay ra. Vui long thu lai.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> _runAccountAction(Future<void> Function() action) async {
    _setLoading(true);
    try {
      await action();
      _errorMessage = null;
      return true;
    } on AuthException catch (error) {
      _errorMessage = error.message;
      return false;
    } on FirebaseException catch (error) {
      _errorMessage = _firebaseErrorMessage(error);
      return false;
    } catch (_) {
      _errorMessage = 'Da co loi xay ra. Vui long thu lai.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _watchCurrentUser(String uid) {
    _stopWatchingCurrentUser();
    _currentUserSubscription = _authService.watchUser(uid).listen(
      (user) {
        _currentUser = user;
        notifyListeners();
      },
      onError: (Object error) {
        if (error is FirebaseException) {
          _errorMessage = _firebaseErrorMessage(error);
          notifyListeners();
        }
      },
    );
  }

  void _stopWatchingCurrentUser() {
    _currentUserSubscription?.cancel();
    _currentUserSubscription = null;
  }

  @override
  void dispose() {
    _stopWatchingCurrentUser();
    super.dispose();
  }

  String _firebaseErrorMessage(FirebaseException error) {
    if (error.code == 'permission-denied') {
      return 'Firestore dang chan quyen doc/ghi. Hay deploy firestore.rules.';
    }
    if (error.code == 'unavailable') {
      return 'Khong ket noi duoc Firestore. Vui long thu lai.';
    }
    return error.message ?? 'Firebase bi loi. Vui long thu lai.';
  }
}
