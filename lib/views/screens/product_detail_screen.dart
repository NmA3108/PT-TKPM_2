import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/providers/auth_provider.dart';
import '../../controllers/providers/cart_provider.dart';
import '../../models/checkout_models.dart';
import '../../models/product_detail_model.dart';
import '../../services/product_detail_service.dart';
import 'account_features/seller_chat_detail_screen.dart';
import 'cart_screen.dart';
import 'order_checkout_screen.dart';
import 'product_detail/product_detail_bottom_bar.dart';
import 'product_detail/product_detail_body.dart';
import 'product_detail/product_detail_state_views.dart';
import 'product_detail/product_detail_style.dart';
import 'shop_products_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  final String productId;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _service = ProductDetailService();
  var _quantity = 1;
  var _isAddingToCart = false;
  var _didStartUserBindings = false;
  String _selectedColor = '';
  String _selectedClassification = '';
  String _selectedSize = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didStartUserBindings) {
      return;
    }

    _didStartUserBindings = true;
    final userId = _currentUserId() ?? 'guest';
    if (userId != 'guest') {
      try {
        context.read<CartProvider>().watchUserCart(userId);
      } catch (_) {}
    }
    _service
        .logProductView(userId: userId, productId: widget.productId)
        .catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ProductDetailModel?>(
      stream: _service.watchProduct(widget.productId),
      builder: (context, snapshot) {
        var cartCount = 0;
        try {
          cartCount = context.watch<CartProvider>().itemCount;
        } catch (_) {}

        if (snapshot.connectionState == ConnectionState.waiting) {
          return ProductDetailLoading(onBack: _goBack);
        }

        if (snapshot.hasError) {
          return ProductDetailMessage(
            message: 'Khong the tai san pham.\n${snapshot.error}',
            onBack: _goBack,
          );
        }

        final product = snapshot.data;
        if (product == null) {
          return ProductDetailMessage(
            message: 'San pham khong con ton tai.',
            onBack: _goBack,
          );
        }

        _ensureSelectedOptions(product);

        return Scaffold(
          backgroundColor: ProductDetailColors.background,
          body: ProductDetailBody(
            product: product,
            quantity: _quantity,
            selectedColor: _selectedColor,
            selectedClassification: _selectedClassification,
            selectedSize: _selectedSize,
            onBack: _goBack,
            cartCount: cartCount,
            onCartTap: _openCart,
            onMoreTap: _showMoreActions,
            onOpenShop: () => _openShop(product),
            onColorSelected: (value) => setState(() => _selectedColor = value),
            onClassificationSelected: (value) {
              setState(() => _selectedClassification = value);
            },
            onSizeSelected: (value) => setState(() => _selectedSize = value),
            onDecreaseQuantity: _decreaseQuantity,
            onIncreaseQuantity: () => _increaseQuantity(product.stockQuantity),
          ),
          bottomNavigationBar: ProductDetailBottomBar(
            price: product.price,
            isBusy: _isAddingToCart,
            onChat: () => _openChat(product),
            onAddToCart: () => _addToCart(product),
            onBuyNow: () => _buyNow(product),
          ),
        );
      },
    );
  }

  void _ensureSelectedOptions(ProductDetailModel product) {
    final colors = visibleColors(product);
    final sizes = visibleSizes(product);

    if (_selectedColor.isEmpty && colors.isNotEmpty) {
      _selectedColor = colors.first;
    }
    if (_selectedClassification.isEmpty && product.classifications.isNotEmpty) {
      _selectedClassification = product.classifications.first;
    }
    if (_selectedSize.isEmpty && sizes.isNotEmpty) {
      _selectedSize = sizes.first;
    }
  }

  void _goBack() {
    Navigator.of(context).maybePop();
  }

  void _openCart() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const CartScreen()),
    );
  }

  void _showMoreActions() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chức năng đang được phát triển.')),
    );
  }

  void _decreaseQuantity() {
    if (_quantity > 1) {
      setState(() => _quantity--);
    }
  }

  void _increaseQuantity(int stockQuantity) {
    if (_quantity >= stockQuantity) {
      _showSnackBar('Số lượng đã đạt giới hạn tồn kho.');
      return;
    }
    setState(() => _quantity++);
  }

  void _openChat(ProductDetailModel product) {
    final sellerId = product.sellerId.trim().isNotEmpty
        ? product.sellerId.trim()
        : product.shopId.trim();
    if (sellerId.isEmpty) {
      _showSnackBar('Sản phẩm chưa có thông tin.');
      return;
    }

    final sellerName = product.shopName.trim().isNotEmpty
        ? product.shopName.trim()
        : _defaultSellerName(sellerId);

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SellerChatDetailScreen(
          sellerId: sellerId,
          sellerName: sellerName,
        ),
      ),
    );
  }

  void _openShop(ProductDetailModel product) {
    final sellerId = product.sellerId.trim().isNotEmpty
        ? product.sellerId.trim()
        : product.shopId.trim();
    if (sellerId.isEmpty) {
      _showSnackBar('Sản phẩm chưa có thông tin.');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ShopProductsScreen(
          sellerId: sellerId,
          shopName: _shopName(product),
          shopAvatarUrl: '',
        ),
      ),
    );
  }

  String _shopName(ProductDetailModel product) {
    if (product.shopName.trim().isNotEmpty) {
      return product.shopName.trim();
    }
    final sellerId = product.sellerId.trim().isNotEmpty
        ? product.sellerId.trim()
        : product.shopId.trim();
    return _defaultSellerName(sellerId);
  }

  String _defaultSellerName(String sellerId) {
    final digits = (sellerId.hashCode.abs() % 1000).toString().padLeft(3, '0');
    return 'Seller$digits';
  }

  Future<void> _buyNow(ProductDetailModel product) async {
    final userId = _currentUserId();
    if (userId == null) {
      _showSnackBar('Vui lòng đăng nhập để thanh toán.');
      return;
    }
    if (!product.isAvailable) {
      _showSnackBar('Sản phẩm hiện không còn hàng.');
      return;
    }

    final item = CartItemModel.fromMap(
      product.id,
      product.toCartItemMap(
        quantity: _quantity,
        selectedColor: _selectedColor,
        selectedClassification: _selectedClassification,
        selectedSize: _selectedSize,
      ),
    );

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OrderCheckoutScreen(items: [item]),
      ),
    );
  }

  Future<bool> _addToCart(ProductDetailModel product) async {
    final userId = _currentUserId();
    if (userId == null) {
      _showSnackBar('Vui lòng đăng nhập để thêm sản phẩm vào giỏ hàng.');
      return false;
    }
    if (!product.isAvailable) {
      _showSnackBar('Sản phẩm hiện không còn hàng.');
      return false;
    }

    setState(() => _isAddingToCart = true);
    try {
      await _service.addToCart(
        userId: userId,
        product: product,
        quantity: _quantity,
        selectedColor: _selectedColor,
        selectedClassification: _selectedClassification,
        selectedSize: _selectedSize,
      );
      if (!mounted) {
        return false;
      }
      try {
        context.read<CartProvider>().watchUserCart(userId);
      } catch (_) {}
      _showSnackBar('Đã thêm sản phẩm vào giỏ hàng thành công.');
      return true;
    } catch (error) {
      if (mounted) {
        _showSnackBar('Thêm vào giỏ hàng thất bại: $error');
      }
      return false;
    } finally {
      if (mounted) {
        setState(() => _isAddingToCart = false);
      }
    }
  }

  String? _currentUserId() {
    try {
      return context.read<AuthProvider>().currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
