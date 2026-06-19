import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/providers/auth_provider.dart';
import '../seller_features/seller_dashboard_screen.dart';
import 'account_feature_service.dart';

const _backgroundColor = Color(0xFFF5F7FB);
const _surfaceColor = Color(0xFFFFFFFF);
const _accentColor = Color(0xFFFF4D2D);

class SellerRegistrationScreen extends StatefulWidget {
  const SellerRegistrationScreen({super.key});

  @override
  State<SellerRegistrationScreen> createState() {
    return _SellerRegistrationScreenState();
  }
}

class _SellerRegistrationScreenState extends State<SellerRegistrationScreen> {
  final _service = AccountFeatureService();
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  var _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _fullNameController.text = user?.fullName ?? '';
    _phoneController.text = user?.mobileNumber ?? '';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _shopNameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final isSeller = user?.isSeller ?? false;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(title: const Text('Đăng ký bán hàng')),
      body: user == null
          ? const _MessageState(message: 'Vui lòng đăng nhập để đăng ký.')
          : isSeller
              ? _ApprovedSellerPanel(
                  onOpenSeller: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SellerDashboardScreen(),
                      ),
                    );
                  },
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  children: [
                    _InfoCard(
                      title: 'Quy trình xét duyệt',
                      content:
                          'Sau khi gửi đơn, admin sẽ xem xét thông tin của bạn. Chỉ khi đơn được duyệt, tài khoản mới có quyền truy cập các chức năng Seller.',
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _surfaceColor,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _fullNameController,
                              decoration: const InputDecoration(
                                labelText: 'Họ tên người đại diện',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: _requiredValidator,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Số điện thoại',
                                prefixIcon: Icon(Icons.phone_outlined),
                              ),
                              validator: _requiredValidator,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _shopNameController,
                              decoration: const InputDecoration(
                                labelText: 'Tên shop',
                                prefixIcon: Icon(Icons.storefront_outlined),
                              ),
                              validator: _requiredValidator,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _addressController,
                              minLines: 2,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'Địa chỉ lấy hàng',
                                prefixIcon: Icon(Icons.location_on_outlined),
                              ),
                              validator: _requiredValidator,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _descriptionController,
                              minLines: 3,
                              maxLines: 5,
                              decoration: const InputDecoration(
                                labelText: 'Mô tả sản phẩm/cửa hàng',
                                prefixIcon: Icon(Icons.description_outlined),
                              ),
                              validator: _requiredValidator,
                            ),
                            const SizedBox(height: 18),
                            FilledButton(
                              onPressed: _isSubmitting ? null : _submit,
                              style: FilledButton.styleFrom(
                                backgroundColor: _accentColor,
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Gửi đơn'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập thông tin.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = context.read<AuthProvider>().currentUser;
    if (user == null) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _service.submitSellerApplication(
        userId: user.uid,
        fullName: _fullNameController.text,
        phone: _phoneController.text,
        shopName: _shopNameController.text,
        address: _addressController.text,
        description: _descriptionController.text,
      );

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi đơn đăng ký.')),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gửi đơn thất bại: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

class _ApprovedSellerPanel extends StatelessWidget {
  const _ApprovedSellerPanel({required this.onOpenSeller});

  final VoidCallback onOpenSeller;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified, color: Color(0xFF16A34A), size: 58),
            const SizedBox(height: 14),
            const Text(
              'Tài khoản đã có quyền Seller.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: onOpenSeller,
              child: const Text('Mở kênh người bán'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.content,
  });

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: _accentColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(content),
              ],
            ),
          ),
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

