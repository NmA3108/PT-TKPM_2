import 'package:flutter/material.dart';

import '../../../models/product_detail_model.dart';
import '../../../utils/currency_formatter.dart';
import 'product_detail_style.dart';

class ProductInfoSection extends StatelessWidget {
  const ProductInfoSection({
    super.key,
    required this.product,
  });

  final ProductDetailModel product;

  @override
  Widget build(BuildContext context) {
    return ProductDetailSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formatVnd(product.price),
            style: const TextStyle(
              color: ProductDetailColors.accent,
              fontSize: 30,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            product.name,
            style: const TextStyle(
              color: ProductDetailColors.primaryText,
              fontSize: 19,
              fontWeight: FontWeight.w500,
              height: 1.18,
            ),
          ),
        ],
      ),
    );
  }
}

class ProductShippingSection extends StatelessWidget {
  const ProductShippingSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const _InfoRow(
      icon: Icons.local_shipping_outlined,
      iconColor: Color(0xFF3BA99C),
      title: 'Giao hang',
      subtitle: 'Phi ship va thoi gian giao hang se hien thi khi thanh toan.',
    );
  }
}

class ProductPolicySection extends StatelessWidget {
  const ProductPolicySection({super.key});

  @override
  Widget build(BuildContext context) {
    return const _InfoRow(
      icon: Icons.verified_user_outlined,
      iconColor: ProductDetailColors.accent,
      title: 'Chinh sach',
      subtitle: 'Tra hang mien phi 15 ngay neu san pham co van de.',
    );
  }
}

class ProductDescriptionSection extends StatelessWidget {
  const ProductDescriptionSection({
    super.key,
    required this.product,
  });

  final ProductDetailModel product;

  @override
  Widget build(BuildContext context) {
    return ProductDetailSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mo ta san pham',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Text(
            product.description.trim().isEmpty
                ? 'San pham chua co mo ta chi tiet.'
                : product.description.trim(),
            style: const TextStyle(
              color: ProductDetailColors.primaryText,
              fontSize: 15,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ProductDetailSection(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: ProductDetailColors.primaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: ProductDetailColors.secondaryText,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
