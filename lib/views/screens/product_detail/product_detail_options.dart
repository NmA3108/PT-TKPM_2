import 'package:flutter/material.dart';

import '../../../models/product_detail_model.dart';
import 'product_detail_style.dart';

class ProductOptionsSection extends StatelessWidget {
  const ProductOptionsSection({
    super.key,
    required this.product,
    required this.quantity,
    required this.selectedColor,
    required this.selectedClassification,
    required this.selectedSize,
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
  final ValueChanged<String> onColorSelected;
  final ValueChanged<String> onClassificationSelected;
  final ValueChanged<String> onSizeSelected;
  final VoidCallback onDecreaseQuantity;
  final VoidCallback onIncreaseQuantity;

  @override
  Widget build(BuildContext context) {
    final colors = visibleColors(product);
    final sizes = visibleSizes(product);

    return ProductDetailSection(
      child: Column(
        children: [
          if (product.classifications.isNotEmpty) ...[
            _OptionRow(
              label: 'Phân loại',
              child: _OptionChips(
                values: product.classifications,
                selectedValue: selectedClassification,
                onSelected: onClassificationSelected,
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (colors.isNotEmpty) ...[
            _OptionRow(
              label: 'Màu sắc',
              child: _OptionChips(
                values: colors,
                selectedValue: selectedColor,
                onSelected: onColorSelected,
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (sizes.isNotEmpty) ...[
            _OptionRow(
              label: 'Kích cỡ',
              child: _OptionChips(
                values: sizes,
                selectedValue: selectedSize,
                onSelected: onSizeSelected,
              ),
            ),
            const SizedBox(height: 12),
          ],
          _OptionRow(
            label: 'Số lượng',
            child: _QuantityControl(
              quantity: quantity,
              canDecrease: quantity > 1,
              canIncrease: quantity < product.stockQuantity,
              onDecrease: onDecreaseQuantity,
              onIncrease: onIncreaseQuantity,
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: const TextStyle(
              color: ProductDetailColors.secondaryText,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _OptionChips extends StatelessWidget {
  const _OptionChips({
    required this.values,
    required this.selectedValue,
    required this.onSelected,
  });

  final List<String> values;
  final String selectedValue;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final value in values)
          ChoiceChip(
            label: Text(value),
            selected: value == selectedValue,
            onSelected: (_) => onSelected(value),
            selectedColor: const Color(0xFFFFECE7),
            backgroundColor: Colors.white,
            showCheckmark: false,
            side: BorderSide(
              color: value == selectedValue
                  ? ProductDetailColors.accent
                  : ProductDetailColors.border,
            ),
            labelStyle: TextStyle(
              color: value == selectedValue
                  ? ProductDetailColors.accent
                  : ProductDetailColors.primaryText,
            ),
          ),
      ],
    );
  }
}

class _QuantityControl extends StatelessWidget {
  const _QuantityControl({
    required this.quantity,
    required this.canDecrease,
    required this.canIncrease,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int quantity;
  final bool canDecrease;
  final bool canIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _QuantityButton(
          icon: Icons.remove,
          enabled: canDecrease,
          onTap: onDecrease,
        ),
        Container(
          width: 42,
          height: 32,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            border: Border.symmetric(
              horizontal: BorderSide(color: ProductDetailColors.border),
            ),
          ),
          child: Text('$quantity'),
        ),
        _QuantityButton(
          icon: Icons.add,
          enabled: canIncrease,
          onTap: onIncrease,
        ),
      ],
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 34,
        height: 32,
        decoration: BoxDecoration(
          border: Border.all(color: ProductDetailColors.border),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled
              ? ProductDetailColors.primaryText
              : const Color(0xFFC9C9C9),
        ),
      ),
    );
  }
}
