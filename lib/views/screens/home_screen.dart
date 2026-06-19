import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/providers/auth_provider.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';
import '../../utils/currency_formatter.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/app_asset_icon.dart';
import '../widgets/chatbot_floating_button.dart';
import '../widgets/product_image.dart';
import 'product_detail_screen.dart';

const _backgroundColor = Color(0xFFF8F7FC);
const _surfaceColor = Color(0xFFFFFFFF);
const _primaryTextColor = Color(0xFF0B1B2E);
const _secondaryTextColor = Color(0xFF8A8F9C);
const _accentColor = Color(0xFF5D3FD3);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static final ProductService _productService = ProductService();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  String _draftKeyword = '';
  String _submittedKeyword = '';
  String _sortMode = 'relevance';
  double? _minPrice;
  double? _maxPrice;
  var _showSuggestions = false;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
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
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              sliver: SliverToBoxAdapter(
                child: _HomeHeader(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  showSuggestions: _showSuggestions,
                  keyword: _draftKeyword,
                  hasSearched: _submittedKeyword.isNotEmpty,
                  sortMode: _sortMode,
                  hasPriceFilter: _minPrice != null || _maxPrice != null,
                  onChanged: (value) {
                    setState(() => _draftKeyword = value.trim());
                  },
                  onSubmitted: _submitSearch,
                  onFocusChanged: (focused) {
                    setState(() => _showSuggestions = focused);
                  },
                  onSuggestionSelected: _selectSuggestion,
                  onBackHome: _resetSearch,
                  onFilterTap: _openPriceFilter,
                  onSortChanged: (value) {
                    if (value == null) return;
                    setState(() => _sortMode = value);
                  },
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
                  stream: _submittedKeyword.isEmpty
                      ? _productService.watchProducts()
                      : _productService.searchProducts(_submittedKeyword),
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

                    final products = _applySearchTools(
                      snapshot.data ?? <ProductModel>[],
                    );
                    if (products.isEmpty) {
                      return const _MessagePanel(message: 'Chưa có sản phẩm.');
                    }

                    final popularProducts = [...products]
                      ..sort((a, b) => b.rating.compareTo(a.rating));

                    return Column(
                      children: [
                        if (_submittedKeyword.isNotEmpty)
                          _HorizontalProductSection(
                            title: 'Kết quả tìm kiếm',
                            products: products.take(12).toList(),
                          )
                        else ...[
                          _HorizontalProductSection(
                            title: 'Mới nhất',
                            products: products.take(8).toList(),
                          ),
                          const SizedBox(height: 28),
                          _HorizontalProductSection(
                            title: 'Nổi bật',
                            products: popularProducts.take(8).toList(),
                          ),
                        ],
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

  Future<void> _submitSearch(String value) async {
    final keyword = value.trim();
    setState(() {
      _draftKeyword = keyword;
      _submittedKeyword = keyword;
      _showSuggestions = false;
    });
    _searchFocusNode.unfocus();

    String? userId;
    try {
      userId = context.read<AuthProvider>().currentUser?.uid;
    } catch (_) {}
    if (userId != null && keyword.isNotEmpty) {
      try {
        await _productService.saveSearchKeyword(
          userId: userId,
          keyword: keyword,
        );
      } catch (_) {}
    }
  }

  void _selectSuggestion(String keyword) {
    _searchController.text = keyword;
    _submitSearch(keyword);
  }

  void _resetSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() {
      _draftKeyword = '';
      _submittedKeyword = '';
      _sortMode = 'relevance';
      _minPrice = null;
      _maxPrice = null;
      _showSuggestions = false;
    });
  }

  List<ProductModel> _applySearchTools(List<ProductModel> products) {
    var result = products.where((product) {
      final price = product.displayPrice;
      final aboveMin = _minPrice == null || price >= _minPrice!;
      final belowMax = _maxPrice == null || price <= _maxPrice!;
      return aboveMin && belowMax;
    }).toList();

    switch (_sortMode) {
      case 'priceAsc':
        result.sort((a, b) => a.displayPrice.compareTo(b.displayPrice));
        break;
      case 'priceDesc':
        result.sort((a, b) => b.displayPrice.compareTo(a.displayPrice));
        break;
      case 'rating':
        result.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      default:
        break;
    }
    return result;
  }

  Future<void> _openPriceFilter() async {
    final result = await showModalBottomSheet<_PriceFilterResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _PriceFilterSheet(
        minPrice: _minPrice,
        maxPrice: _maxPrice,
      ),
    );
    if (result == null) {
      return;
    }
    setState(() {
      _minPrice = result.minPrice;
      _maxPrice = result.maxPrice;
    });
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.controller,
    required this.focusNode,
    required this.showSuggestions,
    required this.keyword,
    required this.hasSearched,
    required this.sortMode,
    required this.hasPriceFilter,
    required this.onChanged,
    required this.onSubmitted,
    required this.onFocusChanged,
    required this.onSuggestionSelected,
    required this.onBackHome,
    required this.onFilterTap,
    required this.onSortChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool showSuggestions;
  final String keyword;
  final bool hasSearched;
  final String sortMode;
  final bool hasPriceFilter;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final ValueChanged<bool> onFocusChanged;
  final ValueChanged<String> onSuggestionSelected;
  final VoidCallback onBackHome;
  final VoidCallback onFilterTap;
  final ValueChanged<String?> onSortChanged;

  @override
  Widget build(BuildContext context) {
    String? userId;
    try {
      userId = context.watch<AuthProvider>().currentUser?.uid;
    } catch (_) {}

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: keyword.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            controller.clear();
                            onChanged('');
                            onSubmitted('');
                          },
                          icon: const Icon(Icons.close),
                        ),
                ),
                onChanged: onChanged,
                onSubmitted: onSubmitted,
                onTap: () => onFocusChanged(true),
              ),
            ),
          ],
        ),
        if (hasSearched) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              ActionChip(
                avatar: const AppAssetIcon(assetName: 'home.jpg', size: 18),
                label: const Text('Trang chủ'),
                onPressed: onBackHome,
              ),
              const SizedBox(width: 10),
              FilterChip(
                selected: hasPriceFilter,
                onSelected: (_) => onFilterTap(),
                avatar: const Icon(Icons.tune_rounded, size: 18),
                label: const Text('Lọc'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: sortMode,
                  decoration: const InputDecoration(
                    labelText: 'Sắp xếp',
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'relevance',
                      child: Text('Lượt mua'),
                    ),
                    DropdownMenuItem(
                      value: 'priceAsc',
                      child: Text('Giá tăng dần'),
                    ),
                    DropdownMenuItem(
                      value: 'priceDesc',
                      child: Text('Giá giảm dần'),
                    ),
                    DropdownMenuItem(
                      value: 'rating',
                      child: Text('Đánh giá cao'),
                    ),
                  ],
                  onChanged: onSortChanged,
                ),
              ),
            ],
          ),
        ],
        if (showSuggestions && userId != null)
          StreamBuilder<List<String>>(
            stream: _HomeScreenState._productService.watchSearchHistory(userId),
            builder: (context, snapshot) {
              final histories = snapshot.data ?? const <String>[];
              if (histories.isEmpty) {
                return const SizedBox.shrink();
              }

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final history in histories)
                      ActionChip(
                        avatar: const Icon(Icons.history, size: 16),
                        label: Text(history),
                        onPressed: () => onSuggestionSelected(history),
                      ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

class _PriceFilterSheet extends StatefulWidget {
  const _PriceFilterSheet({
    required this.minPrice,
    required this.maxPrice,
  });

  final double? minPrice;
  final double? maxPrice;

  @override
  State<_PriceFilterSheet> createState() => _PriceFilterSheetState();
}

class _PriceFilterSheetState extends State<_PriceFilterSheet> {
  late RangeValues _values;

  @override
  void initState() {
    super.initState();
    _values = RangeValues(
      widget.minPrice ?? 0,
      widget.maxPrice ?? 50000000,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Lọc theo khoảng giá', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Text('${formatVnd(_values.start)} - ${formatVnd(_values.end)}'),
          RangeSlider(
            min: 0,
            max: 50000000,
            divisions: 100,
            values: _values,
            labels: RangeLabels(
              formatVnd(_values.start),
              formatVnd(_values.end),
            ),
            onChanged: (value) => setState(() => _values = value),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop(
                      const _PriceFilterResult(
                        minPrice: null,
                        maxPrice: null,
                      ),
                    );
                  },
                  child: const Text('Xóa lọc'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop(
                      _PriceFilterResult(
                        minPrice: _values.start,
                        maxPrice: _values.end,
                      ),
                    );
                  },
                  child: const Text('Áp dụng'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriceFilterResult {
  const _PriceFilterResult({
    required this.minPrice,
    required this.maxPrice,
  });

  final double? minPrice;
  final double? maxPrice;
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
                'Shopping',
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
                'SIÊU SĂN SALE - NGÀY ĐÔI ĐẾN RỒI!',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'TOP ĐỒ CÔNG NGHỆ - DẪN ĐẦU XU HƯỚNG 2026',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Text(
                'Giảm chạm sàn đến 50%',
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
                child: const Text('MUA NGAY'),
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
                child: const Text('Xem thêm'),
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
  return formatVnd(value);
}
