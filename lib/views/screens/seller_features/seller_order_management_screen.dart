import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/providers/auth_provider.dart';
import 'seller_feature_service.dart';

const _backgroundColor = Color(0xFFF5F7FB);
const _surfaceColor = Color(0xFFFFFFFF);
const _accentColor = Color(0xFFFF4D2D);

class SellerOrderManagementScreen extends StatelessWidget {
  const SellerOrderManagementScreen({super.key});

  static final _service = SellerFeatureService();

  @override
  Widget build(BuildContext context) {
    final sellerId = context.watch<AuthProvider>().currentUser?.uid;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text('Quản lý đơn bán'),
        backgroundColor: _backgroundColor,
        elevation: 0,
      ),
      body: sellerId == null
          ? const _MessageState(message: 'Vui lòng đăng nhập.')
          : StreamBuilder<List<SellerOrderModel>>(
              stream: _service.watchSellerOrders(sellerId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _MessageState(
                    message: 'Không thể tải đơn bán.\n${snapshot.error}',
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final orders = snapshot.data ?? const <SellerOrderModel>[];

                if (orders.isEmpty) {
                  return const _MessageState(message: 'Chưa có đơn bán nào.');
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _SellerOrderCard(
                      order: orders[index],
                      onUpdateStatus: (newStatus) {
                        _updateOrderStatus(context, orders[index], newStatus);
                      },
                    );
                  },
                );
              },
            ),
    );
  }

  Future<void> _updateOrderStatus(
    BuildContext context,
    SellerOrderModel order,
    String newStatus,
  ) async {
    try {
      await _service.updateSellerOrderStatus(order, newStatus);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật trạng thái đơn hàng.')),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cập nhật thất bại: $error')),
      );
    }
  }
}

class _SellerOrderCard extends StatelessWidget {
  const _SellerOrderCard({
    required this.order,
    required this.onUpdateStatus,
  });

  final SellerOrderModel order;
  final ValueChanged<String> onUpdateStatus;

  @override
  Widget build(BuildContext context) {
    final nextStatus = _getNextStatus(order.status);
    final nextStatusLabel = _getNextStatusLabel(order.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Đơn #${order.id}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              _StatusBadge(status: order.statusLabel),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            order.firstProductName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${order.itemCount} sản phẩm',
            style: const TextStyle(color: Colors.black54),
          ),
          const Divider(height: 24),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Tổng tiền',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
              Text(
                _formatCurrency(order.grandTotal),
                style: const TextStyle(
                  color: _accentColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          if (nextStatus != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => onUpdateStatus(nextStatus),
                style: FilledButton.styleFrom(
                  backgroundColor: _accentColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(nextStatusLabel),
              ),
            ),
          ] else ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'Đơn hàng đã hoàn tất',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String? _getNextStatus(String status) {
    switch (status) {
      case 'pending':
        return 'confirmed';
      case 'confirmed':
        return 'packed';
      case 'packed':
        return 'shipping';
      case 'shipping':
        return 'delivered';
      default:
        return null;
    }
  }

  String _getNextStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Xác nhận đơn hàng';
      case 'confirmed':
        return 'Chuyển sang đang đóng gói';
      case 'packed':
        return 'Chuyển sang đang giao hàng';
      case 'shipping':
        return 'Xác nhận đã giao hàng';
      default:
        return 'Cập nhật trạng thái';
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: _accentColor,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
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

  return '${buffer}đ';
}