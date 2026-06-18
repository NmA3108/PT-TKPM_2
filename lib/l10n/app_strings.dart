import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../controllers/providers/language_provider.dart';

extension AppStringsX on BuildContext {
  String tr(String key) {
    final language = watch<LanguageProvider>().language;
    final values = _strings[language] ?? _strings[AppLanguage.vi]!;
    return values[key] ?? _strings[AppLanguage.en]![key] ?? key;
  }
}

const _strings = {
  AppLanguage.en: {
    'home': 'Home',
    'category': 'Category',
    'cart': 'Cart',
    'me': 'Me',
    'message': 'Message',
    'search': 'Search',
    'filter': 'Filter',
    'trending': 'Trending',
    'mostPopular': 'Most Popular',
    'viewAll': 'View all',
    'noProducts': 'No products available.',
    'cannotLoadProducts': 'Cannot load products.',
    'results': 'Results',
    'noSearchResults': 'No products found.',
    'categories': 'Categories',
    'allProducts': 'All products',
    'language': 'Language',
    'english': 'English',
    'vietnamese': 'Vietnamese',
    'sellerProducts': 'Product Management',
    'addProduct': 'Add product',
    'editProduct': 'Edit product',
    'productName': 'Product name',
    'description': 'Description',
    'price': 'Price',
    'stock': 'Stock',
    'categoryId': 'Category ID',
    'categoryName': 'Category name',
    'chooseImage': 'Choose image',
    'changeImage': 'Change image',
    'saveChanges': 'Save changes',
    'publishProduct': 'Publish product',
    'uploadRequired': 'Please choose a product image.',
    'addToCart': 'Add to cart',
    'total': 'Total',
  },
  AppLanguage.vi: {
    'home': 'Trang chủ',
    'category': 'Danh mục',
    'cart': 'Giỏ hàng',
    'me': 'Tôi',
    'message': 'Tin nhắn',
    'search': 'Tìm kiếm',
    'filter': 'Lọc',
    'trending': 'Xu hướng',
    'mostPopular': 'Phổ biến',
    'viewAll': 'Xem tất cả',
    'noProducts': 'Chưa có sản phẩm.',
    'cannotLoadProducts': 'Không thể tải sản phẩm.',
    'results': 'Kết quả',
    'noSearchResults': 'Không tìm thấy sản phẩm.',
    'categories': 'Phân loại',
    'allProducts': 'Tất cả sản phẩm',
    'language': 'Ngôn ngữ',
    'english': 'Tiếng Anh',
    'vietnamese': 'Tiếng Việt',
    'sellerProducts': 'Quản lý sản phẩm',
    'addProduct': 'Đăng sản phẩm',
    'editProduct': 'Cập nhật sản phẩm',
    'productName': 'Tên sản phẩm',
    'description': 'Mô tả',
    'price': 'Giá bán',
    'stock': 'Tồn kho',
    'categoryId': 'Mã danh mục',
    'categoryName': 'Tên danh mục',
    'chooseImage': 'Chọn ảnh',
    'changeImage': 'Đổi ảnh',
    'saveChanges': 'Lưu thay đổi',
    'publishProduct': 'Đăng sản phẩm',
    'uploadRequired': 'Vui lòng chọn ảnh sản phẩm.',
    'addToCart': 'Thêm vào giỏ',
    'total': 'Tổng',
  },
};
