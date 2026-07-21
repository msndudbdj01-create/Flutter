import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/media_model.dart';
import '../services/storage_service.dart';
import '../services/trakt_service.dart';
import '../services/ad_service.dart';
import '../utils/constants.dart';
import '../utils/localization.dart';
import '../screens/details_screen.dart';
import '../screens/player/player_screen.dart';

class HeroCarousel extends StatefulWidget {
  final List<Media> mediaList;
  final VoidCallback onListUpdated;
  const HeroCarousel(
      {Key? key, required this.mediaList, required this.onListUpdated})
      : super(key: key);

  @override
  _HeroCarouselState createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel>
    with AutomaticKeepAliveClientMixin {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _autoScrollTimer;
  bool _isDragging = false;
  final Map<int, bool> _inListStatus = {};
  final Map<int, bool> _isUpdating = {};

  @override
  bool get wantKeepAlive => false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    _startAutoScroll();
    _checkAllInListStatus();
  }

  @override
  void didUpdateWidget(covariant HeroCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mediaList.length != widget.mediaList.length ||
        oldWidget.mediaList != widget.mediaList) _checkAllInListStatus();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_isDragging && widget.mediaList.isNotEmpty && mounted) {
        if (_currentPage < widget.mediaList.length - 1)
          _pageController.nextPage(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut);
        else
          _pageController.animateToPage(0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut);
      }
    });
  }

  void _stopAutoScroll() => _autoScrollTimer?.cancel();
  void _resumeAutoScroll() {
    _stopAutoScroll();
    _startAutoScroll();
  }

  Future<void> _checkAllInListStatus() async {
    for (var media in widget.mediaList) await _checkSingleInListStatus(media);
  }

  Future<void> _checkSingleInListStatus(Media media) async {
    bool exists = await StorageService.isInList(media.id);
    if (!exists && await TraktService.isLoggedIn()) {
      final traktList = await TraktService.getSyncWatchlist();
      exists = traktList.any((item) =>
          item['id'] == media.id && item['mediaType'] == media.mediaType);
      if (exists)
        await StorageService.addToMyList({
          'id': media.id,
          'title': media.title,
          'poster_path': media.posterPath,
          'backdrop_path': media.backdropPath,
          'mediaType': media.mediaType,
          'vote_average': media.voteAverage,
          'from_trakt': true
        });
    }
    if (mounted) setState(() => _inListStatus[media.id] = exists);
  }

  Future<void> _toggleList(Media media) async {
    if (_isUpdating[media.id] == true) return;
    setState(() => _isUpdating[media.id] = true);
    final isInList = _inListStatus[media.id] ?? false;
    try {
      if (isInList) {
        await StorageService.removeFromMyList(media.id);
        if (await TraktService.isLoggedIn())
          await TraktService.removeFromWatchlist(media.id, media.mediaType);
        if (mounted) setState(() => _inListStatus[media.id] = false);
      } else {
        await StorageService.addToMyList({
          'id': media.id,
          'title': media.title,
          'poster_path': media.posterPath,
          'backdrop_path': media.backdropPath,
          'mediaType': media.mediaType,
          'vote_average': media.voteAverage
        });
        if (await TraktService.isLoggedIn())
          await TraktService.addToWatchlist(media.id, media.mediaType);
        if (mounted) setState(() => _inListStatus[media.id] = true);
      }
      widget.onListUpdated();
    } finally {
      if (mounted) setState(() => _isUpdating[media.id] = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (widget.mediaList.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        SizedBox(
          height: 550.h,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification) {
                setState(() => _isDragging = true);
                _stopAutoScroll();
              } else if (notification is ScrollEndNotification) {
                setState(() => _isDragging = false);
                _resumeAutoScroll();
              }
              return false;
            },
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemCount: widget.mediaList.length,
              itemBuilder: (context, index) {
                final media = widget.mediaList[index];
                final isInList = _inListStatus[media.id] ?? false;
                final isUpdating = _isUpdating[media.id] ?? false;
                return _buildHeroItem(media, isInList, isUpdating);
              },
            ),
          ),
        ),
        SizedBox(height: 10.h),
        _buildIndicators(),
      ],
    );
  }

  Widget _buildHeroItem(Media media, bool isInList, bool isUpdating) {
    final imageUrl = (media.posterPath != null && media.posterPath!.isNotEmpty)
        ? '${AppConstants.tmdbImageBaseUrl}${media.posterPath}'
        : 'https://via.placeholder.com/500x750?text=No+Poster';
    return GestureDetector(
      onTap: () {
        _stopAutoScroll();
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => DetailsScreen(media: media))).then((_) {
          _checkSingleInListStatus(media);
          _resumeAutoScroll();
          widget.onListUpdated();
        });
      },
      child: Stack(
        children: [
          CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              height: 550.h,
              width: double.infinity,
              memCacheWidth: 500,
              memCacheHeight: 750,
              placeholder: (context, url) => Container(
                  color: Colors.grey[900],
                  child: const Center(
                      child: CircularProgressIndicator(
                          color: Color(AppColors.primary)))),
              errorWidget: (context, url, error) => Container(
                  color: Colors.grey[900],
                  child: const Icon(Icons.broken_image,
                      color: Colors.white54, size: 50))),
          Container(
              height: 550.h,
              decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black54,
                    Color(AppColors.background)
                  ],
                      stops: [
                    0.0,
                    0.4,
                    0.7,
                    1.0
                  ]))),
          Positioned(
            bottom: 20.h,
            left: 20.w,
            right: 20.w,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                        color: const Color(AppColors.primary).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20.r)),
                    child: Text(
                        media.mediaType == 'movie'
                            ? LocalizationService.get(context, 'movie')
                            : LocalizationService.get(context, 'tv_show'),
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Tajawal'))),
                SizedBox(height: 10.h),
                Text(media.title,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 26.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Tajawal',
                        shadows: [
                          Shadow(
                              blurRadius: 10,
                              color: Colors.black.withOpacity(0.8),
                              offset: const Offset(2, 2))
                        ]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Icon(Icons.star,
                        color: const Color(AppColors.ratingStar), size: 18.sp),
                    SizedBox(width: 5.w),
                    Text(media.voteAverage?.toStringAsFixed(1) ?? '0.0',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                  blurRadius: 5,
                                  color: Colors.black.withOpacity(0.8),
                                  offset: const Offset(1, 1))
                            ])),
                    SizedBox(width: 15.w),
                    Text(media.year,
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14.sp,
                            shadows: [
                              Shadow(
                                  blurRadius: 5,
                                  color: Colors.black.withOpacity(0.8),
                                  offset: const Offset(1, 1))
                            ])),
                  ],
                ),
                SizedBox(height: 20.h),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildActionButton(
                        icon: Icons.play_arrow_rounded,
                        label: LocalizationService.get(context, 'watch_now'),
                        color: const Color(AppColors.primary),
                        isPrimary: true,
                        onTap: () async {
                          _stopAutoScroll();
                          void navigateToPlayer() => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          PlayerScreen(media: media)))
                              .then((_) => _resumeAutoScroll());
                          await AdService()
                              .showInterstitialAd(navigateToPlayer);
                        },
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      flex: 2,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _buildActionButton(
                          key: ValueKey('${media.id}_$isInList'),
                          icon: isUpdating
                              ? Icons.hourglass_empty
                              : (isInList
                                  ? Icons.check_circle
                                  : Icons.add_circle_outline),
                          label: isUpdating
                              ? "..."
                              : (isInList
                                  ? LocalizationService.get(context, 'in_list')
                                  : LocalizationService.get(
                                      context, 'add_to_list')),
                          color: isInList
                              ? const Color(AppColors.primary)
                              : Colors.white,
                          isPrimary: false,
                          onTap: isUpdating ? null : () => _toggleList(media),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      {Key? key,
      required IconData icon,
      required String label,
      required Color color,
      required bool isPrimary,
      VoidCallback? onTap}) {
    return GestureDetector(
      key: key,
      onTap: onTap,
      child: Container(
        height: 48.h,
        decoration: BoxDecoration(
          color: isPrimary
              ? color.withOpacity(0.9)
              : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(25.r),
          border: isPrimary
              ? null
              : Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (onTap != null)
              Icon(icon, color: isPrimary ? Colors.black : color, size: 20.sp),
            if (onTap != null) SizedBox(width: 5.w),
            Text(label,
                style: TextStyle(
                    color: isPrimary ? Colors.black : color,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Tajawal')),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
          widget.mediaList.length,
          (index) => GestureDetector(
                onTap: () => _pageController.animateToPage(index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut),
                child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: EdgeInsets.symmetric(horizontal: 4.w),
                    width: _currentPage == index ? 24.w : 8.w,
                    height: 8.h,
                    decoration: BoxDecoration(
                        color: _currentPage == index
                            ? const Color(AppColors.primary)
                            : Colors.white.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(4.r))),
              )),
    );
  }
}
