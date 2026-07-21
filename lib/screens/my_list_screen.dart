import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/storage_service.dart';
import '../services/trakt_service.dart';
import '../services/tmdb_service.dart';
import '../utils/constants.dart';
import '../utils/localization.dart';
import '../models/media_model.dart';
import 'details_screen.dart';

class MyListScreen extends StatefulWidget {
  const MyListScreen({Key? key}) : super(key: key);

  @override
  _MyListScreenState createState() => _MyListScreenState();
}

class _MyListScreenState extends State<MyListScreen> {
  List<Map<String, dynamic>> _allMedia = [];
  bool _isLoading = false;
  bool _isSyncing = false;
  final TmdbService _tmdbService = TmdbService();

  @override
  void initState() {
    super.initState();
    _loadLocalList();
    _syncInBackground();
  }

  Future<void> _loadLocalList() async {
    final localData = await StorageService.getMyList();
    if (mounted) setState(() => _allMedia = localData);
  }

  Future<void> _syncInBackground() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    try {
      final localData = await StorageService.getMyList();
      List<Map<String, dynamic>> combined = List.from(localData);
      if (await TraktService.isLoggedIn()) {
        final traktData = await TraktService.getSyncWatchlist();
        List<Future> futures = [];
        bool hasChanges = false;
        for (var tItem in traktData) {
          if (!combined.any((lItem) => lItem['id'] == tItem['id'])) {
            hasChanges = true;
            futures.add(_tmdbService
                .getMediaDetails(tItem['id'], tItem['mediaType'])
                .then((details) {
              if (details != null)
                tItem['poster_path'] = details['poster_path'];
              combined.add(tItem);
            }).catchError((e) {}));
          }
        }
        if (futures.isNotEmpty) await Future.wait(futures);
        if (hasChanges) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setStringList('my_list_movies',
              combined.map((item) => jsonEncode(item)).toList());
        }
      }
      if (mounted)
        setState(() {
          _allMedia = combined;
          _isSyncing = false;
        });
    } catch (e) {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(AppColors.background),
        appBar: AppBar(
          title: Text(context.tr('my_list'),
              style: const TextStyle(
                  fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            if (_isSyncing)
              const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Color(AppColors.primary), strokeWidth: 2)))
            else
              IconButton(
                  icon: const Icon(Icons.refresh,
                      color: Color(AppColors.primary)),
                  onPressed: _syncInBackground),
          ],
        ),
        body: _allMedia.isEmpty && _isSyncing
            ? const Center(
                child:
                    CircularProgressIndicator(color: Color(AppColors.primary)))
            : _allMedia.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bookmark_border,
                            color: Colors.white24, size: 64.sp),
                        SizedBox(height: 16.h),
                        Text(context.tr('my_list_empty'),
                            style: TextStyle(
                                color: Colors.white54,
                                fontSize: 16.sp,
                                fontFamily: 'Tajawal')),
                        SizedBox(height: 8.h),
                        Text(context.tr('add_movies_and_shows'),
                            style: TextStyle(
                                color: Colors.white24,
                                fontSize: 13.sp,
                                fontFamily: 'Tajawal')),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: EdgeInsets.fromLTRB(15.w, 10.h, 15.w, 120.h),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.7,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15),
                    itemCount: _allMedia.length,
                    itemBuilder: (context, index) {
                      final item = _allMedia[index];
                      final media = Media.fromJson(item, item['mediaType']);
                      return Stack(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            DetailsScreen(media: media)))
                                .then((_) => _loadLocalList()),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20.r),
                              child: CachedNetworkImage(
                                imageUrl: (item['poster_path'] == null ||
                                        item['poster_path'].isEmpty)
                                    ? "https://via.placeholder.com/500x750?text=No+Poster"
                                    : "https://image.tmdb.org/t/p/w500${item['poster_path']}",
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                placeholder: (context, url) =>
                                    Container(color: Colors.white10),
                                errorWidget: (context, url, error) => Container(
                                    color: Colors.white10,
                                    child: const Icon(Icons.broken_image,
                                        color: Colors.white54)),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () async {
                                await StorageService.removeFromMyList(
                                    item['id']);
                                if (item['from_trakt'] == true)
                                  await TraktService.removeFromWatchlist(
                                      item['id'], item['mediaType']);
                                _loadLocalList();
                              },
                              child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                      color: Colors.redAccent,
                                      shape: BoxShape.circle),
                                  child: const Icon(Icons.close,
                                      color: Colors.white, size: 18)),
                            ),
                          ),
                          if (item['from_trakt'] == true)
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle),
                                  child: Icon(Icons.cloud_done,
                                      color: Color(AppColors.primary),
                                      size: 18)),
                            ),
                        ],
                      );
                    },
                  ),
      ),
    );
  }
}
