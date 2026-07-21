import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// خدمة تخزين آمنة للمفاتيح والبيانات الحساسة
class SecureStorage {
  static const String _keyPrefix = 'zora_secure_';
  static const MethodChannel _channel = MethodChannel('com.zora.app/secure');
  
  /// حفظ قيمة مشفرة
  static Future<void> write(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    // في الإنتاج، استخدم flutter_secure_storage
    final encoded = base64.encode(utf8.encode(value));
    await prefs.setString('$_keyPrefix$key', encoded);
  }
  
  /// قراءة قيمة مشفرة
  static Future<String?> read(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString('$_keyPrefix$key');
    if (encoded == null) return null;
    try {
      return utf8.decode(base64.decode(encoded));
    } catch (e) {
      return null;
    }
  }
  
  /// حذف قيمة
  static Future<void> delete(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_keyPrefix$key');
  }
  
  /// حفظ بيانات Trakt Token
  static Future<void> saveTraktToken(String token) async {
    await write('trakt_token', token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('trakt_logged_in', true);
  }
  
  /// الحصول على Trakt Token
  static Future<String?> getTraktToken() async {
    return await read('trakt_token');
  }
  
  /// حذف Trakt Token
  static Future<void> deleteTraktToken() async {
    await delete('trakt_token');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('trakt_logged_in', false);
    await prefs.remove('trakt_user_name');
    await prefs.remove('trakt_user_avatar');
  }
  
  /// التحقق من تسجيل الدخول في Trakt
  static Future<bool> isTraktLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('trakt_logged_in') ?? false;
  }
  
  /// حفظ Wyzie API Key
  static Future<void> saveWyzieApiKey(String key) async {
    await write('wyzie_api_key', key);
  }
  
  /// الحصول على Wyzie API Key
  static Future<String?> getWyzieApiKey() async {
    return await read('wyzie_api_key');
  }
}