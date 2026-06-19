import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../l10n/app_strings.dart';
import '../../../models/product_model.dart';
import '../../../services/seller_product_service.dart';
import '../../../utils/currency_formatter.dart';
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
      builder: (_) => _ProductFormSheet(
        product: product,
        service: _service,
        sellerId: widget.sellerId,
      ),
    );

    if (result == null) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      final imageUrls = [...result.existingImageUrls];
      for (var index = 0; index < result.imageBytes.length; index++) {
        final imageUrl = await _service.uploadProductImage(
          sellerId: widget.sellerId,
          bytes: result.imageBytes[index],
          fileName: index < result.imageNames.length
              ? result.imageNames[index]
              : 'product_$index.jpg',
        );
        imageUrls.add(imageUrl);
      }
      final imageUrl = imageUrls.isEmpty ? '' : imageUrls.first;

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
          classificationId: result.classificationId,
          classificationName: result.classificationName,
          classifications: result.classifications,
          sizes: result.sizes,
          thumbnailUrl: imageUrl,
          imageUrls: imageUrls,
        );
        _showSnackBar('Đăng sản phẩm mới thành công.');
      } else {
        await _service.updateProduct(
          product: product,
          name: result.name,
          price: result.price,
          stock: result.stock,
          categoryId: result.categoryId,
          categoryName: result.categoryName,
          classificationId: result.classificationId,
          classificationName: result.classificationName,
          classifications: result.classifications,
          sizes: result.sizes,
          thumbnailUrl: imageUrl,
          imageUrls: imageUrls,
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
                    formatVnd(product.displayPrice),
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
  const _ProductFormSheet({
    required this.product,
    required this.service,
    required this.sellerId,
  });

  final ProductModel? product;
  final SellerProductService service;
  final String sellerId;

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
  late final TextEditingController _sizesController;
  String? _selectedCategoryId;
  String _selectedCategoryName = '';
  String? _selectedClassificationId;
  String _selectedClassificationName = '';
  final _selectedClassifications = <SellerProductTaxonomy>[];
  late final List<String> _existingImageUrls;
  final _imageBytes = <Uint8List>[];
  final _imageNames = <String>[];

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
    _sizesController = TextEditingController(
      text: product == null ? '' : product.sizes.join(', '),
    );
    _selectedCategoryId = product?.categoryId;
    _selectedCategoryName = product?.categoryName ?? '';
    _selectedClassificationId = product?.classificationId;
    _selectedClassificationName = product?.classificationName ?? '';
    _existingImageUrls = product?.imageUrls.isNotEmpty == true
        ? [...product!.imageUrls]
        : [
            if (product?.imageUrl.trim().isNotEmpty == true) product!.imageUrl,
          ];
    for (final name in product?.classifications ?? const <String>[]) {
      _selectedClassifications.add(
        SellerProductTaxonomy(id: name, name: name, type: 'classification'),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _sizesController.dispose();
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
                existingImageUrls: _existingImageUrls,
                onPick: _pickImage,
                onRemoveExisting: _removeExistingImage,
                onRemoveNew: _removeNewImage,
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
              _TaxonomySelector(
                service: widget.service,
                sellerId: widget.sellerId,
                selectedCategoryId: _selectedCategoryId,
                selectedClassificationIds:
                    _selectedClassifications.map((item) => item.id).toSet(),
                onCategoryChanged: (item) {
                  setState(() {
                    _selectedCategoryId = item.id;
                    _selectedCategoryName = item.name;
                  });
                },
                onClassificationChanged: (item, selected) {
                  setState(() {
                    if (selected) {
                      _selectedClassifications.add(item);
                    } else {
                      _selectedClassifications.removeWhere(
                        (selectedItem) => selectedItem.id == item.id,
                      );
                    }
                    _selectedClassificationId = _selectedClassifications.isEmpty
                        ? null
                        : _selectedClassifications.first.id;
                    _selectedClassificationName = _selectedClassifications.isEmpty
                        ? ''
                        : _selectedClassifications.first.name;
                  });
                },
                onCreate: _createTaxonomy,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _sizesController,
                decoration: const InputDecoration(
                  labelText: 'Kich co tuy chon',
                  hintText: 'VD: S, M, L. Bo trong neu khong co',
                ),
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
    final images = await _picker.pickMultiImage(
      maxWidth: 900,
      maxHeight: 900,
      imageQuality: 60,
    );
    if (images.isEmpty) {
      return;
    }

    final nextBytes = <Uint8List>[];
    final nextNames = <String>[];
    for (final image in images) {
      final bytes = await image.readAsBytes();
      if (bytes.lengthInBytes > 4 * 1024 * 1024) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anh qua lon. Vui long chon anh nho hon 4MB.'),
          ),
        );
        return;
      }
      nextBytes.add(bytes);
      nextNames.add(image.name);
    }
    setState(() {
      _imageBytes.addAll(nextBytes);
      _imageNames.addAll(nextNames);
    });
  }

  void _removeExistingImage(String url) {
    setState(() => _existingImageUrls.remove(url));
  }

  void _removeNewImage(int index) {
    setState(() {
      _imageBytes.removeAt(index);
      _imageNames.removeAt(index);
    });
  }

  Future<void> _createTaxonomy(String type) async {
    final controller = TextEditingController();
    final title = type == 'classification' ? 'Tao phan loai' : 'Tao danh muc';
    final hint = type == 'classification' ? 'Ten phan loai' : 'Ten danh muc';

    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(labelText: hint),
            onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Huy'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(controller.text.trim());
              },
              child: const Text('Tao'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (name == null || name.isEmpty) {
      return;
    }

    try {
      final item = await widget.service.createTaxonomy(
        sellerId: widget.sellerId,
        name: name,
        type: type,
      );
      if (!mounted) {
        return;
      }
      setState(() {
    if (item.isClassification) {
          _selectedClassifications.add(item);
          _selectedClassificationId = item.id;
          _selectedClassificationName = item.name;
        } else {
          _selectedCategoryId = item.id;
          _selectedCategoryName = item.name;
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tao that bai: $error')),
      );
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedCategoryId == null || _selectedCategoryName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui long chon hoac tao danh muc.')),
      );
      return;
    }
    if (widget.product == null && _existingImageUrls.isEmpty && _imageBytes.isEmpty) {
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
        categoryId: _selectedCategoryId!,
        categoryName: _selectedCategoryName.trim(),
        classificationId: _selectedClassificationId,
        classificationName: _selectedClassificationName.trim(),
        classifications:
            _selectedClassifications.map((item) => item.name).toList(),
        sizes: _splitOptions(_sizesController.text),
        existingImageUrls: _existingImageUrls,
        imageBytes: _imageBytes,
        imageNames: _imageNames,
      ),
    );
  }

  List<String> _splitOptions(String value) {
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();
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
class _TaxonomySelector extends StatelessWidget {
  const _TaxonomySelector({
    required this.service,
    required this.sellerId,
    required this.selectedCategoryId,
    required this.selectedClassificationIds,
    required this.onCategoryChanged,
    required this.onClassificationChanged,
    required this.onCreate,
  });

  final SellerProductService service;
  final String sellerId;
  final String? selectedCategoryId;
  final Set<String> selectedClassificationIds;
  final ValueChanged<SellerProductTaxonomy> onCategoryChanged;
  final void Function(SellerProductTaxonomy item, bool selected)
      onClassificationChanged;
  final ValueChanged<String> onCreate;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SellerProductTaxonomy>>(
      stream: service.watchSellerTaxonomies(sellerId),
      builder: (context, snapshot) {
        final items = snapshot.data ?? <SellerProductTaxonomy>[];
        final categories = items.where((item) => item.isCategory).toList();
        final classifications =
            items.where((item) => item.isClassification).toList();
        final categoryValue = categories.any((item) {
          return item.id == selectedCategoryId;
        })
            ? selectedCategoryId
            : null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TaxonomyRow(
              label: 'Danh muc',
              buttonLabel: 'Tao danh muc',
              onCreate: () => onCreate('category'),
              child: DropdownButtonFormField<String>(
                value: categoryValue,
                decoration: const InputDecoration(labelText: 'Danh muc'),
                items: categories.map((item) {
                  return DropdownMenuItem<String>(
                    value: item.id,
                    child: Text(item.name),
                  );
                }).toList(),
                onChanged: (value) {
                  SellerProductTaxonomy? selected;
                  for (final item in categories) {
                    if (item.id == value) {
                      selected = item;
                      break;
                    }
                  }
                  if (selected != null) {
                    onCategoryChanged(selected);
                  }
                },
              ),
            ),
            const SizedBox(height: 12),
            _TaxonomyRow(
              label: 'Phan loai',
              buttonLabel: 'Tao phan loai',
              onCreate: () => onCreate('classification'),
              child: classifications.isEmpty
                  ? const Text('Chua co phan loai.')
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final item in classifications)
                          FilterChip(
                            label: Text(item.name),
                            selected: selectedClassificationIds.contains(item.id),
                            onSelected: (selected) {
                              onClassificationChanged(item, selected);
                            },
                          ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _TaxonomyRow extends StatelessWidget {
  const _TaxonomyRow({
    required this.label,
    required this.buttonLabel,
    required this.child,
    required this.onCreate,
  });

  final String label;
  final String buttonLabel;
  final Widget child;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            TextButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add, size: 18),
              label: Text(buttonLabel),
            ),
          ],
        ),
        child,
      ],
    );
  }
}

class _ImagePickerBox extends StatelessWidget {
  const _ImagePickerBox({
    required this.imageBytes,
    required this.existingImageUrls,
    required this.onPick,
    required this.onRemoveExisting,
    required this.onRemoveNew,
  });

  final List<Uint8List> imageBytes;
  final List<String> existingImageUrls;
  final VoidCallback onPick;
  final ValueChanged<String> onRemoveExisting;
  final ValueChanged<int> onRemoveNew;

  @override
  Widget build(BuildContext context) {
    final hasImages = existingImageUrls.isNotEmpty || imageBytes.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: onPick,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: Text(hasImages ? 'Them anh san pham' : context.tr('chooseImage')),
        ),
        const SizedBox(height: 10),
        if (!hasImages)
          Container(
            height: 140,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD1D5DB)),
            ),
            child: const Icon(Icons.add_photo_alternate_outlined, size: 44),
          )
        else
          SizedBox(
            height: 112,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final url in existingImageUrls)
                  _ImageThumb(
                    child: ProductImage(imageUrl: url, fit: BoxFit.cover),
                    onRemove: () => onRemoveExisting(url),
                  ),
                for (var index = 0; index < imageBytes.length; index++)
                  _ImageThumb(
                    child: Image.memory(imageBytes[index], fit: BoxFit.cover),
                    onRemove: () => onRemoveNew(index),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ImageThumb extends StatelessWidget {
  const _ImageThumb({
    required this.child,
    required this.onRemove,
  });

  final Widget child;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      margin: const EdgeInsets.only(right: 10),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD1D5DB)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          child,
          Positioned(
            right: 4,
            top: 4,
            child: Material(
              color: Colors.black.withOpacity(0.55),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onRemove,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ),
          ),
        ],
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
    required this.classificationId,
    required this.classificationName,
    required this.classifications,
    required this.sizes,
    required this.existingImageUrls,
    required this.imageBytes,
    required this.imageNames,
  });

  final String name;
  final String description;
  final double price;
  final int stock;
  final String categoryId;
  final String categoryName;
  final String? classificationId;
  final String classificationName;
  final List<String> classifications;
  final List<String> sizes;
  final List<String> existingImageUrls;
  final List<Uint8List> imageBytes;
  final List<String> imageNames;
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
