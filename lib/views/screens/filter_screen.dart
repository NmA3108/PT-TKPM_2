import 'package:flutter/material.dart';

import '../../utils/currency_formatter.dart';

const _backgroundColor = Color(0xFFF5F7FB);
const _surfaceColor = Color(0xFFFFFFFF);
const _primaryTextColor = Color(0xFF111827);
const _secondaryTextColor = Color(0xFF6B7280);

class FilterScreen extends StatefulWidget {
  const FilterScreen({super.key});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  RangeValues _priceRange = const RangeValues(0, 50000000);
  String _selectedCategory = 'Fashion';
  String _selectedSize = 'M';
  String _selectedBrand = 'Nike';
  Color _selectedColor = const Color(0xFF111827);

  static const List<String> _categories = [
    'Fashion',
    'Shoes',
    'Watch',
    'Beauty',
    'Tech',
  ];

  static const List<String> _sizes = ['XS', 'S', 'M', 'L', 'XL'];
  static const List<String> _brands = ['Nike', 'Adidas', 'Zara', 'Uniqlo'];

  static const List<Color> _colors = [
    Color(0xFF111827),
    Color(0xFF2563EB),
    Color(0xFFEF4444),
    Color(0xFF14B8A6),
    Color(0xFFFFB020),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(title: const Text('Filter')),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _resetFilters,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reset'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Apply'),
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        children: [
          _FilterPanel(
            child: _PriceRangeFilter(
              values: _priceRange,
              onChanged: (values) {
                setState(() => _priceRange = values);
              },
            ),
          ),
          const SizedBox(height: 16),
          _FilterPanel(
            child: _ChipFilterSection(
              title: 'Categories',
              values: _categories,
              selectedValue: _selectedCategory,
              onSelected: (value) {
                setState(() => _selectedCategory = value);
              },
            ),
          ),
          const SizedBox(height: 16),
          _FilterPanel(
            child: _ColorFilterSection(
              colors: _colors,
              selectedColor: _selectedColor,
              onSelected: (color) {
                setState(() => _selectedColor = color);
              },
            ),
          ),
          const SizedBox(height: 16),
          _FilterPanel(
            child: _ChipFilterSection(
              title: 'Size',
              values: _sizes,
              selectedValue: _selectedSize,
              onSelected: (value) {
                setState(() => _selectedSize = value);
              },
            ),
          ),
          const SizedBox(height: 16),
          _FilterPanel(
            child: _ChipFilterSection(
              title: 'Brands',
              values: _brands,
              selectedValue: _selectedBrand,
              onSelected: (value) {
                setState(() => _selectedBrand = value);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      _priceRange = const RangeValues(0, 50000000);
      _selectedCategory = 'Fashion';
      _selectedSize = 'M';
      _selectedBrand = 'Nike';
      _selectedColor = const Color(0xFF111827);
    });
  }
}

class _FilterPanel extends StatelessWidget {
  const _FilterPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PriceRangeFilter extends StatelessWidget {
  const _PriceRangeFilter({required this.values, required this.onChanged});

  final RangeValues values;
  final ValueChanged<RangeValues> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FilterTitle(
          title: 'Price Range',
          trailing: '${formatVnd(values.start)} - ${formatVnd(values.end)}',
        ),
        const SizedBox(height: 12),
        RangeSlider(
          min: 0,
          max: 50000000,
          divisions: 100,
          values: values,
          labels: RangeLabels(
            formatVnd(values.start),
            formatVnd(values.end),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _ChipFilterSection extends StatelessWidget {
  const _ChipFilterSection({
    required this.title,
    required this.values,
    required this.selectedValue,
    required this.onSelected,
  });

  final String title;
  final List<String> values;
  final String selectedValue;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FilterTitle(title: title),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: values.map((value) {
            final selected = value == selectedValue;
            return ChoiceChip(
              label: Text(value),
              selected: selected,
              showCheckmark: true,
              onSelected: (_) => onSelected(value),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ColorFilterSection extends StatelessWidget {
  const _ColorFilterSection({
    required this.colors,
    required this.selectedColor,
    required this.onSelected,
  });

  final List<Color> colors;
  final Color selectedColor;
  final ValueChanged<Color> onSelected;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FilterTitle(title: 'Colors'),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: colors.map((color) {
            final selected = color.value == selectedColor.value;
            return Semantics(
              selected: selected,
              button: true,
              child: InkWell(
                onTap: () => onSelected(color),
                borderRadius: BorderRadius.circular(18),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  height: 44,
                  width: 44,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: selected ? primary : const Color(0xFFE5E7EB),
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: selected
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _FilterTitle extends StatelessWidget {
  const _FilterTitle({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
      ],
    );
  }
}
