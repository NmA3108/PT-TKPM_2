import 'package:flutter/material.dart';

import '../../../utils/currency_formatter.dart';
import 'product_detail_style.dart';

class ProductDetailBottomBar extends StatelessWidget {
  const ProductDetailBottomBar({
    super.key,
    required this.price,
    required this.isBusy,
    required this.onChat,
    required this.onAddToCart,
    required this.onBuyNow,
  });

  final double price;
  final bool isBusy;
  final VoidCallback onChat;
  final VoidCallback onAddToCart;
  final VoidCallback onBuyNow;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 64,
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x16000000),
              blurRadius: 10,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _ActionButton(
                color: ProductDetailColors.teal,
                icon: Icons.chat_outlined, 
                label: 'Chat ngay',
                onPressed: isBusy ? null : onChat,
              ),
            ),
            Expanded(
              child: _ActionButton(
                color: ProductDetailColors.teal,
                icon: Icons.add_shopping_cart,
                label: 'Thêm vào giỏ',
                onPressed: isBusy ? null : onAddToCart,
              ),
            ),
            Expanded(
              flex: 2,
              child: Material(
                color: ProductDetailColors.accent,
                child: InkWell(
                  onTap: isBusy ? null : onBuyNow,
                  child: Center(
                    child: isBusy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Mua ngay\n${formatVnd(price)}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              height: 1.2,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.color,
    required this.icon, // Đổi từ String assetName sang IconData icon
    required this.label,
    required this.onPressed,
  });

  final Color color;
  final IconData icon; // Đổi kiểu dữ liệu dữ liệu thành IconData
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: color,
        shape: const RoundedRectangleBorder(),
        minimumSize: const Size(0, 64),
        padding: EdgeInsets.zero,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon, 
            size: 23, 
            color: Colors.white, // Thiết lập màu cho Icon trùng màu chữ
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11), // Thu nhỏ chữ lại một chút để tránh tràn hàng khi dùng Icon
          ),
        ],
      ),
    );
  }
}