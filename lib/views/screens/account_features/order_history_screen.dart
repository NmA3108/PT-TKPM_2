import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/providers/auth_provider.dart';
import '../../../utils/currency_formatter.dart';
import '../order_tracking_screen.dart';
import 'account_feature_service.dart';

const _backgroundColor = Color(0xFFF5F7FB);
const _surfaceColor = Color(0xFFFFFFFF);
const _primaryTextColor = Color(0xFF111827);
const _secondaryTextColor = Color(0xFF6B7280);
const _accentColor = Color(0xFFFF4D2D);

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({
    super.key,
    this.statuses = const <String>{},
    this.title = 'Lịch sử mua hàng',
  });

  static final _service = AccountFeatureService();

  final Set<String> statuses;
  final String title;

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().currentUser?.uid;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: _backgroundColor,
        elevation: 0,
      ),
      body: userId == null
          ? const _MessageState(
              message: 'Vui lòng đăng nhập để xem đơn hàng.',
            )
          : StreamBuilder<List<CustomerOrderModel>>(
              stream: _service.watchCustomerOrders(userId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _MessageState(
                    message: 'Không thể tải đơn hàng.\n${snapshot.error}',
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allOrders = snapshot.data ?? const <CustomerOrderModel>[];
                final orders = statuses.isEmpty
                    ? allOrders
                    : allOrders
                        .where((order) => statuses.contains(order.status))
                        .toList();

                if (orders.isEmpty) {
                  return _MessageState(
                    message: statuses.isEmpty
                        ? 'Bạn chưa có đơn hàng nào.'
                        : 'Chưa có đơn hàng trong trạng thái này.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return _OrderCard(
                      order: order,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => OrderTrackingScreen(order: order),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.onTap,
  });

  final CustomerOrderModel order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
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
                    'Đơn hàng#${order.id}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _primaryTextColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _StatusBadge(status: order.statusLabel),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              order.firstProductName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _primaryTextColor,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${order.itemCount} sản phẩm',
              style: const TextStyle(color: _secondaryTextColor),
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Tổng thanh toán',
                    style: TextStyle(color: _secondaryTextColor),
                  ),
                ),
                Text(
                  formatVnd(order.grandTotal),
                  style: const TextStyle(
                    color: _accentColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Đặt lúc: ${_formatDate(order.createdAt)}',
              style: const TextStyle(
                color: _secondaryTextColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
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

String _formatDate(int millis) {
  if (millis <= 0) return '--';

  final date = DateTime.fromMillisecondsSinceEpoch(millis);
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}
