import 'package:flutter/foundation.dart';

enum AppLanguage {
  en,
  vi,
}

class LanguageProvider extends ChangeNotifier {
  AppLanguage _language = AppLanguage.vi;

  AppLanguage get language => _language;
  bool get isVietnamese => _language == AppLanguage.vi;

  void toggle() {
    _language = isVietnamese ? AppLanguage.en : AppLanguage.vi;
    notifyListeners();
  }

  void setLanguage(AppLanguage language) {
    if (_language == language) {
      return;
    }
    _language = language;
    notifyListeners();
  }
}
