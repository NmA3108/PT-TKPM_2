import 'package:flutter/material.dart';

import '../../../models/product_detail_model.dart';
import 'product_detail_header.dart';
import 'product_detail_options.dart';
import 'product_detail_sections.dart';

class ProductDetailBody extends StatelessWidget {
  const ProductDetailBody({
    super.key,
    required this.product,
    required this.quantity,
    required this.selectedColor,
    required this.selectedClassification,
    required this.selectedSize,
    required this.onBack,
    required this.cartCount,
    required this.onCartTap,
    required this.onMoreTap,
    required this.onOpenShop,
    required this.onColorSelected,
    required this.onClassificationSelected,
    required this.onSizeSelected,
    required this.onDecreaseQuantity,
    required this.onIncreaseQuantity,
  });

  final ProductDetailModel product;
  final int quantity;
  final String selectedColor;
  final String selectedClassification;
  final String selectedSize;
  final VoidCallback onBack;
  final int cartCount;
  final VoidCallback onCartTap;
  final VoidCallback onMoreTap;
  final VoidCallback onOpenShop;
  final ValueChanged<String> onColorSelected;
  final ValueChanged<String> onClassificationSelected;
  final ValueChanged<String> onSizeSelected;
  final VoidCallback onDecreaseQuantity;
  final VoidCallback onIncreaseQuantity;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProductDetailHeader(
              product: product,
              cartCount: cartCount,
              onBack: onBack,
              onCartTap: onCartTap,
              onMoreTap: onMoreTap,
            ),
            ProductInfoSection(product: product),
            ProductOptionsSection(
              product: product,
              quantity: quantity,
              selectedColor: selectedColor,
              selectedClassification: selectedClassification,
              selectedSize: selectedSize,
              onColorSelected: onColorSelected,
              onClassificationSelected: onClassificationSelected,
              onSizeSelected: onSizeSelected,
              onDecreaseQuantity: onDecreaseQuantity,
              onIncreaseQuantity: onIncreaseQuantity,
            ),
            ProductShopSection(product: product, onOpenShop: onOpenShop),
            ProductShippingSection(),
            ProductPolicySection(),
            ProductDescriptionSection(product: product),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}
