import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/providers/auth_provider.dart';
import '../../models/checkout_models.dart';
import '../../services/checkout_service.dart';
import '../../utils/currency_formatter.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/app_asset_icon.dart';
import '../widgets/product_image.dart';
import 'order_checkout_screen.dart';

const _backgroundColor = Color(0xFFEFFBFF);
const _surfaceColor = Color(0xFFFFFFFF);
const _primaryTextColor = Color(0xFF0B1B2E);
const _secondaryTextColor = Color(0xFF8A8F9C);
const _accentColor = Color(0xFF5D3FD3);

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _service = CheckoutService();
  final _selectedProductIds = <String>{};
  var _didInitializeSelection = false;

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().currentUser?.uid;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        title: const Text('Giỏ hàng'),
        
      ),
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

                _syncSelectedItems(items);
                final selectedItems = items
                    .where((item) => _selectedProductIds.contains(item.cartItemId))
                    .toList();
                final groups = _groupItemsByShop(items);
                final subtotal = selectedItems.fold<double>(
                  0,
                  (total, item) => total + item.subtotal,
                );

                return Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        itemCount: groups.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 18),
                        itemBuilder: (context, index) {
                          final group = groups[index];
                          return _ShopCartGroup(
                            group: group,
                            selectedProductIds: _selectedProductIds,
                            onSelectedChanged: _toggleItemSelection,
                            onDecrease: (item) => _updateQuantity(
                              userId,
                              item,
                              item.quantity - 1,
                            ),
                            onIncrease: (item) => _updateQuantity(
                              userId,
                              item,
                              item.quantity + 1,
                            ),
                            onDelete: (item) => _removeItem(userId, item),
                          );
                        },
                      ),
                    ),
                    _CartSummaryPanel(
                      subtotal: subtotal,
                      itemCount: selectedItems.length,
                      onCheckout: selectedItems.isEmpty
                          ? null
                          : () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => OrderCheckoutScreen(
                                    items: selectedItems,
                                  ),
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
      await _service.removeCartItem(userId: userId, productId: item.cartItemId);
      _selectedProductIds.remove(item.cartItemId);
      _showSnackBar('Đã xóa sản phẩm khỏi giỏ hàng.');
    } catch (error) {
      _showSnackBar('Xóa sản phẩm thất bại: $error');
    }
  }

  void _syncSelectedItems(List<CartItemModel> items) {
    final currentIds = items.map((item) => item.cartItemId).toSet();
    if (!_didInitializeSelection) {
      _selectedProductIds
        ..clear()
        ..addAll(currentIds);
      _didInitializeSelection = true;
      return;
    }

    _selectedProductIds.removeWhere((id) => !currentIds.contains(id));
  }

  void _toggleItemSelection(CartItemModel item, bool selected) {
    setState(() {
      if (selected) {
        _selectedProductIds.add(item.cartItemId);
      } else {
        _selectedProductIds.remove(item.cartItemId);
      }
    });
  }

  List<_ShopCartGroupData> _groupItemsByShop(List<CartItemModel> items) {
    final grouped = <String, List<CartItemModel>>{};
    for (final item in items) {
      final shopKey = _shopGroupKey(item);
      grouped.putIfAbsent(shopKey, () => <CartItemModel>[]).add(item);
    }

    return grouped.entries.map((entry) {
      final firstItem = entry.value.first;
      final shopName = firstItem.shopName.trim().isNotEmpty
          ? firstItem.shopName.trim()
          : _sellerDisplayName(entry.key);
      return _ShopCartGroupData(shopName: shopName, items: entry.value);
    }).toList();
  }

  String _shopGroupKey(CartItemModel item) {
    if (item.shopName.trim().isNotEmpty) {
      return item.shopName.trim();
    }
    if (item.shopId.trim().isNotEmpty) {
      return item.shopId.trim();
    }
    if (item.sellerId.trim().isNotEmpty) {
      return item.sellerId.trim();
    }
    return 'default_shop';
  }

  String _sellerDisplayName(String sellerId) {
    if (sellerId == 'default_shop' || sellerId.trim().isEmpty) {
      return 'Seller000';
    }
    final digits = (sellerId.hashCode.abs() % 1000).toString().padLeft(3, '0');
    return 'Seller$digits';
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

class _ShopCartGroupData {
  const _ShopCartGroupData({
    required this.shopName,
    required this.items,
  });

  final String shopName;
  final List<CartItemModel> items;
}

class _ShopCartGroup extends StatelessWidget {
  const _ShopCartGroup({
    required this.group,
    required this.selectedProductIds,
    required this.onSelectedChanged,
    required this.onDecrease,
    required this.onIncrease,
    required this.onDelete,
  });

  final _ShopCartGroupData group;
  final Set<String> selectedProductIds;
  final void Function(CartItemModel item, bool selected) onSelectedChanged;
  final ValueChanged<CartItemModel> onDecrease;
  final ValueChanged<CartItemModel> onIncrease;
  final ValueChanged<CartItemModel> onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                const AppAssetIcon(assetName: 'category_icon.jpg', size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    group.shopName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _primaryTextColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          for (var index = 0; index < group.items.length; index++) ...[
            _CartItemCard(
              item: group.items[index],
              isSelected: selectedProductIds.contains(group.items[index].productId),
              onSelectedChanged: (selected) {
                onSelectedChanged(group.items[index], selected);
              },
              onDecrease: () => onDecrease(group.items[index]),
              onIncrease: () => onIncrease(group.items[index]),
              onDelete: () => onDelete(group.items[index]),
            ),
            if (index < group.items.length - 1)
              const Divider(height: 1, indent: 16, endIndent: 16),
          ],
        ],
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.item,
    required this.isSelected,
    required this.onSelectedChanged,
    required this.onDecrease,
    required this.onIncrease,
    required this.onDelete,
  });

  final CartItemModel item;
  final bool isSelected;
  final ValueChanged<bool> onSelectedChanged;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Checkbox(
            value: isSelected,
            onChanged: (value) => onSelectedChanged(value ?? false),
            activeColor: _accentColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 66,
              width: 66,
              child: ColoredBox(
                color: const Color(0xFFEDE3FF),
                child: ProductImage(
                  imageUrl: item.thumbnailUrl,
                  fit: BoxFit.cover,
                  errorWidget: const Icon(
                    Icons.shopping_bag,
                    color: _accentColor,
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
                  _optionText(item),
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
              const SizedBox(height: 16),
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

String _optionText(CartItemModel item) {
  final values = [
    item.selectedClassification,
    item.selectedColor,
    item.selectedSize,
  ].where((value) => value.trim().isNotEmpty).toList();
  return values.isEmpty ? 'Mac dinh' : values.join(' - ');
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
          color: filled ? _accentColor : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: _accentColor, width: 1.4),
        ),
        child: Icon(
          icon,
          size: 16,
          color: filled ? Colors.white : _accentColor,
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
  final VoidCallback? onCheckout;

  @override
  Widget build(BuildContext context) {
    const shipping = 30000.0;
    final total = itemCount == 0 ? 0.0 : subtotal + shipping;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 22),
        decoration: const BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SummaryLine(label: 'Tổng giá trị', value: subtotal),
            const Divider(height: 24),
            _SummaryLine(label: 'Phí vận chuyển', value: itemCount == 0 ? 0 : shipping),
            const Divider(height: 24),
            _SummaryLine(
              label: 'Tổng tiền',
              value: total,
              
              emphasized: true,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: onCheckout,
                style: FilledButton.styleFrom(
                  backgroundColor: _accentColor,
                  disabledBackgroundColor: const Color(0xFFC7CBD5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Thanh toán'),
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
        Text(
          _formatCurrency(value),
          style: TextStyle(
            color: _primaryTextColor,
            fontSize: emphasized ? 18 : 16,
            fontWeight: FontWeight.w900,
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
  return formatVnd(value);
}
