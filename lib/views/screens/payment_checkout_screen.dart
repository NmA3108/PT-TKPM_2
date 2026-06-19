import 'package:flutter/material.dart';

import '../../models/checkout_models.dart';
import '../../services/checkout_service.dart';
import '../../utils/currency_formatter.dart';
import '../widgets/chatbot_floating_button.dart';

const _backgroundColor = Color(0xFFF5F7FB);
const _surfaceColor = Color(0xFFFFFFFF);

class PaymentCheckoutScreen extends StatefulWidget {
  const PaymentCheckoutScreen({
    super.key,
    required this.userId,
    required this.draft,
  });

  final String userId;
  final CheckoutDraft draft;

  @override
  State<PaymentCheckoutScreen> createState() => _PaymentCheckoutScreenState();
}

class _PaymentCheckoutScreenState extends State<PaymentCheckoutScreen> {
  final _service = CheckoutService();
  var _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(title: const Text('Thanh toán đơn hàng')),
      floatingActionButton: const ChatbotFloatingButton(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
        children: [
          _StepCard(
            icon: Icons.location_on_outlined,
            title: 'Địa chỉ nhận hàng',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.draft.receiverName,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(widget.draft.receiverPhone),
                const SizedBox(height: 4),
                Text(widget.draft.addressDetail),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _StepCard(
            icon: Icons.payments_outlined,
            title: 'Phương thức thanh toán',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _PaymentMethodLogo(method: widget.draft.paymentMethod),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(_paymentMethodLabel(widget.draft.paymentMethod)),
                    ),
                    const Icon(Icons.check_circle, color: Color(0xFF16A34A)),
                  ],
                ),
                if (widget.draft.paymentMethod != 'cod') ...[
                  const SizedBox(height: 14),
                  _PaymentPreviewCard(method: widget.draft.paymentMethod),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          _StepCard(
            icon: Icons.local_offer_outlined,
            title: 'Voucher',
            child: Text(
              widget.draft.voucherCode.isEmpty
                  ? 'Không áp dụng voucher'
                  : widget.draft.voucherCode,
            ),
          ),
          const SizedBox(height: 14),
          _StepCard(
            icon: Icons.receipt_long_outlined,
            title: 'Thông tin đơn hàng',
            child: Column(
              children: [
                for (final item in widget.draft.items)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.productName),
                    subtitle: Text('${_optionText(item)} • x${item.quantity}'),
                    trailing: Text(_formatCurrency(item.subtotal)),
                  ),
                const Divider(),
                _SummaryRow(label: 'Tạm tính', value: widget.draft.subtotal),
                _SummaryRow(label: 'Phí vận chuyển', value: widget.draft.shippingFee),
                _SummaryRow(label: 'Giảm giá', value: -widget.draft.discountTotal),
                _SummaryRow(
                  label: 'Cần thanh toán',
                  value: widget.draft.grandTotal,
                  emphasized: true,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          color: _surfaceColor,
          child: FilledButton(
            onPressed: _isSubmitting ? null : _confirmPayment,
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Xác nhận thanh toán'),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmPayment() async {
    setState(() => _isSubmitting = true);

    try {
      final orderId = await _service.createOrderFromCart(
        userId: widget.userId,
        draft: widget.draft,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đặt hàng thành công. Mã đơn: $orderId')),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Thanh toán thất bại: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _paymentMethodLabel(String method) {
    switch (method) {
      case 'momo':
        return 'Ví điện tử';
      case 'bank':
        return 'Tài khoản ngân hàng';
      default:
        return 'COD - Thanh toán khi nhận hàng';
    }
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _PaymentMethodLogo extends StatelessWidget {
  const _PaymentMethodLogo({required this.method});

  final String method;

  @override
  Widget build(BuildContext context) {
    final label = switch (method) {
      'momo' => 'mo\nmo',
      'bank' => 'VISA',
      _ => 'COD',
    };
    final color = switch (method) {
      'momo' => const Color(0xFFB21D6B),
      'bank' => const Color(0xFF1A73E8),
      _ => const Color(0xFF17233D),
    };

    return Container(
      height: 54,
      width: 74,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF347DFF), width: 1.6),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: method == 'momo' ? 20 : 22,
          height: 0.9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PaymentPreviewCard extends StatelessWidget {
  const _PaymentPreviewCard({required this.method});

  final String method;

  @override
  Widget build(BuildContext context) {
    final isMomo = method == 'momo';

    return Container(
      height: 158,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isMomo
              ? const [Color(0xFFD82D8B), Color(0xFF7A174D)]
              : const [Color(0xFF4169E1), Color(0xFF111936)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F2563EB),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isMomo ? 'MoMo Wallet' : 'VISA / Mastercard',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          Text(
            isMomo ? '09xx xxx xxx' : '**** **** **** 2345',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 18,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              const Text(
                'Trạng thái\nSẵn sàng thanh toán',
                style: TextStyle(
                  color: Colors.white,
                  height: 1.35,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: const Color(0xFF347DFF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Đã chọn',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final double value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final style = emphasized
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyMedium;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(_formatCurrency(value), style: style),
        ],
      ),
    );
  }
}

String _formatCurrency(double value) {
  return formatVnd(value);
}

String _optionText(CartItemModel item) {
  final values = [
    item.selectedClassification,
    item.selectedColor,
    item.selectedSize,
  ].where((value) => value.trim().isNotEmpty).toList();
  return values.isEmpty ? 'Mac dinh' : values.join(' • ');
}
