import '../../../services/trakt_service.dart';
import '../../../services/storage_service.dart';

/// متحكم حفظ واستعادة تقدم المشاهدة
class ProgressController {
  /// حفظ موقع استكمال المشاهدة
  Future<void> saveProgress({
    required int mediaId,
    required String mediaType,
    required int season,
    required int episode,
    required double position,
    String? title,
    String? posterPath,
    String? backdropPath,
  }) async {
    // حفظ محلياً
    await StorageService.saveResumePosition(
      mediaId: mediaId,
      mediaType: mediaType,
      season: season,
      episode: episode,
      position: position,
    );

    // تحديث قائمة متابعة المشاهدة
    final continueWatching = await StorageService.getContinueWatching();
    final index = continueWatching.indexWhere(
      (i) => i['id'] == mediaId && i['mediaType'] == mediaType,
    );

    final item = {
      'id': mediaId,
      'title': title ?? '',
      'mediaType': mediaType,
      'poster_path': posterPath,
      'backdrop_path': backdropPath,
      'position': position * 100,
      'last_s': season,
      'last_e': episode,
    };

    if (index != -1) {
      final existing = continueWatching[index];
      item['title'] = existing['title'] ?? title ?? '';
      item['poster_path'] = existing['poster_path'] ?? posterPath;
      item['backdrop_path'] = existing['backdrop_path'] ?? backdropPath;
      continueWatching[index] = item;
    } else {
      continueWatching.add(item);
    }

    await StorageService.saveContinueWatching(continueWatching);

    // مزامنة مع Trakt
    if (await TraktService.isLoggedIn()) {
      TraktService.syncPlaybackProgress(
        mediaId,
        mediaType,
        position * 100,
        season: season,
        episode: episode,
      );
    }
  }

  /// استعادة موقع المشاهدة
  Future<double> getResumePosition({
    required int mediaId,
    required String mediaType,
    required int season,
    required int episode,
  }) async {
    // التحقق محلياً
    final localProgress = await StorageService.getResumePosition(
      mediaId: mediaId,
      mediaType: mediaType,
      season: season,
      episode: episode,
    );

    if (localProgress > 0.05 && localProgress < 0.95) return localProgress;

    // التحقق من Trakt
    if (await TraktService.isLoggedIn()) {
      final traktProgress = await TraktService.getPlaybackProgress(
        mediaId,
        mediaType,
        season: season,
        episode: episode,
      );
      return traktProgress ?? 0.0;
    }
    return 0.0;
  }
}
