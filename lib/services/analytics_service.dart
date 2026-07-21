import 'package:aptabase_flutter/aptabase_flutter.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  // استبدل هذا بالمفتاح الخاص بك من Aptabase
  static const String _appKey = 'A-EU-9342481486';
  static bool _isInitialized = false;

  /// تهيئة الخدمة - تستدعى مرة واحدة في main.dart
  static Future<void> init() async {
    if (_isInitialized) return;

    // في وضع التطوير، لا نقوم بتهيئة Aptabase
    /*if (kDebugMode) {
      debugPrint('Aptabase disabled in debug mode');
      return;
    }*/

    await Aptabase.init(_appKey);
    _isInitialized = true;
  }

  /// تتبع حدث عام مع خصائص اختيارية
  static Future<void> trackEvent(String eventName, [Map<String, dynamic>? props]) async {
    if (!_isInitialized) return;

    try {
      await Aptabase.instance.trackEvent(eventName, props);
    } catch (e) {
      debugPrint('Aptabase track error: $e');
    }
  }

  // ========== الأحداث المطلوبة ==========

  /// تتبع بدء الجلسة
  static Future<void> trackSessionStart() async {
    await trackEvent('session_start');
  }

  /// تتبع انتهاء الجلسة
  static Future<void> trackSessionEnd() async {
    await trackEvent('session_end');
  }

  /// تتبع النقر على عنصر من متابعة المشاهدة
  static Future<void> trackContinueWatchingClick({
    required int mediaId,
    required String mediaType,
    required String title,
    int? season,
    int? episode,
  }) async {
    await trackEvent('continue_watching_click', {
      'media_id': mediaId,
      'media_type': mediaType,
      'title': title,
      if (season != null) 'season': season,
      if (episode != null) 'episode': episode,
    });
  }
}