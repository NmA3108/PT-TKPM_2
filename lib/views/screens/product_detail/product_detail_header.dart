import 'package:flutter/material.dart';

import '../../../models/product_detail_model.dart';
import '../../widgets/product_image.dart';
import 'product_detail_style.dart';

class ProductDetailHeader extends StatefulWidget {
  const ProductDetailHeader({
    super.key,
    required this.product,
    required this.onBack,
  });

  final ProductDetailModel product;
  final VoidCallback onBack;

  @override
  State<ProductDetailHeader> createState() => _ProductDetailHeaderState();
}

class _ProductDetailHeaderState extends State<ProductDetailHeader> {
  var _page = 0;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final imageHeight = width > 520 ? 430.0 : width;
    final images = widget.product.imageUrls.isEmpty
        ? <String>[widget.product.imageUrl]
        : widget.product.imageUrls;

    return Container(
      color: Colors.white,
      height: imageHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            itemCount: images.length,
            onPageChanged: (value) => setState(() => _page = value),
            itemBuilder: (context, index) {
              return ProductImage(
                imageUrl: images[index],
                fit: BoxFit.contain,
                placeholder: const Center(child: CircularProgressIndicator()),
                errorWidget: const Icon(
                  Icons.image_not_supported_outlined,
                  color: ProductDetailColors.secondaryText,
                  size: 54,
                ),
              );
            },
          ),
          Positioned(
            left: 12,
            top: MediaQuery.paddingOf(context).top + 8,
            child: _HeaderButton(
              icon: Icons.arrow_back,
              onPressed: widget.onBack,
            ),
          ),
          Positioned(
            right: 18,
            bottom: 18,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${_page + 1}/${images.length}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.34),
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
      ),
    );
  }
}
