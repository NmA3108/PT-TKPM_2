import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.errorWidget,
    this.placeholder,
  });

  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? errorWidget;
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    final source = imageUrl.trim();
    if (source.startsWith('data:image')) {
      return _MemoryDataImage(
        dataUrl: source,
        fit: fit,
        width: width,
        height: height,
        errorWidget: errorWidget,
      );
    }

    if (source.isEmpty) {
      return errorWidget ?? const Icon(Icons.image_not_supported_outlined);
    }

    return CachedNetworkImage(
      imageUrl: source,
      width: width,
      height: height,
      fit: fit,
      placeholder: placeholder == null ? null : (_, __) => placeholder!,
      errorWidget: (_, __, ___) {
        return errorWidget ?? const Icon(Icons.image_not_supported_outlined);
      },
    );
  }
}

class _MemoryDataImage extends StatelessWidget {
  const _MemoryDataImage({
    required this.dataUrl,
    required this.fit,
    required this.width,
    required this.height,
    required this.errorWidget,
  });

  final String dataUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? errorWidget;

  @override
  Widget build(BuildContext context) {
    try {
      final commaIndex = dataUrl.indexOf(',');
      if (commaIndex == -1) {
        return errorWidget ?? const Icon(Icons.image_not_supported_outlined);
      }

      final bytes = base64Decode(dataUrl.substring(commaIndex + 1));
      return Image.memory(
        Uint8List.fromList(bytes),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) {
          return errorWidget ?? const Icon(Icons.image_not_supported_outlined);
        },
      );
    } catch (_) {
      return errorWidget ?? const Icon(Icons.image_not_supported_outlined);
    }
  }
}
