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
      appBar: AppBar(title: const Text('Quan ly don ban')),
      body: sellerId == null
          ? const _MessageState(message: 'Vui long dang nhap.')
          : StreamBuilder<List<SellerOrderModel>>(
              stream: _service.watchSellerOrders(sellerId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _MessageState(
                    message: 'Khong the tai don ban.\n${snapshot.error}',
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final orders = snapshot.data ?? const <SellerOrderModel>[];
                if (orders.isEmpty) {
                  return const _MessageState(message: 'Chua co don ban nao.');
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _SellerOrderCard(
                      order: orders[index],
                      onConfirm: () => _confirmOrder(context, orders[index]),
                    );
                  },
                );
              },
            ),
    );
  }

  Future<void> _confirmOrder(
    BuildContext context,
    SellerOrderModel order,
  ) async {
    try {
      await _service.confirmSellerOrder(order);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Da xac nhan don hang.')),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xac nhan that bai: $error')),
      );
    }
  }
}

class _SellerOrderCard extends StatelessWidget {
  const _SellerOrderCard({
    required this.order,
    required this.onConfirm,
  });

  final SellerOrderModel order;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(18),
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
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                order.statusLabel,
                style: const TextStyle(
                  color: _accentColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(order.firstProductName),
          const SizedBox(height: 8),
          Text('Tong tien: ${_formatCurrency(order.grandTotal)}'),
          if (order.canConfirm) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onConfirm,
                style: FilledButton.styleFrom(backgroundColor: _accentColor),
                child: const Text('Xac nhan don hang'),
              ),
            ),
          ],
        ],
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
