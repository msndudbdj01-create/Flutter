import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../../utils/config.dart';
import 'package:flutter/material.dart';

/// متحكم استخراج روابط الفيديو والترجمة من WebView
class WebExtractorController {
  InAppWebViewController? webController;

  // قائمة domains المحظورة (إعلانات)
  static const List<String> _blockedDomains = [
    'doubleclick.net',
    'googleadservices.com',
    'googlesyndication.com',
    '1xbet',
    'bet',
    'ads',
    'popunder',
    'popup',
    'banner',
    'click',
  ];

  /// إنشاء WebView مخفي لاستخراج الروابط
  InAppWebView buildWebView({
    required int mediaId,
    required bool isMovie,
    required int season,
    required int episode,
  }) {
    final url = isMovie
        ? "${AppConfig.vidkingBaseUrl}/movie/$mediaId"
        : "${AppConfig.vidkingBaseUrl}/tv/$mediaId/$season/$episode";

    return InAppWebView(
      key: ValueKey("wv_${season}_$episode"),
      initialUrlRequest: URLRequest(url: WebUri(url)),
      onWebViewCreated: (controller) => webController = controller,
      onLoadResource: (_, resource) => _handleWebResource(resource),
    );
  }

  /// معالجة موارد الويب المستخرجة
  void _handleWebResource(dynamic resource) {
    final url = resource.url.toString();

    // تجاهل الإعلانات
    if (_isAdUrl(url)) return;

    // استخراج روابط الفيديو
    if (url.contains(".m3u8") || url.contains(".mp4")) {
      _handleVideoUrl(url);
    }

    // استخراج روابط الترجمة
    if (url.contains(".vtt") || url.contains(".srt")) {
      _handleSubtitleUrl(url);
    }
  }

  /// التحقق مما إذا كان الرابط إعلاناً
  bool _isAdUrl(String url) {
    final lowerUrl = url.toLowerCase();
    return _blockedDomains.any((domain) => lowerUrl.contains(domain));
  }

  // سيتم تعيين هذه الدوال من الخارج (callbacks)
  Function(String url)? onVideoUrlFound;
  Function(String quality)? onQualityDetected;
  Function(String url)? onSubtitleUrlFound;

  void _handleVideoUrl(String url) {
    String quality = "Auto";
    if (url.contains("1080")) {
      quality = "1080p";
    } else if (url.contains("720")) {
      quality = "720p";
    } else if (url.contains("480")) {
      quality = "480p";
    } else if (url.contains("360")) {
      quality = "360p";
    }

    onQualityDetected?.call(quality);
    onVideoUrlFound?.call(url);
  }

  void _handleSubtitleUrl(String url) {
    onSubtitleUrlFound?.call(url);
  }

  /// تنظيف الموارد
  void dispose() {
    webController = null;
  }
}
