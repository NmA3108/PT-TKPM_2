import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/providers/auth_provider.dart';
import '../../models/checkout_models.dart';
import '../../models/user_account_models.dart';
import '../../services/promotion_service.dart';
import '../../services/user_account_service.dart';
import '../../utils/currency_formatter.dart';
import '../widgets/chatbot_floating_button.dart';
import 'payment_checkout_screen.dart';

const _backgroundColor = Color(0xFFF5F7FB);
const _surfaceColor = Color(0xFFFFFFFF);

class OrderCheckoutScreen extends StatefulWidget {
  const OrderCheckoutScreen({
    super.key,
    required this.items,
  });

  final List<CartItemModel> items;

  @override
  State<OrderCheckoutScreen> createState() => _OrderCheckoutScreenState();
}

class _OrderCheckoutScreenState extends State<OrderCheckoutScreen> {
  final _userService = UserAccountService();
  final _promotionService = PromotionService();
  final _voucherController = TextEditingController();
  UserAddressModel? _selectedAddress;
  String _paymentMethod = 'cod';
  double _discountTotal = 0;

  double get _subtotal {
    return widget.items.fold<double>(0, (total, item) => total + item.subtotal);
  }

  double get _shippingFee => widget.items.isEmpty ? 0 : 30000;
  double get _grandTotal => _subtotal + _shippingFee - _discountTotal;

  @override
  void dispose() {
    _voucherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().currentUser?.uid;
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: _backgroundColor,
      appBar: AppBar(title: const Text('Đặt hàng')),
      floatingActionButton: isKeyboardOpen ? null : const ChatbotFloatingButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: userId == null
          ? const _MessageState(message: 'Vui lòng đăng nhập để đặt hàng.')
          : StreamBuilder<List<UserAddressModel>>(
              stream: _userService.watchAddresses(userId),
              builder: (context, snapshot) {
                final addresses = snapshot.data ?? <UserAddressModel>[];
                final selectedAddress = _resolveSelectedAddress(addresses);
                _syncDefaultAddress(selectedAddress);

                return ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    isKeyboardOpen ? 24 : 112,
                  ),
                  children: [
                    _SectionCard(
                      title: 'Địa chỉ nhận hàng',
                      trailing: Wrap(
                        spacing: 4,
                        children: [
                          TextButton.icon(
                            onPressed: () => _addAddress(userId),
                            icon: const Icon(Icons.add_location_alt_outlined),
                            label: const Text('Them'),
                          ),
                          if (addresses.isNotEmpty)
                            TextButton(
                              onPressed: () => _selectAddress(addresses),
                              child: const Text('Doi'),
                            ),
                        ],
                      ),
                      child: selectedAddress == null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Ban chua co dia chi nhan hang.'),
                                const SizedBox(height: 10),
                                OutlinedButton.icon(
                                  onPressed: () => _addAddress(userId),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Them dia chi'),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedAddress.receiverName,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const SizedBox(height: 4),
                                Text(selectedAddress.phoneNumber),
                                const SizedBox(height: 4),
                                Text(selectedAddress.detailAddress),
                              ],
                            ),
                    ),
                    const SizedBox(height: 14),
                    _SectionCard(
                      title: 'Sản phẩm',
                      child: Column(
                        children: widget.items.map((item) {
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(item.productName),
                            subtitle: Text(
                              '${_optionText(item)} • x${item.quantity}',
                            ),
                            trailing: Text(_formatCurrency(item.subtotal)),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SectionCard(
                      title: 'Voucher',
                      child: _VoucherInput(
                        controller: _voucherController,
                        onApply: _applyVoucher,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SectionCard(
                      title: 'Phương thức thanh toán',
                      child: Column(
                        children: [
                          RadioListTile<String>(
                            value: 'cod',
                            groupValue: _paymentMethod,
                            onChanged: _selectPaymentMethod,
                            title: const Text('COD'),
                            subtitle: const Text('Thanh toán khi nhận hàng'),
                          ),
                          RadioListTile<String>(
                            value: 'momo',
                            groupValue: _paymentMethod,
                            onChanged: _selectPaymentMethod,
                            title: const Text('Ví điện tử'),
                            subtitle: const Text('MoMo hoặc ví đã liên kết'),
                          ),
                          RadioListTile<String>(
                            value: 'bank',
                            groupValue: _paymentMethod,
                            onChanged: _selectPaymentMethod,
                            title: const Text('Tài khoản ngân hàng'),
                            subtitle: const Text('Visa/Mastercard đã liên kết'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _OrderSummary(
                      subtotal: _subtotal,
                      shippingFee: _shippingFee,
                      discountTotal: _discountTotal,
                      grandTotal: _grandTotal,
                    ),
                  ],
                );
              },
            ),
      bottomNavigationBar: _CheckoutBottomBar(
        grandTotal: _grandTotal,
        isKeyboardOpen: isKeyboardOpen,
        onContinue: userId == null ? null : () => _continueToPayment(userId),
      ),
    );
  }

  UserAddressModel? _resolveSelectedAddress(List<UserAddressModel> addresses) {
    if (addresses.isEmpty) {
      return null;
    }

    final selectedAddress = _selectedAddress;
    if (selectedAddress == null) {
      return addresses.first;
    }

    for (final address in addresses) {
      if (address.id == selectedAddress.id) {
        return address;
      }
    }

    return addresses.first;
  }

  void _syncDefaultAddress(UserAddressModel? address) {
    if (address == null || _selectedAddress?.id == address.id) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _selectedAddress?.id == address.id) {
        return;
      }
      setState(() => _selectedAddress = address);
    });
  }

  void _selectPaymentMethod(String? value) {
    if (value == null) {
      return;
    }
    setState(() => _paymentMethod = value);
  }

  Future<void> _selectAddress(List<UserAddressModel> addresses) async {
    final result = await showModalBottomSheet<UserAddressModel>(
      context: context,
      builder: (context) => ListView(
        padding: const EdgeInsets.all(16),
        children: addresses.map((address) {
          return ListTile(
            title: Text(address.receiverName),
            subtitle: Text('${address.phoneNumber}\n${address.detailAddress}'),
            isThreeLine: true,
            onTap: () => Navigator.of(context).pop(address),
          );
        }).toList(),
      ),
    );

    if (result != null) {
      setState(() => _selectedAddress = result);
    }
  }

  Future<void> _addAddress(String userId) async {
    final result = await showModalBottomSheet<UserAddressModel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const _CheckoutAddressSheet(),
    );

    if (result == null) {
      return;
    }

    try {
      final addressId = await _userService.addAddress(
        uid: userId,
        address: result,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedAddress = UserAddressModel(
          id: addressId,
          receiverName: result.receiverName,
          phoneNumber: result.phoneNumber,
          detailAddress: result.detailAddress,
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Da them dia chi.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Them dia chi that bai: $error')),
      );
    }
  }

  void _applyVoucher() {
    _applyVoucherAsync();
  }

  Future<void> _applyVoucherAsync() async {
    final code = _voucherController.text.trim().toUpperCase();
    final sellerIds = widget.items
        .map((item) => item.sellerId.trim())
        .where((sellerId) => sellerId.isNotEmpty)
        .toSet();
    final promotion = await _promotionService.findActivePromotion(
      code: code,
      sellerIds: sellerIds,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _discountTotal = promotion?.calculate(_subtotal) ?? 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _discountTotal > 0
              ? 'Áp voucher thành công.'
              : 'Voucher không hợp lệ hoặc không được áp dụng.',
        ),
      ),
    );
  }

  void _continueToPayment(String userId) {
    final address = _selectedAddress;
    if (address == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn địa chỉ nhận hàng.')),
      );
      return;
    }

    final draft = CheckoutDraft(
      items: widget.items,
      subtotal: _subtotal,
      shippingFee: _shippingFee,
      discountTotal: _discountTotal,
      grandTotal: _grandTotal,
      addressId: address.id,
      receiverName: address.receiverName,
      receiverPhone: address.phoneNumber,
      addressDetail: address.detailAddress,
      paymentMethod: _paymentMethod,
      voucherCode: _voucherController.text.trim(),
    );

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PaymentCheckoutScreen(
          userId: userId,
          draft: draft,
        ),
      ),
    );
  }
}

class _CheckoutAddressSheet extends StatefulWidget {
  const _CheckoutAddressSheet();

  @override
  State<_CheckoutAddressSheet> createState() => _CheckoutAddressSheetState();
}

class _CheckoutAddressSheetState extends State<_CheckoutAddressSheet> {
  final _formKey = GlobalKey<FormState>();
  final _receiverController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void dispose() {
    _receiverController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Them dia chi',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _receiverController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Nguoi nhan'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'So dien thoai'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Dia chi chi tiet'),
                validator: _required,
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _submit,
                child: const Text('Luu dia chi'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.of(context).pop(
      UserAddressModel(
        id: '',
        receiverName: _receiverController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        detailAddress: _addressController.text.trim(),
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui long nhap thong tin.';
    }
    return null;
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

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
              Expanded(
                child: Text(title, style: Theme.of(context).textTheme.titleMedium),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _VoucherInput extends StatelessWidget {
  const _VoucherInput({
    required this.controller,
    required this.onApply,
  });

  final TextEditingController controller;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useVerticalLayout = constraints.maxWidth < 360;

        final input = TextField(
          controller: controller,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            hintText: 'Nhập mã giảm giá',
          ),
          onSubmitted: (_) => onApply(),
        );

        final button = FilledButton(
          onPressed: onApply,
          child: const Text('Áp dụng'),
        );

        if (useVerticalLayout) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              input,
              const SizedBox(height: 10),
              button,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: input),
            const SizedBox(width: 10),
            SizedBox(width: 112, child: button),
          ],
        );
      },
    );
  }
}

class _OrderSummary extends StatelessWidget {
  const _OrderSummary({
    required this.subtotal,
    required this.shippingFee,
    required this.discountTotal,
    required this.grandTotal,
  });

  final double subtotal;
  final double shippingFee;
  final double discountTotal;
  final double grandTotal;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Tổng thanh toán',
      child: Column(
        children: [
          _SummaryRow(label: 'Tạm tính', value: subtotal),
          _SummaryRow(label: 'Phí vận chuyển', value: shippingFee),
          _SummaryRow(label: 'Giảm giá', value: -discountTotal),
          const Divider(),
          _SummaryRow(label: 'Tổng cộng', value: grandTotal, emphasized: true),
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

class _CheckoutBottomBar extends StatelessWidget {
  const _CheckoutBottomBar({
    required this.grandTotal,
    required this.isKeyboardOpen,
    required this.onContinue,
  });

  final double grandTotal;
  final bool isKeyboardOpen;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    if (isKeyboardOpen) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        color: _surfaceColor,
        child: Row(
          children: [
            Expanded(
              child: Text(
                _formatCurrency(grandTotal),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            SizedBox(
              width: 170,
              child: FilledButton(
                onPressed: onContinue,
                child: const Text('Thanh toán'),
              ),
            ),
          ],
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
