import '../../../services/subtitle_service.dart';
import '../../../services/storage_service.dart';
import '../models/subtitle_entry.dart';

class SubtitleController {
  static final Map<String, List<SubtitleEntry>> _subtitleCache = {};
  static final Map<String, String> _rawSubtitleCache = {};
  static final Map<String, int> _lineCountCache = {};

  Future<List<Map<String, dynamic>>> fetchSubdlSubtitles({
    required int tmdbId,
    required bool isMovie,
    required int season,
    required int episode,
  }) async {
    print(
        '📡 Fetching Subdl subtitles for TMDB ID: $tmdbId, Season: $season, Episode: $episode');

    final subtitles = isMovie
        ? await SubtitleService.searchMovieSubtitles(tmdbId: tmdbId)
        : await SubtitleService.searchTVSubtitles(
            tmdbId: tmdbId,
            season: season,
            episode: episode,
          );

    // طباعة تفاصيل النتائج للتصحيح
    for (var sub in subtitles) {
      print(
          '   - ${sub['language']} (S${sub['season']}:E${sub['episode']}) - rating: ${sub['rating']}');
    }

    return subtitles;
  }

  Future<Map<String, dynamic>?> loadBestAutoSubtitle({
    required int tmdbId,
    required bool isMovie,
    required int season,
    required int episode,
  }) async {
    try {
      print('🔍 Searching for best auto subtitle from Subdl...');
      final subtitles = await fetchSubdlSubtitles(
        tmdbId: tmdbId,
        isMovie: isMovie,
        season: season,
        episode: episode,
      );

      if (subtitles.isEmpty) {
        print('❌ No subtitles found from Subdl');
        return null;
      }

      // البحث عن ترجمة تطابق الموسم والحلقة بدقة
      Map<String, dynamic>? exactMatch;
      for (var sub in subtitles) {
        if (sub['season'] == season && sub['episode'] == episode) {
          exactMatch = sub;
          break;
        }
      }

      final bestSubtitle = exactMatch ?? subtitles.first;
      final language = bestSubtitle['language']?.toString() ?? 'unknown';
      final rating = bestSubtitle['rating']?.toString() ?? '0';
      final subSeason = bestSubtitle['season'];
      final subEpisode = bestSubtitle['episode'];

      print('✅ Auto-selected best subtitle: $language (rating: $rating)');
      if (subSeason != null && subEpisode != null) {
        print('   Matches S$subSeason:E$subEpisode');
      } else if (bestSubtitle['full_season'] == true) {
        print('   This is a full season pack');
      }

      return bestSubtitle;
    } catch (e) {
      print('❌ Error loading best auto subtitle: $e');
      return null;
    }
  }

  Future<int> _countSubtitleLinesFromContent(String content) async {
    if (content.isEmpty) return 0;

    if (content.contains('WEBVTT')) {
      final lines = content.split('\n');
      int cueCount = 0;
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].contains('-->')) cueCount++;
      }
      return cueCount;
    } else {
      final blocks = content.split(RegExp(r'\n\s*\n'));
      return blocks.where((block) => block.trim().isNotEmpty).length;
    }
  }

  Future<List<SubtitleEntry>?> loadSubtitle(String url) async {
    if (_subtitleCache.containsKey(url)) {
      print('📦 Using cached subtitle: $url');
      return _subtitleCache[url];
    }

    try {
      String? content = await SubtitleService.downloadSubtitle(url);

      if (content != null && content.isNotEmpty) {
        _rawSubtitleCache[url] = content;
        final lineCount = await _countSubtitleLinesFromContent(content);
        _lineCountCache[url] = lineCount;
        print('📊 Subtitle has $lineCount lines');

        final parsed = content.contains('WEBVTT')
            ? _parseVTT(content)
            : _parseSRT(content);

        _subtitleCache[url] = parsed;
        return parsed;
      }
    } catch (e) {
      print('❌ Error loading subtitle: $e');
    }
    return null;
  }

  Future<void> preloadNextEpisodeSubtitles({
    required int tmdbId,
    required int season,
    required int episode,
  }) async {
    try {
      final subtitles = await SubtitleService.searchTVSubtitles(
        tmdbId: tmdbId,
        season: season,
        episode: episode,
      );

      if (subtitles.isNotEmpty) {
        final firstSub = subtitles.first;
        final url = firstSub['url']?.toString();
        if (url != null && url.isNotEmpty) {
          await loadSubtitle(url);
          print('📦 Preloaded subtitle for next episode S$season:E$episode');
        }
      }
    } catch (e) {
      print('❌ Error preloading subtitles: $e');
    }
  }

  static void clearCache() {
    _subtitleCache.clear();
    _rawSubtitleCache.clear();
    _lineCountCache.clear();
  }

  static int get cacheSize => _subtitleCache.length;

  static Future<SubtitleSettings> loadSettings() async {
    try {
      final fontSize = await StorageService.getSubtitleTextSize();
      final textColorValue = await StorageService.getSubtitleTextColorValue();
      final bgColorValue = await StorageService.getSubtitleBgColorValue();
      final fontFamily = await StorageService.getSubtitleFont();
      final position = await StorageService.getSubtitlePosition();

      return SubtitleSettings(
        fontSize: fontSize,
        textColorValue: textColorValue,
        bgColorValue: bgColorValue,
        fontFamily: fontFamily,
        position: position,
      );
    } catch (e) {
      return const SubtitleSettings();
    }
  }

  List<SubtitleEntry> _parseSRT(String content) {
    final subs = <SubtitleEntry>[];
    final blocks = content.split(RegExp(r'\n\s*\n'));

    for (var block in blocks) {
      final lines = block.trim().split('\n');
      if (lines.length < 2) continue;

      final timeLine =
          lines.firstWhere((l) => l.contains("-->"), orElse: () => "");
      if (timeLine.isEmpty) continue;

      final times = timeLine.split(' --> ');
      if (times.length < 2) continue;

      final text = lines.sublist(lines.indexOf(timeLine) + 1).join('\n');
      subs.add(SubtitleEntry(
        start: _parseDuration(times[0].trim()),
        end: _parseDuration(times[1].trim()),
        text: text.replaceAll(RegExp(r'<[^>]*>'), ''),
      ));
    }
    return subs;
  }

  List<SubtitleEntry> _parseVTT(String content) {
    final subs = <SubtitleEntry>[];
    final lines = content.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (!line.contains('-->')) continue;

      final times = line.split(' --> ');
      if (times.length < 2) continue;

      String text = '';
      int j = i + 1;
      while (j < lines.length &&
          lines[j].trim().isNotEmpty &&
          !lines[j].contains('-->')) {
        if (text.isNotEmpty) text += '\n';
        text += lines[j].trim();
        j++;
      }

      text = text.replaceAll(RegExp(r'<[^>]*>'), '');
      if (text.isNotEmpty) {
        subs.add(SubtitleEntry(
          start: _parseDuration(times[0].trim()),
          end: _parseDuration(times[1].trim()),
          text: text,
        ));
      }
    }
    return subs;
  }

  Duration _parseDuration(String hms) {
    hms = hms.replaceAll(',', '.').trim();
    final parts = hms.split(':');

    if (parts.length == 3) {
      final secondsParts = parts[2].split('.');
      return Duration(
        hours: int.parse(parts[0]),
        minutes: int.parse(parts[1]),
        seconds: int.parse(secondsParts[0]),
        milliseconds: secondsParts.length > 1
            ? int.parse(secondsParts[1].padRight(3, '0').substring(0, 3))
            : 0,
      );
    }
    return Duration.zero;
  }

  String getActiveSubtitleText(
    Duration position,
    List<SubtitleEntry> subtitles,
  ) {
    for (var sub in subtitles) {
      if (position >= sub.start && position <= sub.end) {
        return sub.text;
      }
    }
    return "";
  }

  SubtitleSource addSubdlSubtitleToList(Map<String, dynamic> sub) {
    final langCode = sub['language']?.toString() ?? 'unknown';
    final langName = SubtitleService.getLanguageNameInArabic(langCode);
    final fileName = sub['file_name']?.toString() ?? 'ترجمة';
    final format = sub['format']?.toString() ?? 'srt';
    final source = sub['source']?.toString() ?? 'Subdl';
    final rating = (sub['rating'] as num?)?.toDouble() ?? 0.0;
    final fullSeason = sub['full_season'] == true;
    final subSeason = sub['season'];
    final subEpisode = sub['episode'];

    String name = '[$source] $langName';
    if (rating > 0) name += ' ⭐${rating.toStringAsFixed(1)}';

    if (fullSeason) {
      name += ' 📦 الموسم الكامل';
    } else if (subSeason != null && subEpisode != null) {
      name += ' - S$subSeason:E$subEpisode';
    }

    name += ' - $fileName.${format == 'zip' ? 'srt' : format}';

    final url = sub['url']?.toString() ?? '';

    return SubtitleSource(
      name: name,
      url: url,
      lang: langCode,
      format: format,
    );
  }
}
