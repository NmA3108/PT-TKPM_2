import 'package:flutter/material.dart';

import '../../../models/product_detail_model.dart';
import '../../../utils/currency_formatter.dart';
import '../../widgets/app_asset_icon.dart';
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
      title: '21 Th06 - 24 Th06',
      subtitle: 'Tặng Voucher Freeship nếu giao sau thời gian trên.',
    );
  }
}

class ProductShopSection extends StatelessWidget {
  const ProductShopSection({
    super.key,
    required this.product,
    required this.onOpenShop,
  });

  final ProductDetailModel product;
  final VoidCallback onOpenShop;

  @override
  Widget build(BuildContext context) {
    final shopName = _shopName(product);

    return ProductDetailSection(
      child: InkWell(
        onTap: onOpenShop,
        child: Row(
          children: [
            const AppAssetIcon(
              assetName: 'category_icon.jpg',
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Shop',
                    style: TextStyle(
                      color: ProductDetailColors.secondaryText,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    shopName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ProductDetailColors.primaryText,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }

  String _shopName(ProductDetailModel product) {
    if (product.shopName.trim().isNotEmpty) {
      return product.shopName.trim();
    }
    final sellerId = product.sellerId.trim().isNotEmpty
        ? product.sellerId.trim()
        : product.shopId.trim();
    final digits = (sellerId.hashCode.abs() % 1000).toString().padLeft(3, '0');
    return 'Seller$digits';
  }
}

class ProductPolicySection extends StatelessWidget {
  const ProductPolicySection({super.key});

  @override
  Widget build(BuildContext context) {
    return const _InfoRow(
      icon: Icons.verified_user_outlined,
      iconColor: ProductDetailColors.accent,
      title: 'Chính sách',
      subtitle: 'Trả hàng miễn phí 15 ngày nếu sản phẩm có vấn đề.',
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
            'Mô tả sản phẩm',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Text(
            product.description.trim().isEmpty
                ? 'Sản phẩm chưa có mô tả chi tiết.'
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
