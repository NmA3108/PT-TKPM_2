import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/product_model.dart';
import '../../services/product_service.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/chatbot_floating_button.dart';
import 'account_settings_screen.dart';
import 'cart_screen.dart';
import 'filter_screen.dart';
import 'product_detail_screen.dart';

const _backgroundColor = Color(0xFFEFFBFF);
const _surfaceColor = Color(0xFFFFFFFF);
const _primaryTextColor = Color(0xFF0B1B2E);
const _secondaryTextColor = Color(0xFF8A8F9C);
const _accentColor = Color(0xFF347DFF);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _productService = ProductService();
  final _searchController = TextEditingController();
  var _showSearch = false;
  var _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      floatingActionButton: const ChatbotFloatingButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 0),
      body: SafeArea(
        child: StreamBuilder<List<ProductModel>>(
          stream: _productService.watchProducts(),
          builder: (context, snapshot) {
            final products = snapshot.data ?? <ProductModel>[];
            final searchResults = _searchProducts(products);
            final isSearching = _query.trim().isNotEmpty;
            final canFilter = isSearching && searchResults.isNotEmpty;

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: _HomeHeader(
                      showSearch: _showSearch,
                      controller: _searchController,
                      canFilter: canFilter,
                      onSearchToggle: () {
                        setState(() => _showSearch = !_showSearch);
                      },
                      onSearchChanged: (value) {
                        setState(() => _query = value);
                      },
                      onClearSearch: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                      onFilterTap: canFilter
                          ? () => _open(context, const FilterScreen())
                          : null,
                      onAccountTap: () {
                        _open(context, const AccountSettingsScreen());
                      },
                      onCartTap: () => _open(context, const CartScreen()),
                    ),
                  ),
                ),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (snapshot.hasError)
                  SliverFillRemaining(
                    child: _MessagePanel(
                      message: 'Không thể tải sản phẩm.\n${snapshot.error}',
                    ),
                  )
                else if (isSearching)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
                    sliver: SliverToBoxAdapter(
                      child: _SearchResults(
                        query: _query,
                        products: searchResults,
                      ),
                    ),
                  )
                else ...[
                  const SliverPadding(
                    padding: EdgeInsets.fromLTRB(16, 28, 16, 0),
                    sliver: SliverToBoxAdapter(child: _PromoBanner()),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 26, 0, 0),
                    sliver: SliverToBoxAdapter(
                      child: products.isEmpty
                          ? const _MessagePanel(message: 'Chưa có sản phẩm.')
                          : _HomeProductSections(products: products),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  List<ProductModel> _searchProducts(List<ProductModel> products) {
    final keyword = _query.trim().toLowerCase();
    if (keyword.isEmpty) {
      return products;
    }

    return products.where((product) {
      final brand = product.brand?.toLowerCase() ?? '';
      final category = product.categoryName?.toLowerCase() ?? '';
      return product.name.toLowerCase().contains(keyword) ||
          brand.contains(keyword) ||
          category.contains(keyword);
    }).toList();
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.showSearch,
    required this.controller,
    required this.canFilter,
    required this.onSearchToggle,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onFilterTap,
    required this.onAccountTap,
    required this.onCartTap,
  });

  final bool showSearch;
  final TextEditingController controller;
  final bool canFilter;
  final VoidCallback onSearchToggle;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback? onFilterTap;
  final VoidCallback onAccountTap;
  final VoidCallback onCartTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.menu_rounded, size: 30),
            ),
            const SizedBox(width: 8),
            const Expanded(child: _ShopLogo()),
            IconButton(
              onPressed: onSearchToggle,
              icon: const Icon(Icons.search_rounded, size: 28),
            ),
            GestureDetector(
              onTap: onAccountTap,
              child: const CircleAvatar(
                radius: 22,
                backgroundColor: Color(0xFFE3E7EE),
                child: Icon(Icons.person, color: _primaryTextColor),
              ),
            ),
            IconButton(
              onPressed: onCartTap,
              icon: const Icon(Icons.shopping_bag_outlined),
            ),
          ],
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: showSearch
              ? Padding(
                  key: const ValueKey('search'),
                  padding: const EdgeInsets.only(top: 18),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          autofocus: true,
                          onChanged: onSearchChanged,
                          decoration: InputDecoration(
                            hintText: 'Search',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: controller.text.trim().isEmpty
                                ? null
                                : IconButton(
                                    onPressed: onClearSearch,
                                    icon: const Icon(Icons.close),
                                  ),
                          ),
                        ),
                      ),
                      if (canFilter) ...[
                        const SizedBox(width: 14),
                        SizedBox.square(
                          dimension: 52,
                          child: IconButton.filled(
                            onPressed: onFilterTap,
                            icon: const Icon(Icons.tune_rounded),
                          ),
                        ),
                      ],
                    ],
                  ),
                )
              : const SizedBox.shrink(key: ValueKey('no-search')),
        ),
      ],
    );
  }
}

class _ShopLogo extends StatelessWidget {
  const _ShopLogo();

  @override
  Widget build(BuildContext context) {
    return const Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'Shop',
            style: TextStyle(
              color: Colors.black,
              fontSize: 42,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          TextSpan(
            text: '.',
            style: TextStyle(
              color: Color(0xFF9DFF00),
              fontSize: 42,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      ),
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
        color: const Color(0xFF17170D),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Transform.rotate(
              angle: -0.16,
              child: const Text(
                '%',
                style: TextStyle(
                  color: Color(0xFFFFA82E),
                  fontSize: 148,
                  fontWeight: FontWeight.w900,
                  height: 0.8,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'BLACK FRIYAY',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '20% off',
                style: TextStyle(
                  color: Color(0xFFFFB23F),
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Text(
                'all products',
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
                  backgroundColor: const Color(0xFFFFB23F),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(60, 34),
                ),
                child: const Text('Get'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeProductSections extends StatelessWidget {
  const _HomeProductSections({required this.products});

  final List<ProductModel> products;

  @override
  Widget build(BuildContext context) {
    final popularProducts = [...products]
      ..sort((a, b) => b.rating.compareTo(a.rating));

    return Column(
      children: [
        _HorizontalProductSection(
          title: 'Trending',
          products: products.take(8).toList(),
        ),
        const SizedBox(height: 28),
        _HorizontalProductSection(
          title: 'Most Popular',
          products: popularProducts.take(8).toList(),
        ),
        const SizedBox(height: 110),
      ],
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
                style: TextButton.styleFrom(backgroundColor: Colors.white),
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

class _SearchResults extends StatelessWidget {
  const _SearchResults({
    required this.query,
    required this.products,
  });

  final String query;
  final List<ProductModel> products;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return _MessagePanel(message: 'Không tìm thấy sản phẩm cho "$query".');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${products.length} Results',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: _primaryTextColor,
                fontSize: 18,
              ),
        ),
        const SizedBox(height: 18),
        GridView.builder(
          itemCount: products.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 16,
            childAspectRatio: 0.62,
          ),
          itemBuilder: (context, index) {
            return _FigmaProductCard.compact(product: products[index]);
          },
        ),
      ],
    );
  }
}

class _FigmaProductCard extends StatelessWidget {
  const _FigmaProductCard({required this.product}) : compact = false;
  const _FigmaProductCard.compact({required this.product}) : compact = true;

  final ProductModel product;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: compact ? null : 224,
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
            padding: const EdgeInsets.all(14),
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
                            child: CachedNetworkImage(
                              imageUrl: product.imageUrl,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => const Icon(
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
                const SizedBox(height: 12),
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
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const Icon(Icons.star, size: 15, color: Color(0xFFFFB020)),
                    Text(
                      ' (${product.rating.toStringAsFixed(1)})',
                      style: const TextStyle(
                        color: _secondaryTextColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Text(
                  product.brand ?? product.categoryName ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _secondaryTextColor, fontSize: 12),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '\$${product.displayPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    SizedBox.square(
                      dimension: 40,
                      child: IconButton.filled(
                        onPressed: () {},
                        icon: const Icon(Icons.add),
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
