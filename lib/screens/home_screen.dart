import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/media_model.dart';
import '../services/tmdb_service.dart';
import '../services/trakt_service.dart';
import '../services/analytics_service.dart';
import '../services/ad_service.dart';
import '../utils/constants.dart';
import '../utils/localization.dart';
import 'details_screen.dart';
import 'player/player_screen.dart';
import 'settings_screen.dart';
import 'my_list_screen.dart';
import '../widgets/media_card.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/hero_carousel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TmdbService _tmdbService = TmdbService();
  List<Map<String, dynamic>> _continueWatchingData = [];
  int _currentIndex = 0;
  bool _isSearching = false;
  List<Media> _searchResults = [];
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  final ScrollController _scrollController = ScrollController();

  late Future<List<Media>> trending;
  late Future<List<Media>> popularMovies;
  late Future<List<Media>> popularTV;
  late Future<List<Media>> animeShows;

  @override
  void initState() {
    super.initState();
    _loadData();
    _syncAndLoadContinueWatching();
  }

  void _loadData() {
    trending = _tmdbService.getTrending();
    popularMovies = _tmdbService.getPopularMovies();
    popularTV = _tmdbService.getPopularTV();
    animeShows = _tmdbService.getAnimeShows();
  }

  /// دالة لترتيب عناصر متابعة المشاهدة من الأحدث إلى الأقدم
  List<Map<String, dynamic>> _sortContinueWatchingByLatest(
      List<Map<String, dynamic>> items) {
    // ترتيب تنازلي حسب آخر تحديث (الأحدث أولاً)
    items.sort((a, b) {
      // الحصول على وقت آخر تحديث لكل عنصر
      final aTime = a['last_updated'] as int? ?? 0;
      final bTime = b['last_updated'] as int? ?? 0;
      // ترتيب تنازلي (الأحدث أولاً)
      return bTime.compareTo(aTime);
    });
    return items;
  }

  List<Map<String, dynamic>> _mergeContinueWatching(
    List<Map<String, dynamic>> localItems,
    List<Map<String, dynamic>> traktItems,
  ) {
    final Map<String, Map<String, dynamic>> merged = {};

    // إضافة العناصر المحلية
    for (var item in localItems) {
      merged["${item['id']}_${item['mediaType']}"] =
          Map<String, dynamic>.from(item);
    }

    // دمج عناصر Trakt
    for (var tItem in traktItems) {
      final key = "${tItem['id']}_${tItem['mediaType']}";
      if (merged.containsKey(key)) {
        final existing = merged[key]!;
        if (tItem['mediaType'] == 'tv') {
          final tSeason = tItem['last_s'] as int? ?? 1;
          final tEpisode = tItem['last_e'] as int? ?? 1;
          final eSeason = existing['last_s'] as int? ?? 1;
          final eEpisode = existing['last_e'] as int? ?? 1;
          if (tSeason > eSeason ||
              (tSeason == eSeason && tEpisode > eEpisode)) {
            existing['position'] = tItem['position'];
            existing['last_s'] = tSeason;
            existing['last_e'] = tEpisode;
            // تحديث وقت آخر مشاهدة
            existing['last_updated'] = DateTime.now().millisecondsSinceEpoch;
            if (tItem['poster_path'] != null &&
                tItem['poster_path']!.toString().isNotEmpty) {
              existing['poster_path'] = tItem['poster_path'];
            }
            if (tItem['backdrop_path'] != null &&
                tItem['backdrop_path']!.toString().isNotEmpty) {
              existing['backdrop_path'] = tItem['backdrop_path'];
            }
          }
        } else {
          final tProgress = (tItem['position'] as num?)?.toDouble() ?? 0.0;
          final eProgress = (existing['position'] as num?)?.toDouble() ?? 0.0;
          if (tProgress > eProgress) {
            existing['position'] = tProgress;
            // تحديث وقت آخر مشاهدة
            existing['last_updated'] = DateTime.now().millisecondsSinceEpoch;
            if (tItem['poster_path'] != null &&
                tItem['poster_path']!.toString().isNotEmpty) {
              existing['poster_path'] = tItem['poster_path'];
            }
            if (tItem['backdrop_path'] != null &&
                tItem['backdrop_path']!.toString().isNotEmpty) {
              existing['backdrop_path'] = tItem['backdrop_path'];
            }
          }
        }
      } else {
        // إضافة عنصر جديد من Trakt مع وقت آخر تحديث
        final newItem = Map<String, dynamic>.from(tItem);
        newItem['last_updated'] = DateTime.now().millisecondsSinceEpoch;
        merged[key] = newItem;
      }
    }

    return merged.values.toList();
  }

  List<Map<String, dynamic>> _filterUnfinished(
      List<Map<String, dynamic>> items) {
    return items
        .where((item) => ((item['position'] as num?)?.toDouble() ?? 0.0) < 95.0)
        .toList();
  }

  Future<void> _syncAndLoadContinueWatching() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> raw = prefs.getStringList('continue_watching') ?? [];
    List<Map<String, dynamic>> localItems =
        raw.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
    List<Map<String, dynamic>> traktItems = [];

    if (await TraktService.isLoggedIn()) {
      final traktProgress = await TraktService.getAllPlaybackProgress();
      List<Future> futures = [];
      for (var tItem in traktProgress) {
        final key = "${tItem['id']}_${tItem['mediaType']}";
        final existsLocally =
            localItems.any((l) => "${l['id']}_${l['mediaType']}" == key);
        if (!existsLocally) {
          futures.add(_tmdbService
              .getMediaDetails(tItem['id'], tItem['mediaType'])
              .then((details) {
            if (details != null) {
              tItem['title'] = details['title'] ?? details['name'] ?? '';
              tItem['poster_path'] = details['poster_path'];
              tItem['backdrop_path'] = details['backdrop_path'];
            }
            traktItems.add(tItem);
          }).catchError((e) {
            traktItems.add(tItem);
          }));
        } else {
          traktItems.add(tItem);
        }
      }
      if (futures.isNotEmpty) await Future.wait(futures);
    }

    List<Map<String, dynamic>> mergedItems =
        _mergeContinueWatching(localItems, traktItems);
    mergedItems = _filterUnfinished(mergedItems);

    // ترتيب العناصر من الأحدث إلى الأقدم
    mergedItems = _sortContinueWatchingByLatest(mergedItems);

    await prefs.setStringList(
        'continue_watching', mergedItems.map((e) => jsonEncode(e)).toList());
    if (mounted) setState(() => _continueWatchingData = mergedItems);
  }

  Future<void> _removeFromContinueWatching(Map<String, dynamic> item) async {
    setState(() => _continueWatchingData.removeWhere(
        (e) => e['id'] == item['id'] && e['mediaType'] == item['mediaType']));
    final prefs = await SharedPreferences.getInstance();
    final updatedList =
        _continueWatchingData.map((e) => jsonEncode(e)).toList();
    await prefs.setStringList('continue_watching', updatedList);
    if (await TraktService.isLoggedIn()) {
      await TraktService.deletePlaybackProgress(item['id'], item['mediaType']);
    }
    if (item['mediaType'] == 'tv') {
      await _clearResumePosition(item['id'], item['mediaType'],
          item['last_s'] ?? 1, item['last_e'] ?? 1);
    } else {
      await _clearResumePosition(item['id'], item['mediaType'], 1, 1);
    }
  }

  Future<void> _clearResumePosition(
      int mediaId, String mediaType, int season, int episode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("resume_${mediaId}_${mediaType}_${season}_$episode");
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchResults = [];
      }
    });
  }

  void _performSearch(String query) {
    _searchDebounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted) return;
      final results = await _tmdbService.search(query);
      if (mounted) setState(() => _searchResults = results);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(AppColors.background),
        extendBody: true,
        body: Stack(
          children: [
            _buildPageContent(),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildPageContent() {
    switch (_currentIndex) {
      case 1:
        return const MyListScreen();
      case 2:
        return const SettingsScreen();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    return RefreshIndicator(
      onRefresh: () async {
        _loadData();
        await _syncAndLoadContinueWatching();
        if (mounted) setState(() {});
      },
      color: const Color(AppColors.primary),
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: false,
            snap: false,
            expandedHeight: 80.h,
            collapsedHeight: 80.h,
            toolbarHeight: 80.h,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Padding(
                padding: EdgeInsets.only(top: 45.h),
                child: _buildCustomTopBar(),
              ),
            ),
            automaticallyImplyLeading: false,
          ),
          if (_isSearching)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 10.h, left: 20.w, right: 20.w),
                child: _buildSearchBar(),
              ),
            ),
          if (!_isSearching) ...[
            _buildHeroBanner(),
            if (_continueWatchingData.isNotEmpty) _buildContinueSection(),
            _buildSection(context.tr('trending'), trending),
            _buildSection(context.tr('popular_movies'), popularMovies),
            _buildSection(context.tr('popular_tv'), popularTV),
            _buildSection(context.tr('anime'), animeShows),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
          if (_isSearching) _buildSearchResultsGrid(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 52.h,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(26.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: const Color(AppColors.primary).withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _performSearch,
              style: TextStyle(
                color: Colors.white,
                fontSize: 15.sp,
                height: 1.2,
                fontFamily: 'Tajawal',
              ),
              autofocus: true,
              cursorColor: const Color(AppColors.primary),
              cursorWidth: 1.5,
              cursorRadius: Radius.circular(2.r),
              decoration: InputDecoration(
                hintText: context.tr('search'),
                hintStyle: TextStyle(
                  color: Colors.white38,
                  fontSize: 14.sp,
                  fontFamily: 'Tajawal',
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 14.h,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: const Color(AppColors.primary).withOpacity(0.7),
                  size: 20.sp,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                        child: Container(
                          margin: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            color: Colors.white54,
                            size: 16.sp,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.all(4.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(AppColors.primary),
                  const Color(AppColors.primary).withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(22.r),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _toggleSearch,
                borderRadius: BorderRadius.circular(22.r),
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTopBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(25.r),
              border: Border.all(
                color: const Color(AppColors.primary).withOpacity(0.3),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6.w,
                  height: 6.w,
                  decoration: BoxDecoration(
                    color: const Color(AppColors.primary),
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  "Zora",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(AppColors.primary).withOpacity(0.3),
                width: 0.5,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _toggleSearch,
                customBorder: const CircleBorder(),
                child: Container(
                  padding: EdgeInsets.all(10.w),
                  child: Icon(
                    Icons.search_rounded,
                    color: const Color(AppColors.primary),
                    size: 20.sp,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner() {
    return SliverToBoxAdapter(
      child: FutureBuilder<List<Media>>(
        future: trending,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const ShimmerHeroBanner();
          }
          final mediaList = snapshot.data!.take(5).toList();
          return RepaintBoundary(
            child: HeroCarousel(
              mediaList: mediaList,
              onListUpdated: () {
                _syncAndLoadContinueWatching();
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildContinueSection() {
    return SliverToBoxAdapter(
      child: RepaintBoundary(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 3.w,
                        height: 16.h,
                        decoration: BoxDecoration(
                          color: const Color(AppColors.primary),
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        context.tr('continue_watching'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (_continueWatchingData.isNotEmpty)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showClearAllDialog(),
                        borderRadius: BorderRadius.circular(20.r),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent.withOpacity(0.7),
                                size: 14.sp,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                context.tr('clear_all'),
                                style: TextStyle(
                                  color: Colors.redAccent.withOpacity(0.7),
                                  fontSize: 11.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(
              height: 200.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                itemCount: _continueWatchingData.length,
                itemBuilder: (context, index) {
                  final item = _continueWatchingData[index];
                  final media = Media.fromJson(item, item['mediaType']);

                  double progressValue =
                      ((item['position'] ?? 0) / 100).clamp(0.0, 1.0);

                  String episodeInfo = '';
                  if (item['mediaType'] == 'tv' &&
                      item['last_s'] != null &&
                      item['last_e'] != null) {
                    episodeInfo = 'S${item['last_s']}:E${item['last_e']}';
                  }

                  return Container(
                    width: 120.w,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              GestureDetector(
                                onTap: () async {
                                  AnalyticsService.trackContinueWatchingClick(
                                    mediaId: media.id,
                                    mediaType: media.mediaType,
                                    title: media.title,
                                    season: item['last_s'],
                                    episode: item['last_e'],
                                  );
                                  void navigateToPlayer() {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PlayerScreen(
                                          media: media,
                                          season: item['last_s'],
                                          episode: item['last_e'],
                                        ),
                                      ),
                                    ).then(
                                        (_) => _syncAndLoadContinueWatching());
                                  }

                                  final adService = AdService();
                                  await adService
                                      .showInterstitialAd(navigateToPlayer);
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12.r),
                                  child: CachedNetworkImage(
                                    imageUrl: item['poster_path'] != null &&
                                            item['poster_path']!
                                                .toString()
                                                .isNotEmpty
                                        ? "https://image.tmdb.org/t/p/w500${item['poster_path']}"
                                        : "https://via.placeholder.com/500x750?text=No+Poster",
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    placeholder: (context, url) => Container(
                                      color: Colors.white10,
                                      child: Center(
                                        child: SizedBox(
                                          width: 20.w,
                                          height: 20.w,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color:
                                                const Color(AppColors.primary),
                                          ),
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                      color: Colors.white10,
                                      child: Icon(
                                        Icons.broken_image,
                                        color: Colors.white54,
                                        size: 24.sp,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: LinearProgressIndicator(
                                  value: progressValue,
                                  backgroundColor:
                                      Colors.black.withOpacity(0.5),
                                  color: const Color(AppColors.primary),
                                  minHeight: 3.h,
                                ),
                              ),
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () =>
                                        _removeFromContinueWatching(item),
                                    customBorder: const CircleBorder(),
                                    child: Container(
                                      padding: EdgeInsets.all(4.w),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 12.sp,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (progressValue > 0.05 && progressValue < 0.95)
                                Positioned(
                                  bottom: 4,
                                  right: 4,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 4.w, vertical: 2.h),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(4.r),
                                    ),
                                    child: Text(
                                      '${((item['position'] ?? 0)).toInt()}%',
                                      style: TextStyle(
                                        color: const Color(AppColors.primary),
                                        fontSize: 9.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          media.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (episodeInfo.isNotEmpty)
                          Text(
                            episodeInfo,
                            style: TextStyle(
                              color: const Color(AppColors.primary),
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          context.tr('clear_all'),
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          context.tr('clear_all_confirm'),
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              context.tr('cancel'),
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _clearAllContinueWatching();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text(
              context.tr('clear'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllContinueWatching() async {
    if (await TraktService.isLoggedIn()) {
      for (var item in _continueWatchingData) {
        await TraktService.deletePlaybackProgress(
            item['id'], item['mediaType']);
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('continue_watching');
    for (var item in _continueWatchingData) {
      final keys = prefs.getKeys();
      for (var key in keys) {
        if (key.startsWith("resume_${item['id']}_")) {
          await prefs.remove(key);
        }
      }
    }
    setState(() => _continueWatchingData = []);
  }

  Widget _buildSection(String title, Future<List<Media>> future) {
    return SliverToBoxAdapter(
      child: RepaintBoundary(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 15, 20, 8),
              child: Row(
                children: [
                  Container(
                    width: 3.w,
                    height: 14.h,
                    decoration: BoxDecoration(
                      color: const Color(AppColors.primary),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 200.h,
              child: FutureBuilder<List<Media>>(
                future: future,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const ShimmerHorizontalList();
                  }
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) => MediaCard(
                      media: snapshot.data![index],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              DetailsScreen(media: snapshot.data![index]),
                        ),
                      ).then((_) => _syncAndLoadContinueWatching()),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Positioned(
      bottom: 20.h,
      left: 20.w,
      right: 20.w,
      child: Container(
        height: 60.h,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A).withOpacity(0.95),
          borderRadius: BorderRadius.circular(30.r),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildSimpleNavItem(Icons.home_filled, 0, context.tr('home')),
            _buildSimpleNavItem(
                Icons.bookmark_rounded, 1, context.tr('my_list')),
            _buildSimpleNavItem(
                Icons.person_rounded, 2, context.tr('settings')),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleNavItem(IconData icon, int index, String label) {
    bool isSelected = _currentIndex == index;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _currentIndex = index),
          borderRadius: BorderRadius.circular(30.r),
          splashColor: const Color(AppColors.primary).withOpacity(0.2),
          highlightColor: const Color(AppColors.primary).withOpacity(0.1),
          child: Container(
            height: double.infinity,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? const Color(AppColors.primary)
                      : Colors.white54,
                  size: 22.sp,
                ),
                SizedBox(height: 3.h),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? const Color(AppColors.primary)
                        : Colors.white54,
                    fontSize: 10.sp,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                if (isSelected)
                  Container(
                    margin: EdgeInsets.only(top: 2.h),
                    width: 20.w,
                    height: 2.h,
                    decoration: BoxDecoration(
                      color: const Color(AppColors.primary),
                      borderRadius: BorderRadius.circular(1.r),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResultsGrid() {
    return SliverPadding(
      padding:
          EdgeInsets.only(top: 10.h, left: 15.w, right: 15.w, bottom: 120.h),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.7,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => MediaCard(
            media: _searchResults[index],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      DetailsScreen(media: _searchResults[index])),
            ).then((_) => _syncAndLoadContinueWatching()),
          ),
          childCount: _searchResults.length,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
