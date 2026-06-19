import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';
import '../../utils/currency_formatter.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/chatbot_floating_button.dart';
import '../widgets/product_image.dart';
import 'product_detail_screen.dart';

const _backgroundColor = Color(0xFFF8F7FC);
const _surfaceColor = Color(0xFFFFFFFF);
const _accentColor = Color(0xFF5D3FD3);
const _textColor = Color(0xFF0B1B2E);

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final _service = ProductService();
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      floatingActionButton: const ChatbotFloatingButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 1),
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        title: const Text('Danh muc xe'),
      ),
      body: StreamBuilder<List<ProductModel>>(
        stream: _service.watchProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _MessagePanel(
              message: '${context.tr('cannotLoadProducts')}\n${snapshot.error}',
            );
          }

          final products = snapshot.data ?? <ProductModel>[];
          final categories = _categoriesFrom(products);
          final selected = _selectedCategory ??
              (categories.isEmpty ? context.tr('allProducts') : categories.first);
          final visibleProducts = selected == context.tr('allProducts')
              ? products
              : products.where((product) {
                  return (product.categoryName ?? product.categoryId ?? '') ==
                      selected;
                }).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
            children: [
              SizedBox(
                height: 56,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return ChoiceChip(
                      selected: category == selected,
                      label: Text(category),
                      avatar: const Icon(Icons.category_outlined, size: 16),
                      onSelected: (_) {
                        setState(() => _selectedCategory = category);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              Text(
                selected == context.tr('allProducts') ? 'Tat ca tin dang' : selected,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: _textColor,
                      fontSize: 24,
                    ),
              ),
              const SizedBox(height: 14),
              if (visibleProducts.isEmpty)
                _MessagePanel(message: context.tr('noProducts'))
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: visibleProducts.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.62,
                  ),
                  itemBuilder: (context, index) {
                    return _CategoryProductCard(product: visibleProducts[index]);
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  List<String> _categoriesFrom(List<ProductModel> products) {
    final categories = <String>{context.tr('allProducts')};
    for (final product in products) {
      final name = product.categoryName ?? product.categoryId;
      if (name != null && name.trim().isNotEmpty) {
        categories.add(name);
      }
    }
    return categories.toList();
  }
}

class _CategoryProductCard extends StatelessWidget {
  const _CategoryProductCard({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _surfaceColor,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ProductDetailScreen(productId: product.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: ColoredBox(
                    color: const Color(0xFFF7F7F7),
                    child: ProductImage(
                      imageUrl: product.imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorWidget: const Icon(
                        Icons.image_not_supported_outlined,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                _formatCurrency(product.displayPrice),
                style: const TextStyle(
                  color: _accentColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessagePanel extends StatelessWidget {
  const _MessagePanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(message, textAlign: TextAlign.center),
    );
  }
}

String _formatCurrency(double value) {
  return formatVnd(value);
}
