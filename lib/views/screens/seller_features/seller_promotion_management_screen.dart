import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/providers/auth_provider.dart';
import '../../../utils/currency_formatter.dart';
import 'seller_feature_service.dart';

const _backgroundColor = Color(0xFFF5F7FB);
const _surfaceColor = Color(0xFFFFFFFF);

class SellerPromotionManagementScreen extends StatefulWidget {
  const SellerPromotionManagementScreen({super.key});

  @override
  State<SellerPromotionManagementScreen> createState() {
    return _SellerPromotionManagementScreenState();
  }
}

class _SellerPromotionManagementScreenState
    extends State<SellerPromotionManagementScreen> {
  final _service = SellerFeatureService();

  @override
  Widget build(BuildContext context) {
    final sellerId = context.watch<AuthProvider>().currentUser?.uid;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(title: const Text('Quản lý khuyến mãi')),
      floatingActionButton: sellerId == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openPromotionForm(sellerId),
              icon: const Icon(Icons.add),
              label: const Text('Tạo khuyến mãi'),
            ),
      body: sellerId == null
          ? const _MessageState(message: 'Vui lòng đăng nhập.')
          : StreamBuilder<List<SellerPromotionModel>>(
              stream: _service.watchPromotions(sellerId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _MessageState(
                    message: 'Không thể tải khuyến mãi.\n${snapshot.error}',
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final promotions = snapshot.data ?? const <SellerPromotionModel>[];
                if (promotions.isEmpty) {
                  return const _MessageState(message: 'Chưa có khuyến mãi.');
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: promotions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final promotion = promotions[index];
                    return _PromotionCard(
                      promotion: promotion,
                      onToggle: () => _togglePromotion(sellerId, promotion),
                    );
                  },
                );
              },
            ),
    );
  }

  Future<void> _openPromotionForm(String sellerId) async {
    final result = await showModalBottomSheet<_PromotionFormResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const _PromotionFormSheet(),
    );

    if (result == null) {
      return;
    }

    try {
      await _service.createPromotion(
        sellerId: sellerId,
        code: result.code,
        title: result.title,
        discountType: result.discountType,
        discountValue: result.discountValue,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã tạo khuyến mãi.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tạo khuyến mãi thất bại: $error')),
      );
    }
  }

  Future<void> _togglePromotion(
    String sellerId,
    SellerPromotionModel promotion,
  ) async {
    try {
      await _service.togglePromotion(
        sellerId: sellerId,
        promotion: promotion,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cập nhật thất bại: $error')),
      );
    }
  }
}

class _PromotionCard extends StatelessWidget {
  const _PromotionCard({
    required this.promotion,
    required this.onToggle,
  });

  final SellerPromotionModel promotion;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final value = promotion.discountType == 'percent'
        ? promotion.discountLabel
        : formatVnd(promotion.discountValue);

    return Card(
      color: _surfaceColor,
      elevation: 0,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: const Icon(Icons.local_offer_outlined),
        ),
        title: Text(promotion.title.isEmpty ? promotion.code : promotion.title),
        subtitle: Text('${promotion.code} - Giảm $value'),
        trailing: Switch(
          value: promotion.isActive,
          onChanged: (_) => onToggle(),
        ),
      ),
    );
  }
}

class _PromotionFormSheet extends StatefulWidget {
  const _PromotionFormSheet();

  @override
  State<_PromotionFormSheet> createState() => _PromotionFormSheetState();
}

class _PromotionFormSheetState extends State<_PromotionFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _titleController = TextEditingController();
  final _valueController = TextEditingController();
  String _discountType = 'percent';

  @override
  void dispose() {
    _codeController.dispose();
    _titleController.dispose();
    _valueController.dispose();
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
              Text('Tạo Voucher', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(labelText: 'Nhập mã'),
                textCapitalization: TextCapitalization.characters,
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Tên chương trình'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'percent', label: Text('%')),
                  ButtonSegment(value: 'amount', label: Text('Số tiền')),
                ],
                selected: {_discountType},
                onSelectionChanged: (value) {
                  setState(() => _discountType = value.first);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _valueController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: _discountType == 'percent'
                      ? 'Giá trị (%)'
                      : 'Giá trị (VND)',
                ),
                validator: _number,
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _submit,
                child: const Text('Lưu khuyến mãi'),
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
      _PromotionFormResult(
        code: _codeController.text.trim(),
        title: _titleController.text.trim(),
        discountType: _discountType,
        discountValue: double.parse(_valueController.text.trim()),
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập thông tin.';
    }
    return null;
  }

  String? _number(String? value) {
    final error = _required(value);
    if (error != null) return error;
    final number = double.tryParse(value!.trim());
    if (number == null || number <= 0) {
      return 'Giá trị không hợp lệ.';
    }
    if (_discountType == 'percent' && number > 100) {
      return 'Phần trăm không được vượt quá 100.';
    }
    return null;
  }
}

class _PromotionFormResult {
  const _PromotionFormResult({
    required this.code,
    required this.title,
    required this.discountType,
    required this.discountValue,
  });

  final String code;
  final String title;
  final String discountType;
  final double discountValue;
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
