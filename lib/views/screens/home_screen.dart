import 'package:flutter/material.dart';

import '../../models/product_model.dart';
import '../../services/product_service.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/chatbot_floating_button.dart';
import '../widgets/product_image.dart';
import 'filter_screen.dart';
import 'product_detail_screen.dart';

const _backgroundColor = Color(0xFFF8F7FC);
const _surfaceColor = Color(0xFFFFFFFF);
const _primaryTextColor = Color(0xFF0B1B2E);
const _secondaryTextColor = Color(0xFF8A8F9C);
const _accentColor = Color(0xFF5D3FD3);

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static final ProductService _productService = ProductService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      floatingActionButton: const ChatbotFloatingButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 0),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              sliver: SliverToBoxAdapter(
                child: _HomeHeader(
                  onFilterTap: () => _open(context, const FilterScreen()),
                ),
              ),
            ),
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 22, 16, 0),
              sliver: SliverToBoxAdapter(child: _PromoBanner()),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 26, 0, 0),
              sliver: SliverToBoxAdapter(
                child: StreamBuilder<List<ProductModel>>(
                  stream: _productService.watchProducts(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 260,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (snapshot.hasError) {
                      return _MessagePanel(
                        message: 'Không thể tải sản phẩm.\n${snapshot.error}',
                      );
                    }

                    final products = snapshot.data ?? <ProductModel>[];
                    if (products.isEmpty) {
                      return const _MessagePanel(message: 'Chưa có sản phẩm.');
                    }

                    final popularProducts = [...products]
                      ..sort((a, b) => b.rating.compareTo(a.rating));

                    return Column(
                      children: [
                        _HorizontalProductSection(
                          title: 'Moi nhat',
                          products: products.take(8).toList(),
                        ),
                        const SizedBox(height: 28),
                        _HorizontalProductSection(
                          title: 'Noi bat',
                          products: popularProducts.take(8).toList(),
                        ),
                        const SizedBox(height: 92),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.onFilterTap,
  });

  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Tim xe, phu kien, hang xe...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            const SizedBox(width: 14),
            SizedBox.square(
              dimension: 52,
              child: IconButton.filled(
                onPressed: onFilterTap,
                icon: const Icon(Icons.tune_rounded),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 208,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5D3FD3), Color(0xFFC51162)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Transform.rotate(
              angle: -0.16,
              child: const Text(
                'AUTO',
                style: TextStyle(
                  color: Color(0x22FFFFFF),
                  fontSize: 54,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'SAN XE TOT',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tim xe mo uoc',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Text(
                'Hang ngan tin dang moi va dang tin cay',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: () {},
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _accentColor,
                  minimumSize: const Size(60, 34),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                child: const Text('Kham pha'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HorizontalProductSection extends StatelessWidget {
  const _HorizontalProductSection({
    required this.title,
    required this.products,
  });

  final String title;
  final List<ProductModel> products;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: _primaryTextColor,
                        fontSize: 24,
                      ),
                ),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: const Size(76, 34),
                ),
                child: const Text('View all'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 324,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(
                  right: index == products.length - 1 ? 16 : 0,
                ),
                child: _FigmaProductCard(product: products[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FigmaProductCard extends StatelessWidget {
  const _FigmaProductCard({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 224,
      child: Card(
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: ColoredBox(
                            color: _tileColor(product.id),
                            child: ProductImage(
                              imageUrl: product.imageUrl,
                              fit: BoxFit.cover,
                              errorWidget: const Icon(
                                Icons.image_not_supported_outlined,
                                color: _secondaryTextColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 10,
                        top: 10,
                        child: CircleAvatar(
                          radius: 13,
                          backgroundColor: const Color(0xFFEF3340),
                          child: const Icon(
                            Icons.favorite,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const Icon(Icons.star, size: 16, color: Color(0xFFFFB020)),
                    Text(
                      ' ${product.rating.toStringAsFixed(1)}',
                      style: const TextStyle(color: _secondaryTextColor),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  product.brand ?? product.categoryName ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _secondaryTextColor,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _formatCurrency(product.displayPrice),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    SizedBox.square(
                      dimension: 42,
                      child: IconButton.filled(
                        onPressed: () {},
                        style: IconButton.styleFrom(
                          backgroundColor: _accentColor,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.arrow_forward),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _tileColor(String id) {
    final colors = [
      const Color(0xFFFFF8D8),
      const Color(0xFFDDFCE5),
      const Color(0xFFFFDCA9),
      const Color(0xFFEDE2FF),
    ];
    return colors[id.hashCode.abs() % colors.length];
  }
}

class _MessagePanel extends StatelessWidget {
  const _MessagePanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
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
  return '${value.toStringAsFixed(value >= 100 ? 0 : 2)} d';
}
