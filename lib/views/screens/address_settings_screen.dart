import 'package:flutter/material.dart';

import '../../models/user_account_models.dart';
import '../../services/user_account_service.dart';

class AddressSettingsScreen extends StatefulWidget {
  const AddressSettingsScreen({
    super.key,
    required this.currentUid,
  });

  final String currentUid;

  @override
  State<AddressSettingsScreen> createState() => _AddressSettingsScreenState();
}

class _AddressSettingsScreenState extends State<AddressSettingsScreen> {
  final _service = UserAccountService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      appBar: AppBar(
        title: const Text('Thiết lập địa chỉ'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF7F7F8),
      ),
      body: StreamBuilder<List<UserAddressModel>>(
        stream: _service.watchAddresses(widget.currentUid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _MessageState(
              message: 'Không thể tải địa chỉ.\n${snapshot.error}',
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final addresses = snapshot.data ?? <UserAddressModel>[];
          if (addresses.isEmpty) {
            return const _MessageState(
              message: 'Bạn chưa có địa chỉ nhận hàng.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: addresses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final address = addresses[index];
              return _AddressCard(
                address: address,
                onDelete: () => _deleteAddress(address),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddAddressSheet,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Thêm địa chỉ mới'),
      ),
    );
  }

  Future<void> _openAddAddressSheet() async {
    final result = await showModalBottomSheet<UserAddressModel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _AddAddressSheet(),
    );

    if (result == null) {
      return;
    }

    try {
      await _service.addAddress(uid: widget.currentUid, address: result);
      if (!mounted) {
        return;
      }
      _showSnackBar('Thêm địa chỉ thành công.');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showSnackBar('Thêm địa chỉ thất bại: $error');
    }
  }

  Future<void> _deleteAddress(UserAddressModel address) async {
    try {
      await _service.deleteAddress(
        uid: widget.currentUid,
        addressId: address.id,
      );
      if (!mounted) {
        return;
      }
      _showSnackBar('Đã xóa địa chỉ.');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showSnackBar('Xóa địa chỉ thất bại: $error');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.onDelete,
  });

  final UserAddressModel address;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onLongPress: onDelete,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.location_on_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      address.receiverName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(address.phoneNumber),
                    const SizedBox(height: 6),
                    Text(
                      address.detailAddress,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.black54,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                tooltip: 'Xóa địa chỉ',
                icon: const Icon(Icons.delete_outline, color: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddAddressSheet extends StatefulWidget {
  const _AddAddressSheet();

  @override
  State<_AddAddressSheet> createState() => _AddAddressSheetState();
}

class _AddAddressSheetState extends State<_AddAddressSheet> {
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
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Thêm địa chỉ mới',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _receiverController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Tên người nhận',
                border: OutlineInputBorder(),
              ),
              validator: _requiredValidator,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Số điện thoại',
                border: OutlineInputBorder(),
              ),
              validator: _requiredValidator,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _addressController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Địa chỉ chi tiết',
                border: OutlineInputBorder(),
              ),
              validator: _requiredValidator,
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _submit,
              child: const Text('Lưu địa chỉ'),
            ),
          ],
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

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập thông tin.';
    }
    return null;
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
