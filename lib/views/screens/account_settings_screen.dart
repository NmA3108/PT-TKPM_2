import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/providers/auth_provider.dart';
import '../../models/app_user.dart';
import '../widgets/bottom_nav_bar.dart';
import 'account_features/messages_screen.dart';
import 'account_features/order_history_screen.dart';
import 'account_features/seller_registration_screen.dart';
import 'address_settings_screen.dart';
import 'chatbot_screen.dart';
import 'edit_profile_screen.dart';
import 'payment_methods_screen.dart';

const _backgroundColor = Color(0xFFF5F7FB);
const _surfaceColor = Color(0xFFFFFFFF);
const _dangerColor = Color(0xFFEF4444);

class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: _backgroundColor,
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 3),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _AccountHero(user: user),
          const SizedBox(height: 12),
          _PurchaseSection(
            onHistoryTap: () => _open(context, const OrderHistoryScreen()),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _SettingsSection(
              title: 'Tai khoan cua toi',
              children: [
                _AccountSettingsTile(
                  icon: Icons.person_outline,
                  title: 'Hồ sơ của tôi',
                  subtitle: user?.displayName ?? 'Cap nhat ten va Email',
                  onTap: user == null
                      ? null
                      : () => _open(
                            context,
                            EditProfileScreen(currentUid: user.uid),
                          ),
                ),
                _AccountSettingsTile(
                  icon: Icons.location_on_outlined,
                  title: 'Địa chỉ',
                  subtitle: user?.deliveryAddress.isEmpty ?? true
                      ? 'Thêm địa chỉ nhận hàng'
                      : user!.deliveryAddress,
                  onTap: user == null
                      ? null
                      : () => _open(
                            context,
                            AddressSettingsScreen(currentUid: user.uid),
                          ),
                ),
                _AccountSettingsTile(
                  icon: Icons.credit_card_outlined,
                  title: 'Tài khoản thanh toán',
                  subtitle: user?.paymentAccount.isEmpty ?? true
                      ? 'Thêm thông tin thanh toán'
                      : user!.paymentAccount,
                  onTap: user == null
                      ? null
                      : () => _open(
                            context,
                            PaymentMethodsScreen(currentUid: user.uid),
                          ),
                ),
                _AccountSettingsTile(
                  icon: Icons.lock_outline,
                  title: 'Đổi mật khẩu',
                  subtitle: 'Cập nhật mật khẩu đăng nhập',
                  onTap: user == null
                      ? null
                      : () => _open(context, const _ChangePasswordScreen()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _SettingsSection(
              title: 'Tiện ích khác',
              children: [
                _AccountSettingsTile(
                  icon: Icons.storefront_outlined,
                  title: 'Đăng ký bán hàng',
                  subtitle: 'Mở kênh người bán và quản lý sản phẩm',
                  onTap: user == null
                      ? null
                      : () => _open(context, const SellerRegistrationScreen()),
                ),
                _AccountSettingsTile(
                  icon: Icons.favorite_border,
                  title: 'Sản phẩm yêu thích',
                  subtitle: 'Xem lại danh sách wishlist',
                  onTap: () => _showMessage(context, 'Chức năng đang phát triển.'),
                ),
                _AccountSettingsTile(
                  icon: Icons.local_offer_outlined,
                  title: 'Kho voucher',
                  subtitle: 'Quản lý voucher và ưu đãi',
                  onTap: () => _showMessage(context, 'Chức năng đang phát triển.'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _SettingsSection(
              title: 'Hỗ trợ',
              children: [
                _AccountSettingsTile(
                  icon: Icons.support_agent_outlined,
                  title: 'Trung tâm hỗ trợ',
                  subtitle: 'Hỏi đáp và hướng dẫn sử dụng',
                  onTap: () => _open(context, const ChatbotScreen()),
                ),
                _AccountSettingsTile(
                  icon: Icons.chat_bubble_outline,
                  title: 'Tin nhắn',
                  subtitle: 'Danh sách seller đã từng nhận tin',
                  onTap: () => _open(context, const MessagesScreen()),
                ),

              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _SettingsSection(
              children: [
                _AccountSettingsTile(
                  icon: Icons.logout,
                  title: 'Đăng xuất',
                  subtitle: 'Quay lại màn hình đăng nhập',
                  onTap: () => _confirmLogout(context),
                ),
                _AccountSettingsTile(
                  icon: Icons.delete_forever_outlined,
                  title: 'Xóa tài khoản',
                  subtitle: 'Vô hiệu hóa tài khoản này',
                  iconColor: _dangerColor,
                  titleColor: _dangerColor,
                  onTap: user == null ? null : () => _confirmDelete(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout'),
        content: const Text('Do you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    context.read<AuthProvider>().logout();
    Navigator.of(context).pop();
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete account'),
        content: const Text('This account will be disabled. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _dangerColor),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.deleteAccount();

    if (!context.mounted) {
      return;
    }

    if (success) {
      Navigator.of(context).pop();
    } else {
      _showMessage(context, authProvider.errorMessage ?? 'Delete failed.');
    }
  }
}

class _AccountSummary extends StatelessWidget {
  const _AccountSummary({required this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    final displayName = user?.displayName ?? 'Customer000';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            foregroundColor: Theme.of(context).colorScheme.primary,
            child: Text(displayName.characters.first.toUpperCase()),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.mobileNumber ?? 'Not signed in',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (user?.email.isNotEmpty == true)
                  Text(user!.email, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountHero extends StatelessWidget {
  const _AccountHero({required this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    final name = user?.displayName ?? user?.mobileNumber ?? 'Guest';

    return Container(
      padding: EdgeInsets.fromLTRB(
        18,
        MediaQuery.of(context).padding.top + 18,
        18,
        24,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF4D2D), Color(0xFFFF7A3D)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white.withOpacity(0.92),
            child: const Icon(Icons.person, color: Color(0xFFFF4D2D), size: 38),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),

          IconButton(
            tooltip: 'Tin nhắn',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ChatbotScreen()),
            ),
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 30),
          ),
        ],
      ),
    );
  }
}

class _PurchaseSection extends StatelessWidget {
  const _PurchaseSection({required this.onHistoryTap});

  final VoidCallback onHistoryTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x120F172A),
              blurRadius: 24,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Don mua',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onHistoryTap,
                    icon: const Icon(Icons.history),
                    label: const Text('Lịch sử mua hàng'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _PurchaseAction(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Chờ xác nhận',
                  ),
                  _PurchaseAction(
                    icon: Icons.inventory_2_outlined,
                    label: 'Chờ lấy hàng',
                  ),
                  _PurchaseAction(
                    icon: Icons.local_shipping_outlined,
                    label: 'Đang giao hàng',
                  ),
                  _PurchaseAction(
                    icon: Icons.star_border_rounded,
                    label: 'Đánh giá',
                    badge: '3',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PurchaseAction extends StatelessWidget {
  const _PurchaseAction({
    required this.icon,
    required this.label,
    this.badge,
  });

  final IconData icon;
  final String label;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 82,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, size: 36, color: const Color(0xFF111827)),
              if (badge != null)
                Positioned(
                  right: -10,
                  top: -10,
                  child: Container(
                    height: 24,
                    constraints: const BoxConstraints(minWidth: 24),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4D2D),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ChangePasswordScreen extends StatefulWidget {
  const _ChangePasswordScreen();

  @override
  State<_ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<_ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _hideCurrent = true;
  bool _hideNew = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _FormScaffold(
      title: 'Change password',
      formKey: _formKey,
      onSave: _save,
      children: [
        TextFormField(
          controller: _currentPasswordController,
          obscureText: _hideCurrent,
          decoration: InputDecoration(
            labelText: 'Current password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              onPressed: () => setState(() => _hideCurrent = !_hideCurrent),
              icon: Icon(
                _hideCurrent
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
          validator: _validatePassword,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _newPasswordController,
          obscureText: _hideNew,
          decoration: InputDecoration(
            labelText: 'New password',
            prefixIcon: const Icon(Icons.lock_reset_outlined),
            suffixIcon: IconButton(
              onPressed: () => setState(() => _hideNew = !_hideNew),
              icon: Icon(
                _hideNew
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
          validator: _validatePassword,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _hideNew,
          decoration: const InputDecoration(
            labelText: 'Confirm new password',
            prefixIcon: Icon(Icons.verified_user_outlined),
          ),
          validator: (value) => value != _newPasswordController.text
              ? 'Passwords do not match.'
              : null,
        ),
      ],
    );
  }

  String? _validatePassword(String? value) {
    if (value == null || value.length < 6) {
      return 'Password must have at least 6 characters.';
    }
    return null;
  }

  Future<bool> _save() {
    return context.read<AuthProvider>().changePassword(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
    );
  }
}

class _FormScaffold extends StatelessWidget {
  const _FormScaffold({
    required this.title,
    required this.formKey,
    required this.children,
    required this.onSave,
  });

  final String title;
  final GlobalKey<FormState> formKey;
  final List<Widget> children;
  final Future<bool> Function() onSave;

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(title),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x120F172A),
                        blurRadius: 24,
                        offset: Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Column(children: children),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: isLoading ? null : () => _submit(context),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: isLoading
                        ? const SizedBox(
                            key: ValueKey('loading'),
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(key: ValueKey('label'), 'Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await onSave();

    if (!context.mounted) {
      return;
    }

    if (success) {
      _showMessage(context, 'Saved successfully.');
      Navigator.of(context).pop();
    } else {
      _showMessage(context, authProvider.errorMessage ?? 'Save failed.');
    }
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.children,
    this.title,
  });

  final List<Widget> children;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              title!,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
          ),
        ],
        DecoratedBox(
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x120F172A),
                blurRadius: 24,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }
}

class _AccountSettingsTile extends StatelessWidget {
  const _AccountSettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.iconColor,
    this.titleColor,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      enabled: onTap != null,
      minLeadingWidth: 28,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      leading: Container(
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          color: (iconColor ?? Theme.of(context).colorScheme.primary)
              .withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          color: iconColor ?? Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: titleColor,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
    );
  }
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
