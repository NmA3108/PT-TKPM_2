import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/providers/auth_provider.dart';
import '../../models/checkout_models.dart';
import '../../services/checkout_service.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/chatbot_floating_button.dart';
import 'order_checkout_screen.dart';

const _backgroundColor = Color(0xFFEFFBFF);
const _surfaceColor = Color(0xFFFFFFFF);
const _dangerColor = Color(0xFFEF4444);
const _primaryTextColor = Color(0xFF0B1B2E);
const _secondaryTextColor = Color(0xFF8A8F9C);

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _service = CheckoutService();

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().currentUser?.uid;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        title: const Text('Shopping Bag'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.shopping_bag_outlined),
          ),
        ],
      ),
      floatingActionButton: const ChatbotFloatingButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 2),
      body: userId == null
          ? const _MessageState(message: 'Vui lòng đăng nhập để xem giỏ hàng.')
          : StreamBuilder<List<CartItemModel>>(
              stream: _service.watchCartItems(userId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _MessageState(
                    message: 'Không thể tải giỏ hàng.\n${snapshot.error}',
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final items = snapshot.data ?? <CartItemModel>[];
                if (items.isEmpty) {
                  return const _MessageState(message: 'Giỏ hàng đang trống.');
                }

                final subtotal = items.fold<double>(
                  0,
                  (total, item) => total + item.subtotal,
                );

                return Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 18),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return _CartItemCard(
                            item: item,
                            onDecrease: () => _updateQuantity(
                              userId,
                              item,
                              item.quantity - 1,
                            ),
                            onIncrease: () => _updateQuantity(
                              userId,
                              item,
                              item.quantity + 1,
                            ),
                            onDelete: () => _removeItem(userId, item),
                          );
                        },
                      ),
                    ),
                    _CartSummaryPanel(
                      subtotal: subtotal,
                      itemCount: items.length,
                      onCheckout: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => OrderCheckoutScreen(items: items),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
    );
  }

  Future<void> _updateQuantity(
    String userId,
    CartItemModel item,
    int quantity,
  ) async {
    try {
      await _service.updateCartItemQuantity(
        userId: userId,
        item: item,
        quantity: quantity,
      );
    } catch (error) {
      _showSnackBar('Cập nhật giỏ hàng thất bại: $error');
    }
  }

  Future<void> _removeItem(String userId, CartItemModel item) async {
    try {
      await _service.removeCartItem(userId: userId, productId: item.productId);
      _showSnackBar('Đã xóa sản phẩm khỏi giỏ hàng.');
    } catch (error) {
      _showSnackBar('Xóa sản phẩm thất bại: $error');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.item,
    required this.onDecrease,
    required this.onIncrease,
    required this.onDelete,
  });

  final CartItemModel item;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 66,
              width: 66,
              child: ColoredBox(
                color: const Color(0xFFEDE3FF),
                child: CachedNetworkImage(
                  imageUrl: item.thumbnailUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const Icon(
                    Icons.shopping_bag,
                    color: Color(0xFF347DFF),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _primaryTextColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.selectedColor} • ${item.selectedSize}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _secondaryTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatCurrency(item.unitPrice),
                  style: const TextStyle(
                    color: _primaryTextColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: onDelete,
                child: const Icon(Icons.close, size: 18),
              ),
              const Spacer(),
              _QuantityStepper(
                quantity: item.quantity,
                onDecrease: onDecrease,
                onIncrease: onIncrease,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleStepButton(icon: Icons.remove, filled: false, onTap: onDecrease),
        const SizedBox(width: 10),
        Text(
          quantity.toString().padLeft(2, '0'),
          style: const TextStyle(
            color: _primaryTextColor,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 10),
        _CircleStepButton(icon: Icons.add, filled: true, onTap: onIncrease),
      ],
    );
  }
}

class _CircleStepButton extends StatelessWidget {
  const _CircleStepButton({
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        height: 28,
        width: 28,
        decoration: BoxDecoration(
          color: filled ? const Color(0xFF347DFF) : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF347DFF), width: 1.4),
        ),
        child: Icon(
          icon,
          size: 16,
          color: filled ? Colors.white : const Color(0xFF347DFF),
        ),
      ),
    );
  }
}

class _CartSummaryPanel extends StatelessWidget {
  const _CartSummaryPanel({
    required this.subtotal,
    required this.itemCount,
    required this.onCheckout,
  });

  final double subtotal;
  final int itemCount;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    const shipping = 2.0;
    final total = subtotal + shipping;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 28, 16, 28),
        decoration: const BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SummaryLine(label: 'Subtotal', value: subtotal),
            const Divider(height: 28),
            _SummaryLine(label: 'Shipping', value: shipping),
            const Divider(height: 28),
            _SummaryLine(
              label: 'Bag Total',
              value: total,
              itemCount: itemCount,
              emphasized: true,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: onCheckout,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Proceed To Checkout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.label,
    required this.value,
    this.itemCount,
    this.emphasized = false,
  });

  final String label;
  final double value;
  final int? itemCount;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: _primaryTextColor,
              fontSize: emphasized ? 16 : 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (itemCount != null)
          Text(
            '($itemCount items) ',
            style: const TextStyle(color: _secondaryTextColor, fontSize: 12),
          ),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: _formatCurrency(value),
                style: TextStyle(
                  color: _primaryTextColor,
                  fontSize: emphasized ? 18 : 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const TextSpan(
                text: ' USD',
                style: TextStyle(
                  color: _secondaryTextColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
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
  return '\$${value.toStringAsFixed(2)}';
}
