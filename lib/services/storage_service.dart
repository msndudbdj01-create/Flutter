import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _myListKey = 'my_list_movies';
  static const String _continueWatchingKey = 'continue_watching';

  // مفاتيح إعدادات الترجمة
  static const String _subtitleLanguageKey = 'subtitle_language';
  static const String _subtitleFontKey = 'subtitle_font';
  static const String _subtitleTextSizeKey = 'subtitle_text_size';
  static const String _subtitleTextColorKey = 'subtitle_text_color';
  static const String _subtitleBgColorKey = 'subtitle_bg_color';
  static const String _subtitlePositionKey = 'subtitle_position';
  static const String _defaultQualityKey = 'default_quality';
  static const String _resizeModeKey = 'resize_mode';

  /// حفظ فيلم/مسلسل في القائمة
  static Future<void> addToMyList(Map<String, dynamic> media) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> myList = prefs.getStringList(_myListKey) ?? [];

    final exists = myList.any((item) {
      try {
        return json.decode(item)['id'] == media['id'];
      } catch (_) {
        return false;
      }
    });

    if (!exists) {
      myList.add(json.encode(media));
      await prefs.setStringList(_myListKey, myList);
    }
  }

  /// جلب القائمة
  static Future<List<Map<String, dynamic>>> getMyList() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> myList = prefs.getStringList(_myListKey) ?? [];

    return myList
        .map((item) {
          try {
            return json.decode(item) as Map<String, dynamic>;
          } catch (_) {
            return <String, dynamic>{};
          }
        })
        .where((item) => item.isNotEmpty)
        .toList();
  }

  /// حذف من القائمة
  static Future<void> removeFromMyList(int mediaId) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> myList = prefs.getStringList(_myListKey) ?? [];

    myList.removeWhere((item) {
      try {
        return json.decode(item)['id'] == mediaId;
      } catch (_) {
        return false;
      }
    });

    await prefs.setStringList(_myListKey, myList);
  }

  /// التحقق من وجود عنصر في القائمة
  static Future<bool> isInList(int mediaId) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> myList = prefs.getStringList(_myListKey) ?? [];

    return myList.any((item) {
      try {
        return json.decode(item)['id'] == mediaId;
      } catch (_) {
        return false;
      }
    });
  }

  /// حفظ قائمة متابعة المشاهدة
  static Future<void> saveContinueWatching(
      List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = items.map((e) => json.encode(e)).toList();
    await prefs.setStringList(_continueWatchingKey, encoded);
  }

  /// جلب قائمة متابعة المشاهدة
  static Future<List<Map<String, dynamic>>> getContinueWatching() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> raw = prefs.getStringList(_continueWatchingKey) ?? [];

    return raw
        .map((item) {
          try {
            return json.decode(item) as Map<String, dynamic>;
          } catch (_) {
            return <String, dynamic>{};
          }
        })
        .where((item) => item.isNotEmpty)
        .toList();
  }

  /// حفظ موقع استكمال المشاهدة
  static Future<void> saveResumePosition({
    required int mediaId,
    required String mediaType,
    required int season,
    required int episode,
    required double position,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'resume_${mediaId}_${mediaType}_${season}_$episode';
    await prefs.setDouble(key, position);
  }

  /// جلب موقع استكمال المشاهدة
  static Future<double> getResumePosition({
    required int mediaId,
    required String mediaType,
    required int season,
    required int episode,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'resume_${mediaId}_${mediaType}_${season}_$episode';
    return prefs.getDouble(key) ?? 0.0;
  }

  // ==================== إعدادات الترجمة ====================

  static Future<String> getSubtitleLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_subtitleLanguageKey) ?? 'ar';
  }

  static Future<void> setSubtitleLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_subtitleLanguageKey, language);
  }

  static Future<String> getSubtitleFont() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_subtitleFontKey) ?? 'Default';
  }

  static Future<void> setSubtitleFont(String font) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_subtitleFontKey, font);
  }

  static Future<double> getSubtitleTextSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_subtitleTextSizeKey) ?? 10.0;
  }

  static Future<void> setSubtitleTextSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_subtitleTextSizeKey, size);
  }

  static Future<int?> getSubtitleTextColorValue() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_subtitleTextColorKey);
  }

  static Future<void> setSubtitleTextColorValue(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_subtitleTextColorKey, value);
  }

  static Future<int?> getSubtitleBgColorValue() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_subtitleBgColorKey);
  }

  static Future<void> setSubtitleBgColorValue(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_subtitleBgColorKey, value);
  }

  static Future<double> getSubtitlePosition() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_subtitlePositionKey) ?? 40.0;
  }

  static Future<void> setSubtitlePosition(double position) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_subtitlePositionKey, position);
  }

  static Future<String> getDefaultQuality() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_defaultQualityKey) ?? 'Auto';
  }

  static Future<void> setDefaultQuality(String quality) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultQualityKey, quality);
  }

  static Future<String> getResizeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_resizeModeKey) ?? 'Fit';
  }

  static Future<void> setResizeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_resizeModeKey, mode);
  }

  // ==================== مسح البيانات ====================

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
