import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:startapp_sdk/startapp.dart';

const bool ENABLE_ADS = true;
const bool USE_TEST_ADS = false; // <-هذه القيمة حسب حاجتك
// ============================================================

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  final StartAppSdk _startAppSdk = StartAppSdk();
  StartAppInterstitialAd? _interstitialAd;
  Completer<bool>? _adLoadCompleter;
  Function()? _onAdClosedCallback;
  bool _isInitialized = false;
  bool _isAdLoading = false;

  /// تهيئة SDK
  static Future<void> init() async {
    await _instance._initialize();
  }

  Future<void> _initialize() async {
    if (_isInitialized) return;

    // إذا كانت الإعلانات معطلة، لا نقوم بتهيئة الـ SDK
    if (!ENABLE_ADS) {
      print('🚫 Ads are DISABLED (ENABLE_ADS = false)');
      _isInitialized = true;
      return;
    }

    try {
      print('🔄 Initializing Start.io SDK...');

      // استخدام وضع الاختبار بناءً على الإعداد
      await _startAppSdk.setTestAdsEnabled(USE_TEST_ADS);

      if (USE_TEST_ADS) {
        print('🧪 TEST ADS mode enabled (USE_TEST_ADS = true)');
      } else {
        print('💰 REAL ADS mode enabled (USE_TEST_ADS = false)');
      }

      _isInitialized = true;
      print('✅ Start.io SDK Initialized');

      Future.delayed(const Duration(seconds: 2), () {
        _loadInterstitialAd();
      });
    } catch (e) {
      print('❌ Start.io init error: $e');
    }
  }

  /// تحميل إعلان بيني
  Future<void> _loadInterstitialAd() async {
    if (!ENABLE_ADS) {
      print('🚫 Ads disabled, skipping ad load');
      return;
    }

    if (!_isInitialized) {
      print('⚠️ Cannot load ad: SDK not initialized');
      return;
    }

    if (_isAdLoading) {
      print('⚠️ Already loading an ad');
      return;
    }

    print('🔄 Loading interstitial ad...');
    _isAdLoading = true;
    _adLoadCompleter = Completer<bool>();

    try {
      _interstitialAd = await _startAppSdk.loadInterstitialAd();

      if (_interstitialAd != null) {
        print('✅✅✅ Interstitial ad LOADED successfully!');
        _adLoadCompleter?.complete(true);
      } else {
        print('⚠️⚠️⚠️ Interstitial ad is NULL - no ad available');
        _adLoadCompleter?.complete(false);

        Future.delayed(const Duration(seconds: 30), () {
          if (_isInitialized) {
            _loadInterstitialAd();
          }
        });
      }
    } catch (e) {
      print('❌❌❌ Failed to load Interstitial ad: $e');
      _interstitialAd = null;
      _adLoadCompleter?.complete(false);

      Future.delayed(const Duration(seconds: 30), () {
        if (_isInitialized) {
          _loadInterstitialAd();
        }
      });
    } finally {
      _isAdLoading = false;
    }
  }

  /// عرض إعلان بيني
  Future<bool> showInterstitialAd(Function() onAdClosed) async {
    print('📱 showInterstitialAd called');

    // إذا كانت الإعلانات معطلة، ننفذ الدالة مباشرة بدون إعلان
    if (!ENABLE_ADS) {
      print('🚫 Ads are DISABLED - playing content directly without ad');
      onAdClosed();
      return false;
    }

    if (!_isInitialized) {
      print('⚠️ SDK not initialized');
      onAdClosed();
      return false;
    }

    if (_interstitialAd == null) {
      print('⚠️ No ad ready - loading new ad and proceeding without ad');
      onAdClosed();
      _loadInterstitialAd();
      return false;
    }

    _onAdClosedCallback = onAdClosed;

    try {
      print('📱 Showing interstitial ad...');
      final shown = await _interstitialAd!.show();

      if (shown) {
        if (USE_TEST_ADS) {
          print('🧪 TEST ad SHOWN successfully!');
        } else {
          print('💰 REAL ad SHOWN successfully!');
        }

        _interstitialAd = null;

        Future.delayed(const Duration(seconds: 2), () {
          _loadInterstitialAd();
        });

        Future.delayed(const Duration(seconds: 5), () {
          print('📱 Ad duration finished, calling callback');
          if (_onAdClosedCallback != null) {
            _onAdClosedCallback!();
            _onAdClosedCallback = null;
          }
        });

        return true;
      } else {
        print('⚠️⚠️⚠️ Ad NOT shown');
        onAdClosed();
        _loadInterstitialAd();
        return false;
      }
    } catch (e) {
      print('❌❌❌ Error showing ad: $e');
      onAdClosed();
      _loadInterstitialAd();
      return false;
    }
  }

  /// هل الإعلان جاهز؟
  bool get isAdReady {
    if (!ENABLE_ADS) return false;
    final ready = _interstitialAd != null;
    print('📊 isAdReady: $ready');
    return ready;
  }

  /// هل SDK جاهز؟
  bool get isInitialized => _isInitialized;

  /// هل الإعلانات مفعلة؟
  bool get isAdsEnabled => ENABLE_ADS;

  /// هل تستخدم إعلانات تجريبية؟
  bool get isUsingTestAds => USE_TEST_ADS;
}
