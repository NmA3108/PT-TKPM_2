import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/providers/auth_provider.dart';
import 'account_feature_service.dart';

const _backgroundColor = Color(0xFFF5F7FB);
const _surfaceColor = Color(0xFFFFFFFF);
const _primaryTextColor = Color(0xFF111827);
const _secondaryTextColor = Color(0xFF6B7280);
const _accentColor = Color(0xFFFF4D2D);

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  static final _service = AccountFeatureService();

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().currentUser?.uid;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(title: const Text('Lich su mua hang')),
      body: userId == null
          ? const _MessageState(message: 'Vui long dang nhap de xem don hang.')
          : StreamBuilder<List<CustomerOrderModel>>(
              stream: _service.watchCustomerOrders(userId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _MessageState(
                    message: 'Khong the tai don hang.\n${snapshot.error}',
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final orders = snapshot.data ?? const <CustomerOrderModel>[];
                if (orders.isEmpty) {
                  return const _MessageState(message: 'Ban chua co don hang nao.');
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _OrderCard(order: orders[index]);
                  },
                );
              },
            ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final CustomerOrderModel order;

  @override
  Widget build(BuildContext context) {
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
                  'Don #${order.id}',
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
            '${order.itemCount} san pham',
            style: const TextStyle(color: _secondaryTextColor),
          ),
          const Divider(height: 24),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Tong thanh toan',
                  style: TextStyle(color: _secondaryTextColor),
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
          const SizedBox(height: 6),
          Text(
            'Dat luc: ${_formatDate(order.createdAt)}',
            style: const TextStyle(color: _secondaryTextColor, fontSize: 12),
          ),
        ],
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

String _formatDate(int millis) {
  if (millis <= 0) {
    return '--';
  }
  final date = DateTime.fromMillisecondsSinceEpoch(millis);
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}
