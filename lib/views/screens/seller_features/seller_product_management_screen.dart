import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../l10n/app_strings.dart';
import '../../../models/product_model.dart';
import '../../../services/seller_product_service.dart';
import '../../widgets/product_image.dart';

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
  var _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(title: Text(context.tr('sellerProducts'))),
      body: StreamBuilder<List<ProductModel>>(
        stream: _service.watchSellerProducts(widget.sellerId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _MessageState(
              message: '${context.tr('cannotLoadProducts')}\n${snapshot.error}',
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final products = snapshot.data ?? <ProductModel>[];
          if (products.isEmpty) {
            return _MessageState(message: context.tr('noProducts'));
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
        onPressed: _isSaving ? null : () => _openProductForm(null),
        icon: _isSaving
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add_box_outlined),
        label: Text(context.tr('addProduct')),
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

    setState(() => _isSaving = true);
    try {
      var imageUrl = product?.imageUrl ?? '';
      if (result.imageBytes != null) {
        try {
          imageUrl = await _service.uploadProductImage(
            sellerId: widget.sellerId,
            bytes: result.imageBytes!,
            fileName: result.imageName ?? 'product.jpg',
          );
        } catch (error) {
          imageUrl = _buildInlineImageDataUrl(
            result.imageBytes!,
            result.imageName ?? 'product.jpg',
          );
          _showSnackBar(
            'Không tải được ảnh lên Storage, app đã lưu ảnh trực tiếp để tiếp tục đăng sản phẩm.',
          );
        }
      }

      if (product == null && imageUrl.isEmpty) {
        throw Exception(context.tr('uploadRequired'));
      }

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
          thumbnailUrl: imageUrl,
        );
        _showSnackBar('Đăng sản phẩm mới thành công.');
      } else {
        await _service.updateProduct(
          product: product,
          name: result.name,
          price: result.price,
          stock: result.stock,
          categoryName: result.categoryName,
          thumbnailUrl: imageUrl,
        );
        _showSnackBar('Cập nhật sản phẩm thành công.');
      }
    } catch (error) {
      _showSnackBar('Thao tác thất bại: $error');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
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

  String _buildInlineImageDataUrl(Uint8List bytes, String fileName) {
    final lowerName = fileName.toLowerCase();
    final mimeType = lowerName.endsWith('.png')
        ? 'image/png'
        : lowerName.endsWith('.webp')
            ? 'image/webp'
            : 'image/jpeg';
    return 'data:$mimeType;base64,${base64Encode(bytes)}';
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
                child: ProductImage(
                  imageUrl: product.imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: const ColoredBox(
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
                  tooltip: context.tr('editProduct'),
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
  final _picker = ImagePicker();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;
  late final TextEditingController _categoryIdController;
  late final TextEditingController _categoryNameController;
  Uint8List? _imageBytes;
  String? _imageName;

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
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _categoryIdController.dispose();
    _categoryNameController.dispose();
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
                isEditing ? context.tr('editProduct') : context.tr('addProduct'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _ImagePickerBox(
                imageBytes: _imageBytes,
                existingImageUrl: widget.product?.imageUrl,
                onPick: _pickImage,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: context.tr('productName')),
                validator: _requiredValidator,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(labelText: context.tr('description')),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: context.tr('price')),
                validator: _numberValidator,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: context.tr('stock')),
                validator: _intValidator,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoryIdController,
                decoration: InputDecoration(labelText: context.tr('categoryId')),
                validator: _requiredValidator,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoryNameController,
                decoration: InputDecoration(labelText: context.tr('categoryName')),
                validator: _requiredValidator,
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _submit,
                child: Text(
                  isEditing ? context.tr('saveChanges') : context.tr('publishProduct'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 72,
    );
    if (image == null) {
      return;
    }

    final bytes = await image.readAsBytes();
    setState(() {
      _imageBytes = bytes;
      _imageName = image.name;
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (widget.product == null && _imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('uploadRequired'))),
      );
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
        imageBytes: _imageBytes,
        imageName: _imageName,
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
    return double.tryParse(value!.trim()) == null ? 'Giá bán không hợp lệ.' : null;
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

class _ImagePickerBox extends StatelessWidget {
  const _ImagePickerBox({
    required this.imageBytes,
    required this.existingImageUrl,
    required this.onPick,
  });

  final Uint8List? imageBytes;
  final String? existingImageUrl;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final hasExistingImage =
        existingImageUrl != null && existingImageUrl!.trim().isNotEmpty;

    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD1D5DB)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageBytes != null)
              Image.memory(imageBytes!, fit: BoxFit.cover)
            else if (hasExistingImage)
              ProductImage(imageUrl: existingImageUrl!, fit: BoxFit.cover)
            else
              const Center(
                child: Icon(Icons.add_photo_alternate_outlined, size: 44),
              ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                color: Colors.black.withOpacity(0.52),
                child: Text(
                  imageBytes == null && !hasExistingImage
                      ? context.tr('chooseImage')
                      : context.tr('changeImage'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
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

class _ProductFormResult {
  const _ProductFormResult({
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.categoryId,
    required this.categoryName,
    required this.imageBytes,
    required this.imageName,
  });

  final String name;
  final String description;
  final double price;
  final int stock;
  final String categoryId;
  final String categoryName;
  final Uint8List? imageBytes;
  final String? imageName;
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
