import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/media_model.dart';
import '../utils/constants.dart';

class TmdbService {
  static const String _language = 'en-US';
  static const String _arabicLanguage = 'ar';

  Future<Map<String, String>> get _headers async => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  /// دالة مساعدة لجلب البيانات مع معالجة الأخطاء
  Future<T?> _safeRequest<T>({
    required Future<http.Response> Function() request,
    required T Function(Map<String, dynamic>) parser,
  }) async {
    try {
      final response = await request().timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return parser(data);
      }
    } on TimeoutException {
      debugPrint('Request timeout');
    } catch (e) {
      debugPrint('Request error: $e');
    }
    return null;
  }

  /// دالة مساعدة لجلب القوائم
  Future<List<Media>> _fetchList(
    String endpoint, {
    Map<String, String>? params,
  }) async {
    final uri = Uri.parse('${AppConstants.tmdbBaseUrl}/$endpoint').replace(
      queryParameters: {
        'api_key': AppConstants.tmdbApiKey,
        'language': _language,
        ...?params,
      },
    );

    try {
      final response = await http.get(uri, headers: await _headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List<dynamic>? ?? [];
        return results
            .whereType<Map<String, dynamic>>()
            .map((item) =>
                Media.fromJson(item, _extractMediaType(item, endpoint)))
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetching list: $e');
    }
    return [];
  }

  String _extractMediaType(Map<String, dynamic> item, String endpoint) {
    if (endpoint.contains('movie')) return 'movie';
    if (endpoint.contains('tv')) return 'tv';
    return item['media_type'] as String? ?? 'movie';
  }

  /// البحث
  Future<List<Media>> search(String query) async {
    if (query.trim().isEmpty) return [];

    return _fetchList(
      'search/multi',
      params: {'query': query, 'include_adult': 'false'},
    );
  }

  /// المحتوى الرائج
  Future<List<Media>> getTrending() async {
    return _fetchList('trending/all/day');
  }

  /// أفلام مشهورة
  Future<List<Media>> getPopularMovies() async {
    return _fetchList('movie/popular');
  }

  /// مسلسلات مشهورة
  Future<List<Media>> getPopularTV() async {
    return _fetchList('tv/popular');
  }

  /// أنمي
  Future<List<Media>> getAnimeShows() async {
    return _fetchList(
      'discover/tv',
      params: {'with_genres': '16', 'sort_by': 'popularity.desc'},
    );
  }

  /// تفاصيل فيلم/مسلسل
  Future<Map<String, dynamic>?> getMediaDetails(int id, String type) async {
    final endpoint = type == 'movie' ? 'movie/$id' : 'tv/$id';

    try {
      final uri = Uri.parse('${AppConstants.tmdbBaseUrl}/$endpoint').replace(
        queryParameters: {
          'api_key': AppConstants.tmdbApiKey,
          'language': _language,
          'append_to_response': 'content_ratings,external_ids',
        },
      );

      final response = await http.get(uri, headers: await _headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // محاولة جلب الوصف بالعربية
        try {
          final arUri =
              Uri.parse('${AppConstants.tmdbBaseUrl}/$endpoint').replace(
            queryParameters: {
              'api_key': AppConstants.tmdbApiKey,
              'language': _arabicLanguage,
            },
          );
          final arResponse = await http.get(arUri, headers: await _headers);
          if (arResponse.statusCode == 200) {
            final arData = jsonDecode(arResponse.body);
            final arOverview = arData['overview'] as String?;
            if (arOverview != null && arOverview.isNotEmpty) {
              data['overview'] = arOverview;
            }
          }
        } catch (_) {}

        return data;
      }
    } catch (e) {
      debugPrint('Error getting details: $e');
    }
    return null;
  }

  /// تفاصيل مسلسل (لجلب المواسم)
  Future<Map<String, dynamic>?> getTVDetails(int id) async {
    return getMediaDetails(id, 'tv');
  }

  /// حلقات موسم معين
  Future<List<Map<String, dynamic>>> getSeasonEpisodes(
      int tvId, int seasonNumber) async {
    try {
      final uri =
          Uri.parse('${AppConstants.tmdbBaseUrl}/tv/$tvId/season/$seasonNumber')
              .replace(
        queryParameters: {
          'api_key': AppConstants.tmdbApiKey,
          'language': _language, // استخدام العربية لأسماء الحلقات
        },
      );

      final response = await http.get(uri, headers: await _headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final episodes = data['episodes'] as List<dynamic>? ?? [];
        return episodes.whereType<Map<String, dynamic>>().toList();
      }
    } catch (e) {
      debugPrint('Error getting episodes: $e');
    }
    return [];
  }

  /// الحصول على مواسم المسلسل
  Future<List<Map<String, dynamic>>> getTVSeasons(int tvId) async {
    try {
      final details = await getTVDetails(tvId);
      if (details != null) {
        final seasons = details['seasons'] as List<dynamic>? ?? [];
        return seasons
            .whereType<Map<String, dynamic>>()
            .where((s) => (s['season_number'] as int? ?? -1) > 0)
            .toList();
      }
    } catch (e) {
      debugPrint('Error getting seasons: $e');
    }
    return [];
  }
}

void debugPrint(String message) {
  if (kDebugMode) print('[TMDB] $message');
}

const bool kDebugMode = true;
