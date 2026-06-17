import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../services/product_detail_service.dart';

class CartProvider extends ChangeNotifier {
  CartProvider(this._service);

  final ProductDetailService _service;
  StreamSubscription<int>? _cartCountSubscription;
  String? _currentUserId;
  int _itemCount = 0;

  int get itemCount => _itemCount;

  void watchUserCart(String userId) {
    if (_currentUserId == userId) {
      return;
    }

    _currentUserId = userId;
    _cartCountSubscription?.cancel();
    _cartCountSubscription = _service.watchCartItemCount(userId).listen(
      (count) {
        _itemCount = count;
        notifyListeners();
      },
      onError: (_) {
        _itemCount = 0;
        notifyListeners();
      },
    );
  }

  void clear() {
    _currentUserId = null;
    _itemCount = 0;
    _cartCountSubscription?.cancel();
    _cartCountSubscription = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _cartCountSubscription?.cancel();
    super.dispose();
  }
}
