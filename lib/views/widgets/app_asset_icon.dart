import 'package:flutter/material.dart';

class AppAssetIcon extends StatelessWidget {
  const AppAssetIcon({
    super.key,
    required this.assetName,
    this.size = 24,
    this.color,
  });

  final String assetName;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/imgs/$assetName',
      width: size,
      height: size,
      fit: BoxFit.contain,
      color: color,
      colorBlendMode: color == null ? null : BlendMode.srcIn,
      errorBuilder: (_, __, ___) {
        return SizedBox(width: size, height: size);
      },
    );
  }
}
