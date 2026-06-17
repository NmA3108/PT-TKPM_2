import 'package:flutter/material.dart';

import '../widgets/bottom_nav_bar.dart';
import '../widgets/chatbot_floating_button.dart';

class OrderTrackingScreen extends StatelessWidget {
  const OrderTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
        children: const [
          _OrderInfoCard(),
          SizedBox(height: 30),
          Text(
            'Tracking Status',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 20),
          TrackingStep(
            title: 'Order Placed',
            subtitle: '17 Jun 2026 - 14:30',
            completed: true,
            isFirst: true,
          ),
          TrackingStep(
            title: 'Order Confirmed',
            subtitle: '17 Jun 2026 - 15:10',
            completed: true,
          ),
          TrackingStep(
            title: 'Packed',
            subtitle: '17 Jun 2026 - 18:20',
            completed: true,
          ),
          TrackingStep(
            title: 'Shipping',
            subtitle: 'Your package is on the way',
            current: true,
          ),
          TrackingStep(
            title: 'Delivered',
            subtitle: 'Expected: 20 Jun 2026',
            isLast: true,
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _OrderInfoCard extends StatelessWidget {
  const _OrderInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order #ORD001245',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 10),
          Text('Placed on: 17 Jun 2026', style: TextStyle(color: Colors.black54)),
          SizedBox(height: 6),
          Text(
            'Total Payment: \$345.12',
            style: TextStyle(
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
    if (completed) {
      color = Colors.green;
    }
    if (current) {
      color = Colors.orange;
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
                  Expanded(child: Container(width: 2, color: Colors.grey.shade300)),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  child: completed
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : null,
                ),
                if (!isLast)
                  Expanded(child: Container(width: 2, color: Colors.grey.shade300)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
