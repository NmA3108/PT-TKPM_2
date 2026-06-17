import 'package:flutter/foundation.dart';

import '../../models/app_user.dart';
import '../../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._authService);

  final AuthService _authService;

  AppUser? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  Future<bool> register({
    required String mobileNumber,
    required String password,
  }) async {
    return _runAuthAction(
      () =>
          _authService.register(mobileNumber: mobileNumber, password: password),
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
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> _runAuthAction(Future<AppUser> Function() action) async {
    _setLoading(true);
    try {
      _currentUser = await action();
      _errorMessage = null;
      return true;
    } on AuthException catch (error) {
      _errorMessage = error.message;
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
}
