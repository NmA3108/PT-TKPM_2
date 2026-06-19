import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import 'app_asset_icon.dart';

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
  });

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 82,
        padding: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              assetName: 'home.jpg',
              label: context.tr('home'),
              isActive: currentIndex == 0,
              onTap: () => _open(context, 0),
            ),
            _NavItem(
              assetName: 'message.jpg',
              label: context.tr('message'),
              isActive: currentIndex == 1,
              onTap: () => _open(context, 1),
            ),
            _NavItem(
              assetName: 'cart.jpg',
              label: context.tr('cart'),
              isActive: currentIndex == 2,
              onTap: () => _open(context, 2),
            ),
            _NavItem(
              assetName: 'avatardefault.jpg',
              label: context.tr('me'),
              isActive: currentIndex == 3,
              onTap: () => _open(context, 3),
            ),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, int index) {
    if (index == currentIndex) {
      return;
    }

    final routeName = switch (index) {
      0 => '/home',
      1 => '/messages',
      2 => '/cart',
      3 => '/me',
      _ => '/home',
    };

    Navigator.of(context).pushReplacementNamed(routeName);
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.assetName,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String assetName;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? const Color(0xFF5D3FD3) : const Color(0xFF6B7280);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppAssetIcon(assetName: assetName, size: 23),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
