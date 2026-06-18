import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/providers/auth_provider.dart';
import '../../controllers/providers/cart_provider.dart';
import '../../models/checkout_models.dart';
import '../../models/product_detail_model.dart';
import '../../services/product_detail_service.dart';
import '../widgets/product_image.dart';
import 'account_features/seller_chat_detail_screen.dart';
import 'cart_screen.dart';
import 'order_checkout_screen.dart';

const _backgroundColor = Color(0xFFF5F5F5);
const _surfaceColor = Color(0xFFFFFFFF);
const _primaryTextColor = Color(0xFF222222);
const _secondaryTextColor = Color(0xFF777777);
const _shopeeColor = Color(0xFFEE4D2D);
const _tealColor = Color(0xFF4DB6A6);

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
  var _isFavorite = false;
  var _isAddingToCart = false;
  var _didStartUserBindings = false;
  String? _selectedColor;
  String? _selectedSize;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didStartUserBindings) {
      return;
    }

    _didStartUserBindings = true;
    final userId = context.read<AuthProvider>().currentUser?.uid ?? 'guest';
    if (userId != 'guest') {
      context.read<CartProvider>().watchUserCart(userId);
    }
    _service.logProductView(userId: userId, productId: widget.productId);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ProductDetailModel?>(
      stream: _service.watchProduct(widget.productId),
      builder: (context, snapshot) {
        final product = snapshot.data;

        return Scaffold(
          backgroundColor: _backgroundColor,
          body: _buildBody(snapshot, product),
          bottomNavigationBar: product == null
              ? null
              : _ShopeeBottomBar(
                  price: product.price,
                  isAddingToCart: _isAddingToCart,
                  onChat: () => _openChat(product),
                  onAddToCart: () => _addToCart(product),
                  onBuyNow: () => _buyNow(product),
                ),
        );
      },
    );
  }

  Widget _buildBody(
    AsyncSnapshot<ProductDetailModel?> snapshot,
    ProductDetailModel? product,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      return _MessageState(message: 'Khong the tai san pham.\n${snapshot.error}');
    }

    if (product == null) {
      return const _MessageState(message: 'San pham khong con ton tai');
    }

    _selectedColor ??= product.colors.isEmpty ? '' : product.colors.first;
    _selectedSize ??= product.sizes.isEmpty ? '' : product.sizes.first;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SafeProductHeader(
            product: product,
            onBack: () => Navigator.of(context).pop(),
          ),
          _SafeProductInfo(
            product: product,
            isFavorite: _isFavorite,
            onFavorite: () => setState(() => _isFavorite = !_isFavorite),
          ),
          _OptionSection(
            product: product,
            quantity: _quantity,
            selectedColor: _selectedColor ?? '',
            selectedSize: _selectedSize ?? '',
            onColorSelected: (value) => setState(() => _selectedColor = value),
            onSizeSelected: (value) => setState(() => _selectedSize = value),
            onDecrease: _decreaseQuantity,
            onIncrease: () => _increaseQuantity(product.stockQuantity),
          ),
          const _ShippingSection(),
          _SimplePolicySection(product: product),
          _DescriptionSection(product: product),
          const SizedBox(height: 18),
        ],
      ),
    );
  }

  void _openChat(ProductDetailModel product) {
    final sellerId = product.sellerId.isNotEmpty
        ? product.sellerId
        : product.shopId.isNotEmpty
            ? product.shopId
            : '';
    if (sellerId.isEmpty) {
      _showSnackBar('San pham chua co thong tin seller.');
      return;
    }

    final sellerName = product.shopName.trim().isNotEmpty
        ? product.shopName.trim()
        : product.shopId.trim().isNotEmpty
            ? 'Shop ${product.shopId}'
            : 'Seller $sellerId';

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SellerChatDetailScreen(
          sellerId: sellerId,
          sellerName: sellerName,
        ),
      ),
    );
  }

  void _decreaseQuantity() {
    if (_quantity > 1) {
      setState(() => _quantity--);
    }
  }

  void _increaseQuantity(int stockQuantity) {
    if (_quantity >= stockQuantity) {
      _showSnackBar('So luong da dat gioi han ton kho.');
      return;
    }
    setState(() => _quantity++);
  }

  Future<void> _buyNow(ProductDetailModel product) async {
    final userId = context.read<AuthProvider>().currentUser?.uid;
    if (userId == null) {
      _showSnackBar('Vui long dang nhap de thanh toan.');
      return;
    }

    if (!product.isAvailable) {
      _showSnackBar('San pham hien khong con hang.');
      return;
    }

    final item = CartItemModel.fromMap(
      product.id,
      product.toCartItemMap(
        quantity: _quantity,
        selectedColor: _selectedColor ?? '',
        selectedSize: _selectedSize ?? '',
      ),
    );

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OrderCheckoutScreen(items: [item]),
      ),
    );
  }

  Future<bool> _addToCart(ProductDetailModel product) async {
    final userId = context.read<AuthProvider>().currentUser?.uid;
    if (userId == null) {
      _showSnackBar('Vui long dang nhap de them san pham vao gio hang.');
      return false;
    }

    if (!product.isAvailable) {
      _showSnackBar('San pham hien khong con hang.');
      return false;
    }

    setState(() => _isAddingToCart = true);
    try {
      await _service.addToCart(
        userId: userId,
        product: product,
        quantity: _quantity,
        selectedColor: _selectedColor ?? '',
        selectedSize: _selectedSize ?? '',
      );
      if (!mounted) {
        return false;
      }
      context.read<CartProvider>().watchUserCart(userId);
      _showSnackBar('Da them san pham vao gio hang thanh cong!');
      return true;
    } catch (error) {
      if (mounted) {
        _showSnackBar('Them vao gio hang that bai: $error');
      }
      return false;
    } finally {
      if (mounted) {
        setState(() => _isAddingToCart = false);
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _ProductHero extends StatelessWidget {
  const _ProductHero({
    required this.product,
    required this.onBack,
  });

  final ProductDetailModel product;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final heroHeight = screenWidth > 520 ? 430.0 : screenWidth;

    return SizedBox(
      height: heroHeight,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: Colors.white,
            child: ProductImage(
              imageUrl: product.imageUrl,
              fit: BoxFit.contain,
              placeholder: const Center(child: CircularProgressIndicator()),
              errorWidget: const Icon(
                Icons.image_not_supported_outlined,
                color: _secondaryTextColor,
                size: 54,
              ),
            ),
          ),
          Positioned(
            left: 12,
            top: MediaQuery.of(context).padding.top + 8,
            child: _CircleOverlayButton(
              icon: Icons.arrow_back,
              onPressed: onBack,
            ),
          ),
          Positioned(
            right: 12,
            top: MediaQuery.of(context).padding.top + 8,
            child: Row(
              children: [
                _CircleOverlayButton(
                  icon: Icons.share_outlined,
                  onPressed: () {},
                ),
                const SizedBox(width: 10),
                const _CartOverlayButton(),
                const SizedBox(width: 10),
                _CircleOverlayButton(
                  icon: Icons.more_vert,
                  onPressed: () {},
                ),
              ],
            ),
          ),
          Positioned(
            right: 18,
            bottom: 18,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '1/${product.imageUrls.isEmpty ? 1 : product.imageUrls.length}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SafeProductHeader extends StatelessWidget {
  const _SafeProductHeader({
    required this.product,
    required this.onBack,
  });

  final ProductDetailModel product;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final imageHeight = width > 520 ? 430.0 : width;

    return Container(
      color: Colors.white,
      child: Stack(
        children: [
          SizedBox(
            height: imageHeight,
            width: double.infinity,
            child: ProductImage(
              imageUrl: product.imageUrl,
              fit: BoxFit.contain,
              placeholder: const Center(child: CircularProgressIndicator()),
              errorWidget: const Icon(
                Icons.image_not_supported_outlined,
                color: _secondaryTextColor,
                size: 54,
              ),
            ),
          ),
          Positioned(
            left: 12,
            top: MediaQuery.of(context).padding.top + 8,
            child: _CircleOverlayButton(
              icon: Icons.arrow_back,
              onPressed: onBack,
            ),
          ),
          Positioned(
            right: 12,
            top: MediaQuery.of(context).padding.top + 8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CircleOverlayButton(
                  icon: Icons.share_outlined,
                  onPressed: () {},
                ),
                const SizedBox(width: 10),
                _CircleOverlayButton(
                  icon: Icons.shopping_cart_outlined,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const CartScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 10),
                _CircleOverlayButton(
                  icon: Icons.more_vert,
                  onPressed: () {},
                ),
              ],
            ),
          ),
          Positioned(
            right: 18,
            bottom: 18,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '1/${product.imageUrls.isEmpty ? 1 : product.imageUrls.length}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SafeProductInfo extends StatelessWidget {
  const _SafeProductInfo({
    required this.product,
    required this.isFavorite,
    required this.onFavorite,
  });

  final ProductDetailModel product;
  final bool isFavorite;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    return _WhiteSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  _formatCurrency(product.price),
                  style: const TextStyle(
                    color: _shopeeColor,
                    fontSize: 30,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                'Da ban ${product.ratingAverage > 0 ? 40 : 0}',
                style: const TextStyle(
                  color: _secondaryTextColor,
                  fontSize: 15,
                ),
              ),
              IconButton(
                tooltip: 'Them vao wishlist',
                onPressed: onFavorite,
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? _shopeeColor : _secondaryTextColor,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          Text(
            product.name,
            style: const TextStyle(
              color: _primaryTextColor,
              fontSize: 19,
              fontWeight: FontWeight.w500,
              height: 1.18,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleOverlayButton extends StatelessWidget {
  const _CircleOverlayButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.34),
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class _CartOverlayButton extends StatelessWidget {
  const _CartOverlayButton();

  @override
  Widget build(BuildContext context) {
    var itemCount = 0;
    try {
      itemCount = context.watch<CartProvider>().itemCount;
    } catch (_) {
      itemCount = 0;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        _CircleOverlayButton(
          icon: Icons.shopping_cart_outlined,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const CartScreen()),
            );
          },
        ),
        if (itemCount > 0)
          Positioned(
            right: -1,
            top: -4,
            child: Container(
              height: 19,
              constraints: const BoxConstraints(minWidth: 19),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _shopeeColor,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white, width: 1.4),
              ),
              child: Text(
                itemCount > 99 ? '99+' : itemCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PriceAndTitleSection extends StatelessWidget {
  const _PriceAndTitleSection({
    required this.product,
    required this.isFavorite,
    required this.onFavorite,
  });

  final ProductDetailModel product;
  final bool isFavorite;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    return _WhiteSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  _formatCurrency(product.price),
                  style: const TextStyle(
                    color: _shopeeColor,
                    fontSize: 30,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                'Da ban ${product.ratingAverage > 0 ? 40 : 0}',
                style: const TextStyle(color: _secondaryTextColor, fontSize: 15),
              ),
              IconButton(
                onPressed: onFavorite,
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? _shopeeColor : _secondaryTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            'Chi tu ${_formatCurrency(product.price)} x 1 ky voi SPayLater >',
            style: const TextStyle(color: _primaryTextColor, fontSize: 15),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _OutlinedTag(text: 'SPayLater'),
              const SizedBox(width: 4),
              _OutlinedTag(text: '0%'),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            product.name,
            style: const TextStyle(
              color: _primaryTextColor,
              fontSize: 19,
              fontWeight: FontWeight.w500,
              height: 1.18,
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionSection extends StatelessWidget {
  const _OptionSection({
    required this.product,
    required this.quantity,
    required this.selectedColor,
    required this.selectedSize,
    required this.onColorSelected,
    required this.onSizeSelected,
    required this.onDecrease,
    required this.onIncrease,
  });

  final ProductDetailModel product;
  final int quantity;
  final String selectedColor;
  final String selectedSize;
  final ValueChanged<String> onColorSelected;
  final ValueChanged<String> onSizeSelected;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return _WhiteSection(
      child: Column(
        children: [
          _OptionRow(
            label: 'Phan loai',
            child: _ChipWrap(
              values: product.colors.isEmpty ? const ['Mac dinh'] : product.colors,
              selectedValue: selectedColor,
              onSelected: onColorSelected,
            ),
          ),
          const SizedBox(height: 12),
          _OptionRow(
            label: 'Kich co',
            child: _ChipWrap(
              values: product.sizes.isEmpty ? const ['Free size'] : product.sizes,
              selectedValue: selectedSize,
              onSelected: onSizeSelected,
            ),
          ),
          const SizedBox(height: 12),
          _OptionRow(
            label: 'So luong',
            child: _QuantityControl(
              quantity: quantity,
              canDecrease: quantity > 1,
              canIncrease: quantity < product.stockQuantity,
              onDecrease: onDecrease,
              onIncrease: onIncrease,
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: const TextStyle(color: _secondaryTextColor, fontSize: 14),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _ChipWrap extends StatelessWidget {
  const _ChipWrap({
    required this.values,
    required this.selectedValue,
    required this.onSelected,
  });

  final List<String> values;
  final String selectedValue;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final value in values)
          ChoiceChip(
            label: Text(value),
            selected: value == selectedValue,
            onSelected: (_) => onSelected(value),
            selectedColor: const Color(0xFFFFECE7),
            labelStyle: TextStyle(
              color: value == selectedValue ? _shopeeColor : _primaryTextColor,
            ),
            side: BorderSide(
              color: value == selectedValue ? _shopeeColor : const Color(0xFFE5E5E5),
            ),
            backgroundColor: Colors.white,
            showCheckmark: false,
          ),
      ],
    );
  }
}

class _QuantityControl extends StatelessWidget {
  const _QuantityControl({
    required this.quantity,
    required this.canDecrease,
    required this.canIncrease,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int quantity;
  final bool canDecrease;
  final bool canIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _QtyButton(icon: Icons.remove, enabled: canDecrease, onTap: onDecrease),
        Container(
          width: 42,
          height: 32,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            border: Border.symmetric(
              horizontal: BorderSide(color: Color(0xFFE5E5E5)),
            ),
          ),
          child: Text('$quantity'),
        ),
        _QtyButton(icon: Icons.add, enabled: canIncrease, onTap: onIncrease),
      ],
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 34,
        height: 32,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E5E5)),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? _primaryTextColor : const Color(0xFFC9C9C9),
        ),
      ),
    );
  }
}

class _ShippingSection extends StatelessWidget {
  const _ShippingSection();

  @override
  Widget build(BuildContext context) {
    return _PressableRow(
      leading: const Icon(Icons.local_shipping_outlined, color: Color(0xFF3BA99C)),
      title: '22 Th06 - 25 Th06\nPhi ship 0d',
      subtitle: 'Tang Voucher 15.000d neu don giao sau thoi gian tren.',
      trailing: Icons.chevron_right,
    );
  }
}

class _GuaranteeSection extends StatelessWidget {
  const _GuaranteeSection({required this.product});

  final ProductDetailModel product;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PressableRow(
          leading: const Icon(Icons.verified_user_outlined, color: _shopeeColor),
          title: 'Tra hang mien phi 15 ngay  -  Bao hiem Thiet bi',
          trailing: Icons.chevron_right,
        ),
        _PressableRow(
          backgroundColor: const Color(0xFFFFF7F4),
          leading: const Icon(Icons.emoji_events_outlined, color: _shopeeColor),
          title: 'Thuoc top ban chay cua ${product.category.isEmpty ? 'san pham' : product.category}',
          titleColor: _shopeeColor,
          trailing: Icons.chevron_right,
        ),
      ],
    );
  }
}

class _SimplePolicySection extends StatelessWidget {
  const _SimplePolicySection({required this.product});

  final ProductDetailModel product;

  @override
  Widget build(BuildContext context) {
    final category = product.category.isEmpty ? 'san pham' : product.category;

    return Column(
      children: [
        _PressableRow(
          leading: const Icon(Icons.verified_user_outlined, color: _shopeeColor),
          title: 'Tra hang mien phi 15 ngay - Bao hiem thiet bi',
          trailing: Icons.chevron_right,
        ),
        _PressableRow(
          backgroundColor: const Color(0xFFFFF7F4),
          leading: const Icon(Icons.emoji_events_outlined, color: _shopeeColor),
          title: 'Thuoc top ban chay cua $category',
          titleColor: _shopeeColor,
          trailing: Icons.chevron_right,
        ),
      ],
    );
  }
}

class _ShopSection extends StatelessWidget {
  const _ShopSection({required this.product});

  final ProductDetailModel product;

  @override
  Widget build(BuildContext context) {
    final shopName = product.shopName.trim().isNotEmpty
        ? product.shopName.trim()
        : product.shopId.trim().isNotEmpty
            ? 'Shop ${product.shopId}'
            : 'XeGiaTot Official';

    return _WhiteSection(
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: Color(0xFFFFECE7),
            child: Icon(Icons.storefront, color: _shopeeColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shopName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _primaryTextColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Online 12 phut truoc | 98% phan hoi chat',
                  style: TextStyle(color: _secondaryTextColor, fontSize: 13),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: _shopeeColor,
              side: const BorderSide(color: _shopeeColor),
            ),
            child: const Text('Xem shop'),
          ),
        ],
      ),
    );
  }
}

class _ReviewSection extends StatelessWidget {
  const _ReviewSection({required this.product});

  final ProductDetailModel product;

  @override
  Widget build(BuildContext context) {
    final rating = product.ratingAverage <= 0 ? 4.9 : product.ratingAverage;

    return _WhiteSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                rating.toStringAsFixed(1),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.star, color: Color(0xFFFFC44D), size: 24),
              const SizedBox(width: 4),
              const Expanded(
                child: Text(
                  'Danh Gia San Pham (14)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              const Text('Tat ca >', style: TextStyle(color: _secondaryTextColor)),
            ],
          ),
          const SizedBox(height: 14),
          const _ReviewPreview(
            name: 'manman.tnk',
            text: 'Shop giao dung hen, chat luong on so voi gia tien. San pham dung mo ta va dong goi chac chan.',
          ),
          const Divider(height: 26),
          const _ReviewPreview(
            name: 'taphoangocquynhnhu',
            text: 'San pham chac chan, dep, shop giao cung nhanh. Tam hai long.',
          ),
        ],
      ),
    );
  }
}

class _ReviewPreview extends StatelessWidget {
  const _ReviewPreview({
    required this.name,
    required this.text,
  });

  final String name;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 15,
              backgroundColor: Color(0xFFE8EEF3),
              child: Icon(Icons.person, size: 16, color: _secondaryTextColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
            const Text('Huu ich (0)'),
            const SizedBox(width: 4),
            const Icon(Icons.thumb_up_alt_outlined, size: 17),
          ],
        ),
        const SizedBox(height: 8),
        const Row(
          children: [
            Icon(Icons.star, color: Color(0xFFFFC44D), size: 17),
            Icon(Icons.star, color: Color(0xFFFFC44D), size: 17),
            Icon(Icons.star, color: Color(0xFFFFC44D), size: 17),
            Icon(Icons.star, color: Color(0xFFFFC44D), size: 17),
            Icon(Icons.star, color: Color(0xFFFFC44D), size: 17),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          text,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 15, height: 1.35),
        ),
      ],
    );
  }
}

class _DescriptionSection extends StatelessWidget {
  const _DescriptionSection({required this.product});

  final ProductDetailModel product;

  @override
  Widget build(BuildContext context) {
    return _WhiteSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mo ta san pham',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Text(
            product.description.isEmpty
                ? 'San pham chua co mo ta chi tiet.'
                : product.description,
            style: const TextStyle(
              color: _primaryTextColor,
              fontSize: 15,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _SimilarProductsSection extends StatelessWidget {
  const _SimilarProductsSection({
    required this.service,
    required this.product,
  });

  final ProductDetailService service;
  final ProductDetailModel product;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ProductDetailModel>>(
      stream: service.watchSimilarProducts(
        currentProductId: product.id,
        categoryId: product.categoryId,
        category: product.category,
      ),
      builder: (context, snapshot) {
        final products = snapshot.data ?? const <ProductDetailModel>[];
        if (products.isEmpty) {
          return const SizedBox.shrink();
        }

        return _WhiteSection(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'San pham tuong tu',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 208,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    return _SimilarProductCard(product: products[index]);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SimilarProductCard extends StatelessWidget {
  const _SimilarProductCard({required this.product});

  final ProductDetailModel product;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 138,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ProductDetailScreen(productId: product.id),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ProductImage(
                  imageUrl: product.imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorWidget: const Icon(Icons.image_not_supported_outlined),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              _formatCurrency(product.price),
              style: const TextStyle(color: _shopeeColor, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopeeBottomBar extends StatelessWidget {
  const _ShopeeBottomBar({
    required this.price,
    required this.isAddingToCart,
    required this.onChat,
    required this.onAddToCart,
    required this.onBuyNow,
  });

  final double price;
  final bool isAddingToCart;
  final VoidCallback onChat;
  final VoidCallback onAddToCart;
  final VoidCallback onBuyNow;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 64,
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x16000000),
              blurRadius: 10,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              flex: 7,
              child: Row(
                children: [
                  Expanded(
                    child: _BottomActionButton(
                      color: _tealColor,
                      icon: Icons.chat_bubble_outline,
                      label: 'Chat ngay',
                      onPressed: onChat,
                    ),
                  ),
                  Container(width: 1, height: 36, color: const Color(0x33808080)),
                  Expanded(
                    child: _BottomActionButton(
                      color: _tealColor,
                      icon: Icons.add_shopping_cart_outlined,
                      label: 'Them vao Gio hang',
                      onPressed: isAddingToCart ? null : onAddToCart,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 6,
              child: Material(
                color: const Color.fromARGB(255, 240, 70, 36),
                child: InkWell(
                  onTap: isAddingToCart ? null : onBuyNow,
                  child: SizedBox.expand(
                    child: Center(
                      child: isAddingToCart
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Mua voi voucher\n${_formatCurrency(price)}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                height: 1.2,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomActionButton extends StatelessWidget {
  const _BottomActionButton({
    required this.color,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: color,
        shape: const RoundedRectangleBorder(),
        minimumSize: const Size(0, 64),
        padding: EdgeInsets.zero,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _WhiteSection extends StatelessWidget {
  const _WhiteSection({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      color: _surfaceColor,
      child: child,
    );
  }
}

class _PressableRow extends StatelessWidget {
  const _PressableRow({
    required this.leading,
    required this.title,
    this.subtitle,
    this.titleColor,
    this.backgroundColor,
    this.trailing,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final Color? backgroundColor;
  final IconData? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      color: backgroundColor ?? _surfaceColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: subtitle == null ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: titleColor ?? _primaryTextColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _secondaryTextColor, fontSize: 14),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null)
            Icon(trailing, color: const Color(0xFFB6B6B6)),
        ],
      ),
    );
  }
}

class _OutlinedTag extends StatelessWidget {
  const _OutlinedTag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: _shopeeColor),
      ),
      child: Text(
        text,
        style: const TextStyle(color: _shopeeColor, fontSize: 13),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}

String _formatCurrency(double value) {
  final rounded = value.round().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < rounded.length; index++) {
    final fromEnd = rounded.length - index;
    buffer.write(rounded[index]);
    if (fromEnd > 1 && fromEnd % 3 == 1) {
      buffer.write('.');
    }
  }
  return '${buffer}d';
}
