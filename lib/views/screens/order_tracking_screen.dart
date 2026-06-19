import 'package:flutter/material.dart';

import 'account_features/account_feature_service.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/chatbot_floating_button.dart';

class OrderTrackingScreen extends StatelessWidget {
  const OrderTrackingScreen({
    super.key,
    this.order,
  });

  final CustomerOrderModel? order;

  @override
  Widget build(BuildContext context) {
    final data = order;

    return Scaffold(
      backgroundColor: const Color(0xFFEFFBFF),
      floatingActionButton: const ChatbotFloatingButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEFFBFF),
        title: const Text('Order Tracking'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
        children: [
          _OrderInfoCard(order: data),
          const SizedBox(height: 30),
          const Text(
            'Tracking Status',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 20),
          ..._buildTrackingSteps(data?.status ?? 'pending'),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              Navigator.pushNamed(context, '/chatbot');
            },
            child: const Text('Contact Support'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTrackingSteps(String status) {
    final currentIndex = _statusIndex(status);

    final steps = [
      ('Order Placed', 'Your order has been created'),
      ('Order Confirmed', 'Seller confirmed your order'),
      ('Packed', 'Your package is being prepared'),
      ('Shipping', 'Your package is on the way'),
      ('Delivered', 'Order completed successfully'),
    ];

    return List.generate(steps.length, (index) {
      return TrackingStep(
        title: steps[index].$1,
        subtitle: steps[index].$2,
        completed: index < currentIndex,
        current: index == currentIndex,
        isFirst: index == 0,
        isLast: index == steps.length - 1,
      );
    });
  }

  int _statusIndex(String status) {
    switch (status) {
      case 'confirmed':
        return 1;
      case 'packed':
        return 2;
      case 'shipping':
        return 3;
      case 'completed':
      case 'delivered':
        return 4;
      case 'pending':
      default:
        return 0;
    }
  }
}

class _OrderInfoCard extends StatelessWidget {
  const _OrderInfoCard({required this.order});

  final CustomerOrderModel? order;

  @override
  Widget build(BuildContext context) {
    final id = order?.id ?? 'ORD001245';
    final total = order == null ? _formatCurrency(345000) : _formatCurrency(order!.grandTotal);
    final date = order == null ? '17 Jun 2026' : _formatDate(order!.createdAt);
    final product = order?.firstProductName ?? 'Demo product';
    final status = order?.statusLabel ?? 'Chờ xác nhận';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order #$id',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            product,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Text('Placed on: $date', style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 6),
          Text(
            'Status: $status',
            style: const TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Total Payment: $total',
            style: const TextStyle(
              color: Color(0xFF347DFF),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class TrackingStep extends StatelessWidget {
  const TrackingStep({
    super.key,
    required this.title,
    required this.subtitle,
    this.completed = false,
    this.current = false,
    this.isFirst = false,
    this.isLast = false,
  });

  final String title;
  final String subtitle;
  final bool completed;
  final bool current;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    var color = Colors.grey;
    IconData? icon;

    if (completed) {
      color = Colors.green;
      icon = Icons.check;
    }

    if (current) {
      color = Colors.orange;
      icon = Icons.local_shipping_rounded;
    }

    return SizedBox(
      height: 95,
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                if (!isFirst)
                  Expanded(
                    child: Container(width: 2, color: Colors.grey.shade300),
                  ),
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  child: icon == null
                      ? null
                      : Icon(icon, color: Colors.white, size: 15),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: Colors.grey.shade300),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: current ? const Color(0xFFFFF3E0) : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            ),
          ),
        ],
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

String _formatDate(int millis) {
  if (millis <= 0) return '--';

  final date = DateTime.fromMillisecondsSinceEpoch(millis);
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}
