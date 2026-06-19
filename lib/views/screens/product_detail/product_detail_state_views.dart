import 'package:flutter/material.dart';

import 'product_detail_style.dart';

class ProductDetailLoading extends StatelessWidget {
  const ProductDetailLoading({
    super.key,
    required this.onBack,
  });

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProductDetailColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            const Center(child: CircularProgressIndicator()),
            Positioned(
              left: 12,
              top: 8,
              child: _BackButton(onBack: onBack),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductDetailMessage extends StatelessWidget {
  const ProductDetailMessage({
    super.key,
    required this.message,
    required this.onBack,
  });

  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProductDetailColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: ProductDetailColors.primaryText,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              top: 8,
              child: _BackButton(onBack: onBack),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.34),
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: onBack,
        icon: const Icon(Icons.arrow_back, color: Colors.white),
      ),
    );
  }
}
