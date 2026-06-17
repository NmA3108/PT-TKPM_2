import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/product_model.dart';
import '../../services/seller_product_service.dart';

const _backgroundColor = Color(0xFFF5F7FB);
const _surfaceColor = Color(0xFFFFFFFF);
const _secondaryTextColor = Color(0xFF6B7280);
const _dangerColor = Color(0xFFEF4444);

class SellerProductManagementScreen extends StatefulWidget {
  const SellerProductManagementScreen({
    super.key,
    required this.sellerId,
    required this.shopId,
  });

  final String sellerId;
  final String shopId;

  @override
  State<SellerProductManagementScreen> createState() {
    return _SellerProductManagementScreenState();
  }
}

class _SellerProductManagementScreenState
    extends State<SellerProductManagementScreen> {
  final _service = SellerProductService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text('Quản lý sản phẩm'),
      ),
      body: StreamBuilder<List<ProductModel>>(
        stream: _service.watchSellerProducts(widget.sellerId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _MessageState(
              message: 'Không thể tải danh sách sản phẩm.\n${snapshot.error}',
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final products = snapshot.data ?? <ProductModel>[];
          if (products.isEmpty) {
            return const _MessageState(
              message: 'Cửa hàng chưa có sản phẩm nào.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _SellerProductCard(
                product: products[index],
                onEdit: () => _openProductForm(products[index]),
                onHide: () => _confirmHideProduct(products[index]),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openProductForm(null),
        icon: const Icon(Icons.add_box_outlined),
        label: const Text('Đăng sản phẩm mới'),
      ),
    );
  }

  Future<void> _openProductForm(ProductModel? product) async {
    final result = await showModalBottomSheet<_ProductFormResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ProductFormSheet(product: product),
    );

    if (result == null) {
      return;
    }

    try {
      if (product == null) {
        await _service.createProduct(
          sellerId: widget.sellerId,
          shopId: widget.shopId,
          name: result.name,
          description: result.description,
          price: result.price,
          stock: result.stock,
          categoryId: result.categoryId,
          categoryName: result.categoryName,
          thumbnailUrl: result.thumbnailUrl,
        );
        _showSnackBar('Đăng sản phẩm mới thành công.');
      } else {
        await _service.updateProduct(
          product: product,
          name: result.name,
          price: result.price,
          stock: result.stock,
          categoryName: result.categoryName,
          thumbnailUrl: result.thumbnailUrl,
        );
        _showSnackBar('Cập nhật thông tin sản phẩm thành công.');
      }
    } catch (error) {
      _showSnackBar('Thao tác thất bại: $error');
    }
  }

  Future<void> _confirmHideProduct(ProductModel product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ẩn sản phẩm'),
        content: Text('Bạn có muốn ẩn "${product.name}" khỏi gian hàng?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _dangerColor),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ẩn'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _service.hideProduct(product);
      _showSnackBar('Đã ẩn sản phẩm.');
    } catch (error) {
      _showSnackBar('Ẩn sản phẩm thất bại: $error');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _SellerProductCard extends StatelessWidget {
  const _SellerProductCard({
    required this.product,
    required this.onEdit,
    required this.onHide,
  });

  final ProductModel product;
  final VoidCallback onEdit;
  final VoidCallback onHide;

  @override
  Widget build(BuildContext context) {
    final isHidden = product.status == 'hidden';

    return Card(
      color: _surfaceColor,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 82,
                width: 82,
                child: CachedNetworkImage(
                  imageUrl: product.imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const ColoredBox(
                    color: Color(0xFFE5E7EB),
                    child: Icon(Icons.image_not_supported_outlined),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '\$${product.displayPrice.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Kho: ${product.stock} • Đã bán: ${product.soldCount}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (isHidden)
                    Text(
                      'Đang ẩn',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _dangerColor,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  tooltip: 'Cập nhật thông tin sản phẩm',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Ẩn sản phẩm',
                  onPressed: isHidden ? null : onHide,
                  icon: const Icon(
                    Icons.visibility_off_outlined,
                    color: _dangerColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductFormSheet extends StatefulWidget {
  const _ProductFormSheet({required this.product});

  final ProductModel? product;

  @override
  State<_ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<_ProductFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;
  late final TextEditingController _categoryIdController;
  late final TextEditingController _categoryNameController;
  late final TextEditingController _imageController;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _nameController = TextEditingController(text: product?.name ?? '');
    _descriptionController = TextEditingController();
    _priceController = TextEditingController(
      text: product == null ? '' : product.displayPrice.toStringAsFixed(0),
    );
    _stockController = TextEditingController(
      text: product == null ? '' : product.stock.toString(),
    );
    _categoryIdController = TextEditingController(
      text: product?.categoryId ?? 'cat_fashion',
    );
    _categoryNameController = TextEditingController(
      text: product?.categoryName ?? 'Fashion',
    );
    _imageController = TextEditingController(text: product?.imageUrl ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _categoryIdController.dispose();
    _categoryNameController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEditing ? 'Cập nhật sản phẩm' : 'Đăng sản phẩm mới',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Tên sản phẩm'),
                validator: _requiredValidator,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Mô tả'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Giá bán'),
                validator: _numberValidator,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Số lượng tồn kho'),
                validator: _intValidator,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoryIdController,
                decoration: const InputDecoration(labelText: 'Mã danh mục'),
                validator: _requiredValidator,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoryNameController,
                decoration: const InputDecoration(labelText: 'Tên danh mục'),
                validator: _requiredValidator,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _imageController,
                decoration: const InputDecoration(labelText: 'URL hình ảnh'),
                validator: _requiredValidator,
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _submit,
                child: Text(isEditing ? 'Lưu thay đổi' : 'Đăng sản phẩm'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      _ProductFormResult(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        stock: int.parse(_stockController.text.trim()),
        categoryId: _categoryIdController.text.trim(),
        categoryName: _categoryNameController.text.trim(),
        thumbnailUrl: _imageController.text.trim(),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập thông tin.';
    }
    return null;
  }

  String? _numberValidator(String? value) {
    final error = _requiredValidator(value);
    if (error != null) {
      return error;
    }
    return double.tryParse(value!.trim()) == null
        ? 'Giá bán không hợp lệ.'
        : null;
  }

  String? _intValidator(String? value) {
    final error = _requiredValidator(value);
    if (error != null) {
      return error;
    }
    return int.tryParse(value!.trim()) == null
        ? 'Số lượng không hợp lệ.'
        : null;
  }
}

class _ProductFormResult {
  const _ProductFormResult({
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.categoryId,
    required this.categoryName,
    required this.thumbnailUrl,
  });

  final String name;
  final String description;
  final double price;
  final int stock;
  final String categoryId;
  final String categoryName;
  final String thumbnailUrl;
}

class _MessageState extends StatelessWidget {
  const _MessageState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _secondaryTextColor,
              ),
        ),
      ),
    );
  }
}
