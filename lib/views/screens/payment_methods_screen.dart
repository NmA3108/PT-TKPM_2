import 'package:flutter/material.dart';

import '../../models/user_account_models.dart';
import '../../services/payment_service.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({
    super.key,
    required this.currentUid,
  });

  final String currentUid;

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final _service = PaymentService();
  String? _linkingMethodKey;

  bool get _isLinking => _linkingMethodKey != null;

  @override
  void initState() {
    super.initState();
    _ensurePaymentDefaults();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      appBar: AppBar(
        title: const Text('Tài khoản thanh toán'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF7F7F8),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              _SectionTitle(
                title: 'Phương thức đã liên kết',
                icon: Icons.verified_outlined,
              ),
              const SizedBox(height: 12),
              _LinkedMethodsSection(
                stream: _service.watchLinkedMethods(widget.currentUid),
                onDelete: _isLinking ? null : _confirmUnlinkMethod,
              ),
              const SizedBox(height: 24),
              const _SectionTitle(
                title: 'Đối tác khả dụng',
                icon: Icons.add_card_outlined,
              ),
              const SizedBox(height: 12),
              _PartnerCard(
                title: 'Ví điện tử MoMo',
                subtitle: 'Liên kết bằng số điện thoại ví MoMo',
                icon: Icons.account_balance_wallet_outlined,
                color: const Color(0xFFD82D8B),
                onTap: _isLinking ? null : _openMomoDialog,
              ),
              const SizedBox(height: 12),
              _PartnerCard(
                title: 'Thẻ Ngân hàng (Visa/Mastercard)',
                subtitle: 'Liên kết bằng số thẻ và hạn thẻ',
                icon: Icons.credit_card_outlined,
                color: const Color(0xFF2563EB),
                onTap: _isLinking ? null : _openBankDialog,
              ),
            ],
          ),
          if (_isLinking)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withOpacity(0.18),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 14),
                        Text('Đang xác thực liên kết...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openMomoDialog() async {
    final phoneNumber = await showDialog<String>(
      context: context,
      builder: (_) => const _MomoLinkDialog(),
    );

    if (phoneNumber == null) {
      return;
    }

    await _runFakeVerification(
      methodKey: 'momo',
      action: () => _service.linkMomo(
        uid: widget.currentUid,
        phoneNumber: phoneNumber,
      ),
    );
  }

  Future<void> _openBankDialog() async {
    final bankInfo = await showDialog<_BankCardInput>(
      context: context,
      builder: (_) => const _BankLinkDialog(),
    );

    if (bankInfo == null) {
      return;
    }

    await _runFakeVerification(
      methodKey: 'bank',
      action: () => _service.linkBankCard(
        uid: widget.currentUid,
        cardNumber: bankInfo.cardNumber,
        expiryDate: bankInfo.expiryDate,
      ),
    );
  }

  Future<void> _ensurePaymentDefaults() async {
    try {
      await _service.ensurePaymentMethodDefaults(widget.currentUid);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showSnackBar('Không thể khởi tạo phương thức thanh toán: $error');
    }
  }

  Future<void> _confirmUnlinkMethod(PaymentMethodModel method) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa liên kết thanh toán'),
        content: Text('Bạn có muốn xóa liên kết ${method.title}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() => _linkingMethodKey = method.key);

    try {
      await _service.unlinkPaymentMethod(
        uid: widget.currentUid,
        type: method.type,
      );

      if (!mounted) {
        return;
      }
      _showSnackBar('Đã xóa liên kết thanh toán');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showSnackBar('Xóa liên kết thất bại: $error');
    } finally {
      if (mounted) {
        setState(() => _linkingMethodKey = null);
      }
    }
  }

  Future<void> _runFakeVerification({
    required String methodKey,
    required Future<void> Function() action,
  }) async {
    setState(() => _linkingMethodKey = methodKey);

    try {
      await Future<void>.delayed(const Duration(seconds: 2));
      await action();

      if (!mounted) {
        return;
      }
      _showSnackBar('Liên kết thành công');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showSnackBar('Liên kết thất bại: $error');
    } finally {
      if (mounted) {
        setState(() => _linkingMethodKey = null);
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _LinkedMethodsSection extends StatelessWidget {
  const _LinkedMethodsSection({
    required this.stream,
    required this.onDelete,
  });

  final Stream<List<PaymentMethodModel>> stream;
  final ValueChanged<PaymentMethodModel>? onDelete;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PaymentMethodModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _EmptyPanel(
            message: 'Không thể tải phương thức thanh toán.\n${snapshot.error}',
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingPanel();
        }

        final methods = snapshot.data ?? <PaymentMethodModel>[];
        if (methods.isEmpty) {
          return const _EmptyPanel(
            message: 'Bạn chưa liên kết phương thức thanh toán nào.',
          );
        }

        return Column(
          children: [
            for (var index = 0; index < methods.length; index++) ...[
              _LinkedMethodCard(
                method: methods[index],
                onDelete: onDelete == null
                    ? null
                    : () => onDelete?.call(methods[index]),
              ),
              if (index < methods.length - 1) const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }
}

class _LinkedMethodCard extends StatelessWidget {
  const _LinkedMethodCard({
    required this.method,
    required this.onDelete,
  });

  final PaymentMethodModel method;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final isMomo = method.type == PaymentMethodType.momo;

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _MethodIcon(
              icon: isMomo
                  ? Icons.account_balance_wallet_outlined
                  : Icons.credit_card_outlined,
              color: isMomo ? const Color(0xFFD82D8B) : const Color(0xFF2563EB),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(method.subtitle),
                  if (method.expiryDate.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('Hạn thẻ: ${method.expiryDate}'),
                  ],
                ],
              ),
            ),
            Column(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF16A34A)),
                const SizedBox(height: 8),
                IconButton(
                  onPressed: onDelete,
                  tooltip: 'Xóa liên kết',
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PartnerCard extends StatelessWidget {
  const _PartnerCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _MethodIcon(icon: icon, color: color),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MomoLinkDialog extends StatefulWidget {
  const _MomoLinkDialog();

  @override
  State<_MomoLinkDialog> createState() => _MomoLinkDialogState();
}

class _MomoLinkDialogState extends State<_MomoLinkDialog> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Liên kết ví MoMo'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Số điện thoại ví MoMo',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
          validator: (value) {
            final text = value?.trim() ?? '';
            if (text.isEmpty) {
              return 'Vui lòng nhập số điện thoại.';
            }
            if (text.length < 9) {
              return 'Số điện thoại không hợp lệ.';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Liên kết'),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(_phoneController.text.trim());
  }
}

class _BankLinkDialog extends StatefulWidget {
  const _BankLinkDialog();

  @override
  State<_BankLinkDialog> createState() => _BankLinkDialogState();
}

class _BankLinkDialogState extends State<_BankLinkDialog> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Liên kết thẻ ngân hàng'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _cardNumberController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Số thẻ',
                prefixIcon: Icon(Icons.credit_card_outlined),
              ),
              validator: (value) {
                final text = (value ?? '').replaceAll(' ', '');
                if (text.isEmpty) {
                  return 'Vui lòng nhập số thẻ.';
                }
                if (text.length < 12) {
                  return 'Số thẻ không hợp lệ.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _expiryController,
              keyboardType: TextInputType.datetime,
              decoration: const InputDecoration(
                labelText: 'Hạn thẻ (MM/YY)',
                prefixIcon: Icon(Icons.event_outlined),
              ),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) {
                  return 'Vui lòng nhập hạn thẻ.';
                }
                if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(text)) {
                  return 'Hạn thẻ phải có dạng MM/YY.';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Liên kết'),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      _BankCardInput(
        cardNumber: _cardNumberController.text.trim(),
        expiryDate: _expiryController.text.trim(),
      ),
    );
  }
}

class _BankCardInput {
  const _BankCardInput({
    required this.cardNumber,
    required this.expiryDate,
  });

  final String cardNumber;
  final String expiryDate;
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
      ],
    );
  }
}

class _MethodIcon extends StatelessWidget {
  const _MethodIcon({
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      width: 46,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color),
    );
  }
}

class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(message, textAlign: TextAlign.center),
    );
  }
}
