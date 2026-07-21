import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LocalizationService {
  final Locale locale;
  late Map<String, String> _localizedStrings;
  bool _isLoaded = false;

  LocalizationService(this.locale);

  static LocalizationService of(BuildContext context) {
    return Localizations.of<LocalizationService>(context, LocalizationService)!;
  }

  String getText(String key) {
    if (!_isLoaded) {
      return key;
    }
    return _localizedStrings[key] ?? key;
  }

  static String get(BuildContext context, String key) {
    try {
      return of(context).getText(key);
    } catch (e) {
      return key;
    }
  }

  Future<void> load() async {
    try {
      String languageCode = locale.languageCode;
      if (languageCode == 'ar') {
        languageCode = 'ar';
      } else {
        languageCode = 'en';
      }

      String jsonString = await rootBundle
          .loadString('lang/app_$languageCode.json')
          .timeout(const Duration(seconds: 5));
      Map<String, dynamic> jsonMap = json.decode(jsonString);
      _localizedStrings =
          jsonMap.map((key, value) => MapEntry(key, value.toString()));
      _isLoaded = true;
      print('✅ Localization loaded for ${locale.languageCode}');
    } catch (e) {
      print('❌ Failed to load localization: $e');
      // محاولة تحميل الإنجليزية كخط احتياطي
      try {
        String jsonString = await rootBundle
            .loadString('lang/app_en.json')
            .timeout(const Duration(seconds: 5));
        Map<String, dynamic> jsonMap = json.decode(jsonString);
        _localizedStrings =
            jsonMap.map((key, value) => MapEntry(key, value.toString()));
        _isLoaded = true;
        print('✅ Fallback English localization loaded');
      } catch (e2) {
        _localizedStrings = {};
        _isLoaded = true;
      }
    }
  }

  static Future<LocalizationService> loadLocale(Locale locale) async {
    final localization = LocalizationService(locale);
    await localization.load();
    return localization;
  }
}

class LocalizationDelegate extends LocalizationsDelegate<LocalizationService> {
  const LocalizationDelegate();

  @override
  bool isSupported(Locale locale) {
    return locale.languageCode == 'en' || locale.languageCode == 'ar';
  }

  @override
  Future<LocalizationService> load(Locale locale) async {
    return await LocalizationService.loadLocale(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<LocalizationService> old) {
    return false;
  }
}

// Extension لتسهيل الاستخدام
extension LocalizationExtension on BuildContext {
  String tr(String key) {
    try {
      return LocalizationService.get(this, key);
    } catch (e) {
      return key;
    }
  }
}
