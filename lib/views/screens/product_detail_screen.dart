import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/providers/auth_provider.dart';
import '../../controllers/providers/cart_provider.dart';
import '../../models/product_detail_model.dart';
import '../../services/product_detail_service.dart';
import '../widgets/chatbot_floating_button.dart';
import 'cart_screen.dart';

const _backgroundColor = Color(0xFFEFFBFF);
const _surfaceColor = Color(0xFFFFFFFF);
const _primaryTextColor = Color(0xFF0B1B2E);
const _secondaryTextColor = Color(0xFF697180);
const _accentColor = Color(0xFF3B82F6);

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
          floatingActionButton: const ChatbotFloatingButton(),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          appBar: AppBar(
            backgroundColor: _backgroundColor,
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.chevron_left, size: 30),
            ),
            title: const _ShopLogo(),
            actions: const [
              Padding(
                padding: EdgeInsets.only(right: 12),
                child: _CartBadgeButton(),
              ),
            ],
          ),
          body: _buildBody(snapshot, product),
          bottomNavigationBar: product == null
              ? null
              : _ProductBottomBar(
                  quantity: _quantity,
                  total: product.price * _quantity,
                  isAddingToCart: _isAddingToCart,
                  canDecrease: _quantity > 1,
                  canIncrease: _quantity < product.stockQuantity,
                  onDecrease: _decreaseQuantity,
                  onIncrease: () => _increaseQuantity(product.stockQuantity),
                  onAddToCart: () => _addToCart(product),
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
      return _MessageState(message: 'Không thể tải sản phẩm.\n${snapshot.error}');
    }

    if (product == null) {
      return const _MessageState(message: 'Sản phẩm không còn tồn tại');
    }

    _selectedColor ??= product.colors.isEmpty ? '' : product.colors.first;
    _selectedSize ??= product.sizes.isEmpty ? '' : product.sizes.first;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 124),
      children: [
        _ProductShowcase(
          product: product,
          selectedColor: _selectedColor ?? '',
          selectedSize: _selectedSize ?? '',
          isFavorite: _isFavorite,
          onFavoriteTap: () => setState(() => _isFavorite = !_isFavorite),
          onColorSelected: (value) => setState(() => _selectedColor = value),
          onSizeSelected: (value) => setState(() => _selectedSize = value),
        ),
        const SizedBox(height: 24),
        _DescriptionSection(product: product),
        const SizedBox(height: 24),
        _SimilarProductsSection(service: _service, product: product),
      ],
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

  Future<void> _addToCart(ProductDetailModel product) async {
    final userId = context.read<AuthProvider>().currentUser?.uid;
    if (userId == null) {
      _showSnackBar('Vui lòng đăng nhập để thêm sản phẩm vào giỏ hàng.');
      return;
    }

    if (!product.isAvailable) {
      _showSnackBar('Sản phẩm hiện không còn hàng.');
      return;
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
        return;
      }
      context.read<CartProvider>().watchUserCart(userId);
      _showSnackBar('Đã thêm sản phẩm vào giỏ hàng thành công!');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showSnackBar('Thêm vào giỏ hàng thất bại: $error');
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

class _ShopLogo extends StatelessWidget {
  const _ShopLogo();

  @override
  Widget build(BuildContext context) {
    return const Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'Shop',
            style: TextStyle(
              color: Colors.black,
              fontSize: 40,
              fontWeight: FontWeight.w900,
            ),
          ),
          TextSpan(
            text: '.',
            style: TextStyle(
              color: Color(0xFF9DFF00),
              fontSize: 40,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _CartBadgeButton extends StatelessWidget {
  const _CartBadgeButton();

  @override
  Widget build(BuildContext context) {
    final itemCount = context.watch<CartProvider>().itemCount;

    return IconButton(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const CartScreen()),
        );
      },
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.shopping_bag_outlined),
          if (itemCount > 0)
            Positioned(
              right: -7,
              top: -8,
              child: Container(
                height: 16,
                constraints: const BoxConstraints(minWidth: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  itemCount > 99 ? '99+' : itemCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProductShowcase extends StatelessWidget {
  const _ProductShowcase({
    required this.product,
    required this.selectedColor,
    required this.selectedSize,
    required this.isFavorite,
    required this.onFavoriteTap,
    required this.onColorSelected,
    required this.onSizeSelected,
  });

  final ProductDetailModel product;
  final String selectedColor;
  final String selectedSize;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;
  final ValueChanged<String> onColorSelected;
  final ValueChanged<String> onSizeSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: ColoredBox(
                      color: const Color(0xFFF7F7F7),
                      child: CachedNetworkImage(
                        imageUrl: product.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        errorWidget: (_, __, ___) => const Icon(
                          Icons.image_not_supported_outlined,
                          color: _secondaryTextColor,
                          size: 44,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 16,
                  top: 16,
                  child: Material(
                    color: const Color(0xFFEF3340),
                    shape: const CircleBorder(),
                    elevation: 10,
                    shadowColor: const Color(0x44EF3340),
                    child: IconButton(
                      onPressed: onFavoriteTap,
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _primaryTextColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFA51E),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Promo Exclusion',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatCurrency(product.price),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ColorChoices(
                  values: product.colors.isEmpty
                      ? const ['Purple', 'Orange', 'Teal', 'Blue']
                      : product.colors,
                  selectedValue: selectedColor,
                  onSelected: onColorSelected,
                ),
              ),
              const Text('Size:', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(width: 10),
              _SizeBadge(
                value: selectedSize.isEmpty
                    ? (product.sizes.isEmpty ? '9' : product.sizes.first)
                    : selectedSize,
                values: product.sizes,
                onSelected: onSizeSelected,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ColorChoices extends StatelessWidget {
  const _ColorChoices({
    required this.values,
    required this.selectedValue,
    required this.onSelected,
  });

  final List<String> values;
  final String selectedValue;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final fallbackColors = [
      const Color(0xFFBFB2F6),
      const Color(0xFFE34B0B),
      const Color(0xFF32B5A8),
      const Color(0xFFA8C0DC),
    ];

    return Wrap(
      spacing: 10,
      children: [
        for (var index = 0; index < values.take(4).length; index++)
          GestureDetector(
            onTap: () => onSelected(values[index]),
            child: Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                color: fallbackColors[index % fallbackColors.length],
                shape: BoxShape.circle,
                border: Border.all(
                  color: values[index] == selectedValue
                      ? Colors.black
                      : Colors.white,
                  width: values[index] == selectedValue ? 2 : 1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SizeBadge extends StatelessWidget {
  const _SizeBadge({
    required this.value,
    required this.values,
    required this.onSelected,
  });

  final String value;
  final List<String> values;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      itemBuilder: (context) {
        final items = values.isEmpty ? <String>[value] : values;
        return items
            .map((item) => PopupMenuItem(value: item, child: Text(item)))
            .toList();
      },
      child: Container(
        height: 36,
        width: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFD1D5DB)),
        ),
        child: Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }
}

class _DescriptionSection extends StatelessWidget {
  const _DescriptionSection({required this.product});

  final ProductDetailModel product;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Description',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: _primaryTextColor,
                    ),
              ),
            ),
            const Icon(Icons.star, color: Color(0xFFFFB020), size: 22),
            const SizedBox(width: 6),
            Text(
              '${product.ratingAverage.toStringAsFixed(1)}/5',
              style: const TextStyle(
                color: _primaryTextColor,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          product.description.isEmpty
              ? 'Sản phẩm chưa có mô tả chi tiết.'
              : product.description,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _secondaryTextColor,
            fontSize: 15,
            height: 1.45,
          ),
        ),
      ],
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sản phẩm tương tự',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 214,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: products.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return _SimilarProductCard(product: products[index]);
                },
              ),
            ),
          ],
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
      width: 150,
      child: Card(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ProductDetailScreen(productId: product.id),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: product.imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const Icon(
                        Icons.image_not_supported_outlined,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(_formatCurrency(product.price)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductBottomBar extends StatelessWidget {
  const _ProductBottomBar({
    required this.quantity,
    required this.total,
    required this.isAddingToCart,
    required this.canDecrease,
    required this.canIncrease,
    required this.onDecrease,
    required this.onIncrease,
    required this.onAddToCart,
  });

  final int quantity;
  final double total;
  final bool isAddingToCart;
  final bool canDecrease;
  final bool canIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onAddToCart;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
          boxShadow: [
            BoxShadow(
              color: Color(0x16000000),
              blurRadius: 16,
              offset: Offset(0, -7),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _QuantityStepper(
                  quantity: quantity,
                  canDecrease: canDecrease,
                  canIncrease: canIncrease,
                  onDecrease: onDecrease,
                  onIncrease: onIncrease,
                ),
                const Spacer(),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'Total: '),
                      TextSpan(
                        text: _formatCurrency(total),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  style: const TextStyle(
                    color: _primaryTextColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: isAddingToCart ? null : onAddToCart,
                style: FilledButton.styleFrom(
                  backgroundColor: _accentColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: isAddingToCart
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Add to cart'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
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
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RoundStepButton(
            icon: Icons.remove,
            enabled: canDecrease,
            onPressed: onDecrease,
          ),
          SizedBox(
            width: 34,
            child: Text(
              quantity.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          _RoundStepButton(
            icon: Icons.add,
            enabled: canIncrease,
            onPressed: onIncrease,
          ),
        ],
      ),
    );
  }
}

class _RoundStepButton extends StatelessWidget {
  const _RoundStepButton({
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 15),
      constraints: const BoxConstraints.tightFor(width: 32, height: 32),
      padding: EdgeInsets.zero,
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
  return '\$${value.toStringAsFixed(value >= 100 ? 0 : 2)}';
}
