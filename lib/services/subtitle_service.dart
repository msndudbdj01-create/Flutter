import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'key_fetcher_service.dart';
import '../utils/config.dart';

class SubtitleService {
  static const String _subdlApiUrl = AppConfig.subdlBaseUrl;
  static const String _subdlDownloadBaseUrl = AppConfig.subdlDownloadBaseUrl;

  // رابط GitHub Gist للمفاتيح
  static const String _keysUrl =
      'https://gist.githubusercontent.com/msndudbdj01-create/f6346b02df5b1fbb3dc7fdfa9c1ae0e1/raw/57fbfb433497a92f141485a0807be95809fe68d6/keys.txt';

  static const String _cachedKeysKey = 'subdl_api_keys';
  static const String _lastUpdateKey = 'subdl_keys_last_update';

  static List<String> _apiKeys = [];
  static String? _currentApiKey;
  static DateTime? _lastUpdateTime;

  // مدة التخزين المؤقت: 24 ساعة
  static const Duration _cacheDuration = Duration(hours: 24);

  // BuildContext لحاجة KeyFetcherService
  static BuildContext? _context;

  // دالة لتعيين الـ Context (يتم استدعاؤها من MaterialApp)
  static void setContext(BuildContext context) {
    _context = context;
  }

  static Future<List<String>> _fetchApiKeys() async {
    final prefs = await SharedPreferences.getInstance();

    // التحقق من وجود مفاتيح مخزنة ولم تنته صلاحيتها
    final lastUpdateStr = prefs.getString(_lastUpdateKey);
    if (lastUpdateStr != null) {
      _lastUpdateTime = DateTime.tryParse(lastUpdateStr);
      if (_lastUpdateTime != null &&
          DateTime.now().difference(_lastUpdateTime!) < _cacheDuration) {
        final cachedKeys = prefs.getStringList(_cachedKeysKey);
        if (cachedKeys != null && cachedKeys.isNotEmpty) {
          print('📦 Using cached API keys (${cachedKeys.length} keys)');
          _apiKeys = cachedKeys;
          return _apiKeys;
        }
      }
    }

    // جلب المفاتيح باستخدام KeyFetcherService (WebView مخفي)
    String? content;

    // المحاولة باستخدام WebView
    if (_context != null) {
      try {
        print('🌐 Fetching API keys using WebView...');
        final fetcher = KeyFetcherService();
        content = await fetcher.fetchContent(
          url: _keysUrl,
          context: _context!,
          timeout: const Duration(seconds: 20),
        );
      } catch (e) {
        print('❌ WebView fetch error: $e');
      }
    }

    // محاولة HTTP مباشرة كبديل
    if (content == null || content.isEmpty) {
      try {
        print('🔄 Trying HTTP fallback...');
        final response = await http.get(
          Uri.parse(_keysUrl),
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            'Accept': 'text/plain',
          },
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          content = response.body;
          print('✅ HTTP fallback succeeded');
        }
      } catch (e) {
        print('❌ HTTP fallback failed: $e');
      }
    }

    if (content != null && content.isNotEmpty) {
      final keys = content
          .split('\n')
          .map((line) => line.trim())
          .where((line) =>
              line.isNotEmpty &&
              !line.startsWith('#') &&
              line.startsWith('subdl_'))
          .toList();

      if (keys.isNotEmpty) {
        print('✅ Fetched ${keys.length} API keys');
        _apiKeys = keys;
        // تحديث التخزين المؤقت
        await prefs.setStringList(_cachedKeysKey, keys);
        await prefs.setString(_lastUpdateKey, DateTime.now().toIso8601String());
        return keys;
      }
    }

    // استخدام المفاتيح المخزنة مؤقتاً إذا كانت موجودة
    final cachedKeys = prefs.getStringList(_cachedKeysKey);
    if (cachedKeys != null && cachedKeys.isNotEmpty) {
      print('⚠️ Using cached API keys (${cachedKeys.length} keys)');
      _apiKeys = cachedKeys;
      return _apiKeys;
    }

    throw Exception('No API keys available');
  }

  static Future<String> getRandomApiKey() async {
    if (_apiKeys.isEmpty) {
      await _fetchApiKeys();
    }

    if (_apiKeys.isEmpty) {
      throw Exception('No API keys available');
    }

    final random = Random();
    final index = random.nextInt(_apiKeys.length);
    _currentApiKey = _apiKeys[index];
    print('🔑 Using API key #${index + 1}/${_apiKeys.length}');
    return _currentApiKey!;
  }

  static Future<void> refreshApiKeys() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedKeysKey);
    await prefs.remove(_lastUpdateKey);
    _apiKeys.clear();
    await _fetchApiKeys();
  }

  static Future<String> getPreferredLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('subtitle_language') ?? 'ar';
  }

  static String _convertLanguageCode(String langCode) {
    return langCode.toUpperCase();
  }

  static String getLanguageNameInArabic(String langCode) {
    final lang = langCode.toLowerCase();
    switch (lang) {
      case 'ar':
        return 'العربية';
      case 'en':
        return 'الإنجليزية';
      case 'fr':
        return 'الفرنسية';
      case 'es':
        return 'الإسبانية';
      case 'de':
        return 'الألمانية';
      case 'it':
        return 'الإيطالية';
      case 'tr':
        return 'التركية';
      case 'fa':
        return 'الفارسية';
      case 'ur':
        return 'الأردية';
      case 'hi':
        return 'الهندية';
      case 'pt':
        return 'البرتغالية';
      case 'ru':
        return 'الروسية';
      case 'zh':
        return 'الصينية';
      case 'ja':
        return 'اليابانية';
      case 'ko':
        return 'الكورية';
      default:
        return lang.toUpperCase();
    }
  }

  static Future<List<Map<String, dynamic>>> searchSubtitles({
    required int tmdbId,
    required String mediaType,
    int? season,
    int? episode,
  }) async {
    List<Map<String, dynamic>> allSubtitles = [];

    final preferredLanguage = await getPreferredLanguage();
    final apiKey = await getRandomApiKey();

    print(
        '🔍 Searching Subdl subtitles for TMDB ID: $tmdbId, Type: $mediaType');
    print('🎯 Season: $season, Episode: $episode');
    print('🌍 Preferred language: $preferredLanguage');

    if (apiKey.isEmpty) {
      print('⚠️ No Subdl API Key available');
      return [];
    }

    if (mediaType == 'movie') {
      final movieResults = await _searchMovieSubtitles(
        tmdbId: tmdbId,
        language: _convertLanguageCode(preferredLanguage),
        apiKey: apiKey,
      );
      allSubtitles.addAll(movieResults);
    } else {
      final tvResults = await _searchTVSubtitles(
        tmdbId: tmdbId,
        season: season ?? 1,
        episode: episode ?? 1,
        language: _convertLanguageCode(preferredLanguage),
        apiKey: apiKey,
      );
      allSubtitles.addAll(tvResults);
    }

    // فلترة دقيقة للتأكد من مطابقة الموسم والحلقة
    if (mediaType == 'tv' && season != null && episode != null) {
      final beforeFilter = allSubtitles.length;
      allSubtitles = allSubtitles.where((sub) {
        final subSeason = sub['season'] as int?;
        final subEpisode = sub['episode'] as int?;

        if (sub['full_season'] == true) return true;
        if (subSeason != null && subEpisode != null) {
          return subSeason == season && subEpisode == episode;
        }
        return true;
      }).toList();

      print(
          '🎯 Filtered from $beforeFilter to ${allSubtitles.length} subtitles');
    }

    if (allSubtitles.isEmpty && preferredLanguage != 'en') {
      print('🔄 Trying English as fallback...');
      final englishResults = mediaType == 'movie'
          ? await _searchMovieSubtitles(
              tmdbId: tmdbId, language: 'EN', apiKey: apiKey)
          : await _searchTVSubtitles(
              tmdbId: tmdbId,
              season: season ?? 1,
              episode: episode ?? 1,
              language: 'EN',
              apiKey: apiKey,
            );

      if (englishResults.isNotEmpty) {
        print('✅ Found ${englishResults.length} English subtitles');
        allSubtitles.addAll(englishResults);
      }
    }

    allSubtitles = _sortSubtitlesByQuality(allSubtitles);
    return allSubtitles;
  }

  static Future<List<Map<String, dynamic>>> _searchMovieSubtitles({
    required int tmdbId,
    required String language,
    required String apiKey,
  }) async {
    try {
      final uri = Uri.parse(_subdlApiUrl).replace(
        queryParameters: {
          'api_key': apiKey,
          'tmdb_id': tmdbId.toString(),
          'type': 'movie',
          'unpack': '1',
          'languages': language,
        },
      );

      print('🌐 Subdl API URL: ${uri.toString().replaceAll(apiKey, '***')}');

      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json', 'User-Agent': 'Zora/1.0'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] != true) {
          print('❌ Subdl API Error: ${data['error'] ?? 'Unknown error'}');
          return [];
        }
        final subtitlesList = data['subtitles'] as List<dynamic>? ?? [];
        print('📦 Found ${subtitlesList.length} subtitles');
        return subtitlesList
            .map((item) =>
                _formatSubtitleItem(item as Map<String, dynamic>, 'Subdl'))
            .toList();
      } else if (response.statusCode == 401) {
        print('❌ Subdl Error: Invalid API Key');
        await refreshApiKeys();
      }
    } catch (e) {
      print('❌ Subdl Exception: $e');
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> _searchTVSubtitles({
    required int tmdbId,
    required int season,
    required int episode,
    required String language,
    required String apiKey,
  }) async {
    List<Map<String, dynamic>> results = [];

    try {
      final uri = Uri.parse(_subdlApiUrl).replace(
        queryParameters: {
          'api_key': apiKey,
          'tmdb_id': tmdbId.toString(),
          'type': 'tv',
          'season_number': season.toString(),
          'episode_number': episode.toString(),
          'unpack': '1',
          'languages': language,
        },
      );

      print('🌐 Subdl API URL: ${uri.toString().replaceAll(apiKey, '***')}');

      var response = await http.get(
        uri,
        headers: {'Accept': 'application/json', 'User-Agent': 'Zora/1.0'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['status'] == true && data['subtitles'] != null) {
          final subtitles = data['subtitles'] as List;
          if (subtitles.isNotEmpty) {
            print(
                '✅ Found ${subtitles.length} subtitles for S$season:E$episode');
            final exactMatches = subtitles.where((sub) {
              final subSeason = sub['season'] as int?;
              final subEpisode = sub['episode'] as int?;
              return subSeason == season && subEpisode == episode;
            }).toList();

            if (exactMatches.isNotEmpty) {
              results.addAll(exactMatches.map((item) =>
                  _formatSubtitleItem(item as Map<String, dynamic>, 'Subdl')));
            } else {
              results.addAll(subtitles.map((item) =>
                  _formatSubtitleItem(item as Map<String, dynamic>, 'Subdl')));
            }
          }
        }
      }

      if (results.isEmpty) {
        print('🔄 Trying season pack...');
        final seasonUri = Uri.parse(_subdlApiUrl).replace(
          queryParameters: {
            'api_key': apiKey,
            'tmdb_id': tmdbId.toString(),
            'type': 'tv',
            'season_number': season.toString(),
            'unpack': '1',
            'languages': language,
            'full_season': '1',
          },
        );

        response = await http.get(
          seasonUri,
          headers: {'Accept': 'application/json', 'User-Agent': 'Zora/1.0'},
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['status'] == true && data['subtitles'] != null) {
            final subtitles = data['subtitles'] as List;
            if (subtitles.isNotEmpty) {
              print('✅ Found season pack for season $season');
              results.addAll(subtitles.map((item) =>
                  _formatSubtitleItem(item as Map<String, dynamic>, 'Subdl')));
            }
          }
        }
      }

      return results;
    } catch (e) {
      print('❌ Subdl Exception: $e');
      return [];
    }
  }

  static Map<String, dynamic> _formatSubtitleItem(
      Map<String, dynamic> item, String source) {
    List<Map<String, dynamic>> unpackedFiles = [];
    if (item.containsKey('unpack_files') && item['unpack_files'] is List) {
      for (var file in item['unpack_files'] as List) {
        unpackedFiles.add({
          'file_n_id': file['file_n_id'],
          'name': file['name'],
          'season': file['season'],
          'episode': file['episode'],
          'language': file['language'],
          'hi': file['hi'],
          'format': file['format'],
          'size': file['size'],
          'url': '$_subdlDownloadBaseUrl${file['url']}',
        });
      }
    }

    String downloadUrl = '';
    if (item.containsKey('url') && item['url'] != null) {
      downloadUrl = '$_subdlDownloadBaseUrl${item['url']}';
    }

    final isZip = downloadUrl.endsWith('.zip');
    final fullSeason = item['full_season'] == true;

    int? seasonNum = item['season'] as int?;
    int? episodeNum = item['episode'] as int?;

    if ((seasonNum == null || episodeNum == null) && unpackedFiles.isNotEmpty) {
      final firstFile = unpackedFiles.first;
      seasonNum = firstFile['season'] as int?;
      episodeNum = firstFile['episode'] as int?;
    }

    return {
      'id': item['sd_id'] ?? item['id'] ?? '',
      'url': downloadUrl,
      'language': item['language'] ?? 'unknown',
      'file_name': item['name'] ?? item['release_name'] ?? 'Subtitle',
      'format': item['format'] ?? (isZip ? 'zip' : 'srt'),
      'source': source,
      'download_count': item['downloads'] ?? 0,
      'rating': item['rating'] ?? 0.0,
      'hearing_impaired': item['hi'] ?? false,
      'season': seasonNum,
      'episode': episodeNum,
      'full_season': fullSeason,
      'unpack_files': unpackedFiles,
      'is_zip': isZip,
    };
  }

  static List<Map<String, dynamic>> _sortSubtitlesByQuality(
      List<Map<String, dynamic>> subtitles) {
    final sorted = List<Map<String, dynamic>>.from(subtitles);
    sorted.sort((a, b) {
      final aHasEpisode = a['episode'] != null && a['full_season'] != true;
      final bHasEpisode = b['episode'] != null && b['full_season'] != true;
      if (aHasEpisode && !bHasEpisode) return -1;
      if (!aHasEpisode && bHasEpisode) return 1;

      final aFullSeason = a['full_season'] == true;
      final bFullSeason = b['full_season'] == true;
      if (aFullSeason && !bFullSeason) return 1;
      if (!aFullSeason && bFullSeason) return -1;

      final aRating = (a['rating'] as num?)?.toDouble() ?? 0.0;
      final bRating = (b['rating'] as num?)?.toDouble() ?? 0.0;
      if (aRating != bRating) return bRating.compareTo(aRating);

      final aDownloads = (a['download_count'] as num?)?.toInt() ?? 0;
      final bDownloads = (b['download_count'] as num?)?.toInt() ?? 0;
      return bDownloads.compareTo(aDownloads);
    });
    return sorted;
  }

  static Future<String?> _extractSubtitleFromZip(String zipPath) async {
    try {
      final bytes = File(zipPath).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);
      final subtitleExtensions = ['.srt', '.vtt', '.sub', '.ass', '.ssa'];

      for (var file in archive) {
        if (file.isFile) {
          final fileName = file.name.toLowerCase();
          if (subtitleExtensions.any((ext) => fileName.endsWith(ext))) {
            final content = utf8.decode(file.content as List<int>);
            if (content.isNotEmpty) {
              await File(zipPath).delete();
              return content;
            }
          }
        }
      }
      await File(zipPath).delete();
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<String?> downloadSubtitle(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'Mozilla/5.0', 'Accept': '*/*'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final content = response.bodyBytes;
        final isZip = url.endsWith('.zip') ||
            (content.length > 4 &&
                content[0] == 0x50 &&
                content[1] == 0x4B &&
                content[2] == 0x03 &&
                content[3] == 0x04);

        if (isZip) {
          final tempDir = await getTemporaryDirectory();
          final tempFile = File(
              '${tempDir.path}/temp_${DateTime.now().millisecondsSinceEpoch}.zip');
          await tempFile.writeAsBytes(content);
          return await _extractSubtitleFromZip(tempFile.path);
        }

        final textContent = utf8.decode(content);
        if (_isValidSubtitleContent(textContent)) {
          return textContent;
        }
      }
    } catch (e) {
      print('❌ Download error: $e');
    }
    return null;
  }

  static bool _isValidSubtitleContent(String content) {
    return content.contains('-->') ||
        content.contains('WEBVTT') ||
        content.contains('[Events]') ||
        RegExp(r'\d+\n\d{2}:\d{2}:\d{2},\d{3}').hasMatch(content);
  }

  static Future<String?> downloadUnpackedSubtitle(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'Mozilla/5.0', 'Accept': '*/*'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final content = utf8.decode(response.bodyBytes);
        if (_isValidSubtitleContent(content)) {
          return content;
        }
      }
    } catch (e) {
      print('❌ Download error: $e');
    }
    return null;
  }

  static Future<List<Map<String, dynamic>>> searchMovieSubtitles(
      {required int tmdbId}) async {
    return await searchSubtitles(tmdbId: tmdbId, mediaType: 'movie');
  }

  static Future<List<Map<String, dynamic>>> searchTVSubtitles({
    required int tmdbId,
    required int season,
    required int episode,
  }) async {
    return await searchSubtitles(
      tmdbId: tmdbId,
      mediaType: 'tv',
      season: season,
      episode: episode,
    );
  }
}
