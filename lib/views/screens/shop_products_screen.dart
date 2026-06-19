import 'package:flutter/material.dart';

import '../../models/product_detail_model.dart';
import '../../services/product_detail_service.dart';
import '../../utils/currency_formatter.dart';
import '../widgets/product_image.dart';
import 'product_detail_screen.dart';

const _backgroundColor = Color(0xFFF5F5F5);
const _surfaceColor = Color(0xFFFFFFFF);
const _primaryTextColor = Color(0xFF222222);
const _secondaryTextColor = Color(0xFF777777);
const _shopColor = Color(0xFFEE4D2D);

class ShopProductsScreen extends StatefulWidget {
  const ShopProductsScreen({
    super.key,
    required this.sellerId,
    required this.shopName,
    required this.shopAvatarUrl,
  });

  final String sellerId;
  final String shopName;
  final String shopAvatarUrl;

  @override
  State<ShopProductsScreen> createState() => _ShopProductsScreenState();
}

class _ShopProductsScreenState extends State<ShopProductsScreen> {
  final _service = ProductDetailService();
  String? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(title: Text(widget.shopName)),
      body: Column(
        children: [
          _ShopHeader(
            shopName: widget.shopName,
            avatarUrl: widget.shopAvatarUrl,
          ),
          StreamBuilder<List<ShopCategoryModel>>(
            stream: _service.watchShopCategories(widget.sellerId),
            builder: (context, snapshot) {
              final categories = snapshot.data ?? const <ShopCategoryModel>[];
              return _CategoryBar(
                categories: categories,
                selectedCategoryId: _selectedCategoryId,
                onSelected: (categoryId) {
                  setState(() => _selectedCategoryId = categoryId);
                },
              );
            },
          ),
          Expanded(
            child: StreamBuilder<List<ProductDetailModel>>(
              stream: _service.watchShopProducts(widget.sellerId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _MessageState(
                    message: 'Khong the tai san pham.\n${snapshot.error}',
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final products = (snapshot.data ?? const <ProductDetailModel>[])
                    .where(_matchesSelectedCategory)
                    .toList();
                if (products.isEmpty) {
                  return const _MessageState(message: 'Shop chua co san pham.');
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.66,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    return _ShopProductCard(product: products[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _matchesSelectedCategory(ProductDetailModel product) {
    final categoryId = _selectedCategoryId;
    if (categoryId == null || categoryId.isEmpty) {
      return true;
    }
    return product.categoryId == categoryId;
  }
}

class _ShopHeader extends StatelessWidget {
  const _ShopHeader({
    required this.shopName,
    required this.avatarUrl,
  });

  final String shopName;
  final String avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _surfaceColor,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          ClipOval(
            child: SizedBox(
              height: 60,
              width: 60,
              child: ColoredBox(
                color: const Color(0xFFFFECE7),
                child: ProductImage(
                  imageUrl: avatarUrl,
                  fit: BoxFit.cover,
                  errorWidget: const Icon(
                    Icons.storefront,
                    color: _shopColor,
                    size: 30,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              shopName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _primaryTextColor,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelected,
  });

  final List<ShopCategoryModel> categories;
  final String? selectedCategoryId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: _surfaceColor,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ChoiceChip(
              label: const Text('Tat ca'),
              selected: selectedCategoryId == null,
              onSelected: (_) => onSelected(null),
            ),
            const SizedBox(width: 8),
            for (final category in categories) ...[
              ChoiceChip(
                label: Text(category.name),
                selected: selectedCategoryId == category.id,
                onSelected: (_) => onSelected(category.id),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _ShopProductCard extends StatelessWidget {
  const _ShopProductCard({required this.product});

  final ProductDetailModel product;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ProductDetailScreen(productId: product.id),
          ),
        );
      },
      child: Container(
        color: _surfaceColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ProductImage(
                imageUrl: product.imageUrl,
                width: double.infinity,
                fit: BoxFit.cover,
                errorWidget: const Icon(Icons.image_not_supported_outlined),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _primaryTextColor),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatVnd(product.price),
                    style: const TextStyle(
                      color: _shopColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.category.isEmpty ? 'Chua phan danh muc' : product.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _secondaryTextColor,
                      fontSize: 12,
                    ),
                  ),
                ],
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
