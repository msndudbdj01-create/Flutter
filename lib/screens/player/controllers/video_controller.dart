import 'dart:async';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

/// متحكم الفيديو الرئيسي
class VideoController {
  VideoPlayerController? playerController;

  Timer? _controlsTimer;
  bool _isDisposed = false;

  /// دالة استدعاء لتحديث واجهة المستخدم
  VoidCallback? onStateChanged;

  /// تهيئة المشغل
  Future<void> initializePlayer(String url) async {
    playerController?.dispose();
    playerController = null;

    playerController = VideoPlayerController.networkUrl(
      Uri.parse(url),
      httpHeaders: {"Referer": "https://vidking.net/"},
    );

    await playerController!.initialize();
    playerController!.addListener(_playerListener);
  }

  /// مستمع لتغيرات المشغل
  void _playerListener() {
    if (playerController == null || _isDisposed) return;
    onStateChanged?.call();
  }

  /// تشغيل الفيديو
  void play() {
    playerController?.play();
  }

  /// إيقاف الفيديو
  void pause() {
    playerController?.pause();
  }

  /// تبديل التشغيل/الإيقاف
  void togglePlayPause() {
    if (playerController?.value.isPlaying == true) {
      pause();
    } else {
      play();
    }
  }

  /// التقدم للأمام
  void seekForward() {
    if (playerController == null) return;
    final newPosition =
        playerController!.value.position + const Duration(seconds: 10);
    final maxPosition = playerController!.value.duration;
    playerController!
        .seekTo(newPosition > maxPosition ? maxPosition : newPosition);
  }

  /// الرجوع للخلف
  void seekBackward() {
    if (playerController == null) return;
    final newPosition =
        playerController!.value.position - const Duration(seconds: 10);
    playerController!
        .seekTo(newPosition < Duration.zero ? Duration.zero : newPosition);
  }

  /// الانتقال إلى وقت محدد
  void seekTo(Duration position) {
    playerController?.seekTo(position);
  }

  /// بدء مؤقت إخفاء عناصر التحكم
  void startControlsTimer(VoidCallback onTimeout) {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (playerController?.value.isPlaying == true) {
        onTimeout();
      }
    });
  }

  /// إلغاء مؤقت إخفاء عناصر التحكم
  void cancelControlsTimer() {
    _controlsTimer?.cancel();
  }

  /// ضبط وضع ملء الشاشة
  Future<void> setLandscapeMode() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  /// إعادة الوضع العادي
  Future<void> resetOrientation() async {
    try {
      await SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } catch (_) {}
  }

  /// تنسيق الوقت
  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0
        ? "${twoDigits(duration.inHours)}:$minutes:$seconds"
        : "$minutes:$seconds";
  }

  /// تنظيف الموارد
  void disposeController() {
    _isDisposed = true;
    _controlsTimer?.cancel();
    playerController?.removeListener(_playerListener);
    playerController?.dispose();
    playerController = null;
  }
}
