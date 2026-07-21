import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../utils/config.dart';
import 'secure_storage.dart';

class TraktService {
  static String get _clientId => AppConfig.traktId;
  static String get _clientSecret => AppConfig.traktSecret;
  static String get _redirectUri => AppConfig.redirectUri;
  static const String _baseUrl = AppConfig.traktBaseUrl;

  static Future<Map<String, String>> _getHeaders() async {
    final token = await SecureStorage.getTraktToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'trakt-api-version': '2',
      'trakt-api-key': _clientId,
    };
  }

  static Future<bool> isLoggedIn() async {
    return await SecureStorage.isTraktLoggedIn();
  }

  static Future<void> authorize() async {
    final uri = Uri.https('trakt.tv', '/oauth/authorize', {
      'response_type': 'code',
      'client_id': _clientId,
      'redirect_uri': _redirectUri,
    });
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  static Future<bool> saveToken(String code) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/oauth/token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'code': code,
          'client_id': _clientId,
          'client_secret': _clientSecret,
          'redirect_uri': _redirectUri,
          'grant_type': 'authorization_code',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await SecureStorage.saveTraktToken(data['access_token']);
        return true;
      }
    } catch (e) {
      debugPrint('Token error: $e');
    }
    return false;
  }

  static Future<void> logout() async {
    try {
      final headers = await _getHeaders();
      final token = await SecureStorage.getTraktToken();
      if (token != null) {
        await http.post(
          Uri.parse('$_baseUrl/oauth/revoke'),
          headers: headers,
          body: jsonEncode({'token': token}),
        );
      }
    } catch (_) {}
    await SecureStorage.deleteTraktToken();
  }

  static Future<Map<String, dynamic>?> getUserProfile() async {
    if (!await isLoggedIn()) return null;
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/me?extended=full'),
        headers: await _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'name': data['name'] ?? data['username'] ?? 'مستخدم Zora',
          'avatar': data['images']?['avatar']?['full'] ?? '',
        };
      }
    } catch (e) {
      debugPrint('Profile error: $e');
    }
    return null;
  }

  static Future<void> addToWatchlist(int tmdbId, String type) async {
    if (!await isLoggedIn()) return;
    
    try {
      await http.post(
        Uri.parse('$_baseUrl/sync/watchlist'),
        headers: await _getHeaders(),
        body: jsonEncode({
          type == 'movie' ? 'movies' : 'shows': [
            {'ids': {'tmdb': tmdbId}}
          ]
        }),
      );
    } catch (e) {
      debugPrint('Add to watchlist error: $e');
    }
  }

  // دالة مساعدة بنفس الاسم القديم للتوافق
  static Future<void> addToTraktList(int tmdbId, String type) async {
    await addToWatchlist(tmdbId, type);
  }

  static Future<bool> removeFromWatchlist(int tmdbId, String type) async {
    if (!await isLoggedIn()) return false;
    
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/sync/watchlist/remove'),
        headers: await _getHeaders(),
        body: jsonEncode({
          type == 'movie' ? 'movies' : 'shows': [
            {'ids': {'tmdb': tmdbId}}
          ]
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getSyncWatchlist() async {
    if (!await isLoggedIn()) return [];
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/sync/watchlist'),
        headers: await _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) {
          final type = item['type'];
          final media = item[type];
          return {
            'id': media['ids']['tmdb'],
            'title': media['title'],
            'mediaType': type == 'movie' ? 'movie' : 'tv',
            'from_trakt': true,
          };
        }).toList();
      }
    } catch (e) {
      debugPrint('Sync watchlist error: $e');
    }
    return [];
  }

  static Future<void> syncPlaybackProgress(
    int tmdbId,
    String type,
    double progress, {
    int? season,
    int? episode,
  }) async {
    if (!await isLoggedIn()) return;
    
    try {
      final body = <String, dynamic>{
        'progress': progress,
        'app_version': AppConfig.appVersion,
        'app_date': DateTime.now().toIso8601String(),
      };
      
      if (type == 'movie') {
        body['movie'] = {'ids': {'tmdb': tmdbId}};
      } else {
        body['show'] = {'ids': {'tmdb': tmdbId}};
        body['episode'] = {'season': season ?? 1, 'number': episode ?? 1};
      }
      
      await http.post(
        Uri.parse('$_baseUrl/scrobble/pause'),
        headers: await _getHeaders(),
        body: jsonEncode(body),
      );
    } catch (e) {
      debugPrint('Sync progress error: $e');
    }
  }

  static Future<double?> getPlaybackProgress(
    int tmdbId,
    String type, {
    int? season,
    int? episode,
  }) async {
    if (!await isLoggedIn()) return null;
    
    try {
      final endpoint = type == 'movie' ? 'movies' : 'episodes';
      final response = await http.get(
        Uri.parse('$_baseUrl/sync/playback/$endpoint?extended=full'),
        headers: await _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        for (var item in data) {
          final media = type == 'movie' ? item['movie'] : item['show'];
          if (media != null && media['ids']['tmdb'] == tmdbId) {
            if (type == 'movie') {
              return (item['progress'] as num).toDouble() / 100;
            } else {
              final ep = item['episode'];
              if (ep != null && ep['season'] == season && ep['number'] == episode) {
                return (item['progress'] as num).toDouble() / 100;
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Get progress error: $e');
    }
    return null;
  }

  static Future<List<Map<String, dynamic>>> getAllPlaybackProgress() async {
    if (!await isLoggedIn()) return [];
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/sync/playback?extended=full'),
        headers: await _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<Map<String, dynamic>> result = [];
        
        for (var item in data) {
          final type = item['type'] as String?;
          final isEpisode = type == 'episode';
          final media = isEpisode ? item['show'] as Map<String, dynamic>? : item['movie'] as Map<String, dynamic>?;
          
          if (media == null) continue;
          
          final episodeData = isEpisode ? item['episode'] as Map<String, dynamic>? : null;
          
          result.add({
            'id': media['ids']['tmdb'],
            'title': media['title'],
            'progress': (item['progress'] as num).toDouble(),
            'mediaType': isEpisode ? 'tv' : 'movie',
            'last_s': episodeData != null ? episodeData['season'] as int? : null,
            'last_e': episodeData != null ? episodeData['number'] as int? : null,
          });
        }
        
        return result;
      }
    } catch (e) {
      debugPrint('Get all progress error: $e');
    }
    return [];
  }

  static Future<void> deletePlaybackProgress(int tmdbId, String type) async {
    if (!await isLoggedIn()) return;
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/sync/playback'),
        headers: await _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> items = jsonDecode(response.body);
        for (var item in items) {
          final mediaType = item['type'];
          final media = item[mediaType == 'episode' ? 'show' : 'movie'];
          if (media != null && media['ids']['tmdb'] == tmdbId) {
            final playbackId = item['id'];
            await http.delete(
              Uri.parse('$_baseUrl/sync/playback/$playbackId'),
              headers: await _getHeaders(),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Delete progress error: $e');
    }
  }
}