import 'package:flutter/material.dart';

import '../../../models/product_detail_model.dart';

class ProductDetailColors {
  const ProductDetailColors._();

  static const background = Color(0xFFF5F5F5);
  static const surface = Color(0xFFFFFFFF);
  static const primaryText = Color(0xFF222222);
  static const secondaryText = Color(0xFF777777);
  static const accent = Color(0xFFEE4D2D);
  static const teal = Color(0xFF4DB6A6);
  static const border = Color(0xFFE5E5E5);
}

class ProductDetailSection extends StatelessWidget {
  const ProductDetailSection({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      color: ProductDetailColors.surface,
      child: child,
    );
  }
}

List<String> visibleColors(ProductDetailModel product) {
  return product.colors.where((value) {
    return value.trim().toLowerCase() != 'mac dinh';
  }).toList();
}

List<String> visibleSizes(ProductDetailModel product) {
  return product.sizes.where((value) {
    return value.trim().toLowerCase() != 'free size';
  }).toList();
}
