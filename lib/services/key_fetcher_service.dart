import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// خدمة لجلب المفاتيح من URLs التي تمنع الطلبات المباشرة
class KeyFetcherService {
  static final KeyFetcherService _instance = KeyFetcherService._internal();
  factory KeyFetcherService() => _instance;
  KeyFetcherService._internal();

  InAppWebViewController? _webViewController;
  Completer<String?>? _completer;
  Timer? _timeoutTimer;
  OverlayEntry? _overlayEntry;

  /// جلب محتوى نصي من URL باستخدام WebView مخفي
  /// يتم إتلاف WebView فور الحصول على النتيجة
  Future<String?> fetchContent({
    required String url,
    required BuildContext context,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    // إنشاء completer جديد
    _completer = Completer<String?>();

    // إعداد مؤقت timeout
    _timeoutTimer = Timer(timeout, () {
      if (_completer != null && !_completer!.isCompleted) {
        print('⏰ KeyFetcher timeout for URL: $url');
        _completer?.complete(null);
        _disposeWebView();
        _removeOverlay();
      }
    });

    // إنشاء Overlay Entry مع WebView مخفي
    _overlayEntry = OverlayEntry(
      builder: (context) => _buildHiddenWebView(url),
    );

    try {
      // الحصول على Overlay State وإضافة الـ Overlay
      final overlayState = Overlay.of(context);
      overlayState.insert(_overlayEntry!);

      // انتظار النتيجة
      final result = await _completer!.future;

      // تنظيف الموارد
      _removeOverlay();
      _disposeWebView();

      return result;
    } catch (e) {
      print('❌ KeyFetcher error: $e');
      _removeOverlay();
      _disposeWebView();
      return null;
    }
  }

  Widget _buildHiddenWebView(String url) {
    return Container(
      width: 1,
      height: 1,
      child: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(url)),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          domStorageEnabled: true,
          cacheEnabled: false,
          useShouldOverrideUrlLoading: true,
          transparentBackground: true,
        ),
        shouldOverrideUrlLoading: (controller, navigationAction) async {
          return NavigationActionPolicy.ALLOW;
        },
        onWebViewCreated: (controller) {
          _webViewController = controller;
          print('🌐 KeyFetcher WebView created for: $url');
        },
        onLoadStop: (controller, loadedUrl) async {
          print('✅ KeyFetcher WebView loaded: $loadedUrl');
          await _extractContent(controller);
        },
        onLoadError: (controller, url, code, message) {
          print('❌ KeyFetcher WebView error: $code - $message');
          if (_completer != null && !_completer!.isCompleted) {
            _completer?.complete(null);
          }
          _disposeWebView();
          _removeOverlay();
        },
      ),
    );
  }

  Future<void> _extractContent(InAppWebViewController controller) async {
    try {
      // محاولة الحصول على النص من body
      final content = await controller.evaluateJavascript(
          source: "document.body ? document.body.innerText : ''");

      if (content != null && content.toString().isNotEmpty) {
        String textContent = content.toString().trim();
        if (textContent.isNotEmpty) {
          print('✅ KeyFetcher extracted content (${textContent.length} chars)');
          if (_completer != null && !_completer!.isCompleted) {
            _completer?.complete(textContent);
          }
          _disposeWebView();
          _removeOverlay();
          return;
        }
      }

      // محاولة بديلة: الحصول على HTML واستخراج النص
      final html = await controller.getHtml();
      if (html != null && html.isNotEmpty) {
        // إزالة علامات HTML
        final cleanText = _stripHtmlTags(html).trim();
        if (cleanText.isNotEmpty) {
          print(
              '✅ KeyFetcher extracted content from HTML (${cleanText.length} chars)');
          if (_completer != null && !_completer!.isCompleted) {
            _completer?.complete(cleanText);
          }
          _disposeWebView();
          _removeOverlay();
          return;
        }
      }

      // لم يتم العثور على محتوى
      print('❌ KeyFetcher no content found');
      if (_completer != null && !_completer!.isCompleted) {
        _completer?.complete(null);
      }
      _disposeWebView();
      _removeOverlay();
    } catch (e) {
      print('❌ KeyFetcher extract error: $e');
      if (_completer != null && !_completer!.isCompleted) {
        _completer?.complete(null);
      }
      _disposeWebView();
      _removeOverlay();
    }
  }

  String _stripHtmlTags(String html) {
    // إزالة علامات HTML
    String result = html.replaceAll(RegExp(r'<[^>]*>'), '');
    // إزالة المسافات الزائدة
    result = result.replaceAll(RegExp(r'\s+'), ' ').trim();
    return result;
  }

  void _disposeWebView() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;

    if (_webViewController != null) {
      try {
        // dispose() هي void وليس Future، لا تستخدم await
        _webViewController?.dispose();
      } catch (e) {
        print('⚠️ Error disposing WebView: $e');
      }
      _webViewController = null;
    }
  }

  void _removeOverlay() {
    if (_overlayEntry != null) {
      try {
        _overlayEntry?.remove();
      } catch (e) {
        print('⚠️ Error removing overlay: $e');
      }
      _overlayEntry = null;
    }
  }

  void dispose() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    _disposeWebView();
    _removeOverlay();
    _completer = null;
  }
}
