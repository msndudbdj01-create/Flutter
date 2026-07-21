import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/media_model.dart';
import '../utils/constants.dart';
import '../utils/localization.dart';
import '../services/tmdb_service.dart';
import '../services/storage_service.dart';
import '../services/trakt_service.dart';
import '../services/ad_service.dart';
import 'player/player_screen.dart';

class DetailsScreen extends StatefulWidget {
  final Media media;
  const DetailsScreen({Key? key, required this.media}) : super(key: key);

  @override
  _DetailsScreenState createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  bool _isInList = false;
  final TmdbService _tmdbService = TmdbService();
  Map<String, dynamic>? _tvDetails;
  List<dynamic> _episodes = [];
  int? _selectedSeason;
  bool _isLoadingTV = false;
  bool _isLoadingEpisodes = false;
  double? _resumePosition;
  int? _resumeSeason;
  int? _resumeEpisode;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _checkIfInList();
    _checkResumePosition();
    if (widget.media.mediaType == 'tv') _loadTVDetails();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> _checkIfInList() async {
    bool exists = await StorageService.isInList(widget.media.id);
    if (!_isDisposed && mounted) setState(() => _isInList = exists);
  }

  Future<void> _checkResumePosition() async {
    final prefs = await SharedPreferences.getInstance();
    String key;
    if (widget.media.mediaType == 'movie') {
      key = "resume_${widget.media.id}_movie_1_1";
    } else {
      final keys = prefs.getKeys();
      String? resumeKey;
      for (var k in keys) {
        if (k.startsWith("resume_${widget.media.id}_tv_")) {
          final progress = prefs.getDouble(k) ?? 0.0;
          if (progress > 0.05 && progress < 0.95) {
            resumeKey = k;
            break;
          }
        }
      }
      key = resumeKey ?? "resume_${widget.media.id}_tv_1_1";
    }
    final position = prefs.getDouble(key) ?? 0.0;
    if (position > 0.05 && position < 0.95) {
      if (!_isDisposed && mounted) {
        setState(() {
          _resumePosition = position;
          if (widget.media.mediaType == 'tv') {
            final parts = key.split('_');
            if (parts.length >= 5) {
              _resumeSeason = int.tryParse(parts[3]);
              _resumeEpisode = int.tryParse(parts[4]);
            }
          }
        });
      }
    }
    if (await TraktService.isLoggedIn()) {
      if (widget.media.mediaType == 'movie') {
        final traktPos =
            await TraktService.getPlaybackProgress(widget.media.id, 'movie');
        if (traktPos != null && traktPos > 0.05 && traktPos < 0.95) {
          if (!_isDisposed && mounted)
            setState(() => _resumePosition = traktPos);
        }
      }
    }
  }

  Future<void> _toggleList() async {
    if (_isInList) {
      await StorageService.removeFromMyList(widget.media.id);
      if (await TraktService.isLoggedIn())
        await TraktService.removeFromWatchlist(
            widget.media.id, widget.media.mediaType);
    } else {
      await StorageService.addToMyList({
        'id': widget.media.id,
        'title': widget.media.title,
        'poster_path': widget.media.posterPath,
        'backdrop_path': widget.media.backdropPath,
        'mediaType': widget.media.mediaType,
        'vote_average': widget.media.voteAverage,
      });
      if (await TraktService.isLoggedIn())
        TraktService.addToWatchlist(widget.media.id, widget.media.mediaType);
    }
    _checkIfInList();
  }

  Future<void> _loadTVDetails() async {
    if (_isDisposed) return;
    setState(() => _isLoadingTV = true);
    try {
      final details = await _tmdbService.getTVDetails(widget.media.id);
      if (!_isDisposed && mounted && details != null) {
        setState(() {
          _tvDetails = details;
          _isLoadingTV = false;
          final seasons = details['seasons'] as List?;
          if (seasons != null && seasons.isNotEmpty) {
            if (_resumeSeason != null) {
              _selectedSeason = _resumeSeason;
            } else {
              final validSeasons = seasons
                  .where((s) => (s['season_number'] as int? ?? 0) > 0)
                  .toList();
              if (validSeasons.isNotEmpty) {
                validSeasons.sort((a, b) => (a['season_number'] as int)
                    .compareTo(b['season_number'] as int));
                _selectedSeason = validSeasons.first['season_number'] as int;
              } else {
                _selectedSeason = seasons[0]['season_number'] as int;
              }
            }
            _loadEpisodes(_selectedSeason!);
          }
        });
      } else {
        if (!_isDisposed && mounted) setState(() => _isLoadingTV = false);
      }
    } catch (e) {
      if (!_isDisposed && mounted) setState(() => _isLoadingTV = false);
    }
  }

  Future<void> _loadEpisodes(int seasonNumber) async {
    if (_isDisposed) return;
    setState(() => _isLoadingEpisodes = true);
    try {
      final episodes =
          await _tmdbService.getSeasonEpisodes(widget.media.id, seasonNumber);
      if (!_isDisposed && mounted)
        setState(() {
          _episodes = episodes;
          _isLoadingEpisodes = false;
        });
    } catch (e) {
      if (!_isDisposed && mounted) setState(() => _isLoadingEpisodes = false);
    }
  }

  void _playMedia({int? forceSeason, int? forceEpisode}) async {
    int startSeason = forceSeason ?? _selectedSeason ?? 1;
    int startEpisode = forceEpisode ?? 1;
    if (_resumePosition != null &&
        _resumeSeason != null &&
        _resumeEpisode != null) {
      startSeason = _resumeSeason!;
      startEpisode = _resumeEpisode!;
    }
    void navigateToPlayer() {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => PlayerScreen(
                  media: widget.media,
                  season: startSeason,
                  episode: startEpisode)));
    }

    final adService = AdService();
    await adService.showInterstitialAd(navigateToPlayer);
  }

  List<dynamic> _getValidSeasons() {
    if (_tvDetails == null) return [];
    final seasons = _tvDetails!['seasons'] as List? ?? [];
    return seasons
        .where((s) => (s['season_number'] as int? ?? -1) > 0)
        .toList();
  }

  List<dynamic> _getAllSeasonsForDropdown() {
    if (_tvDetails == null) return [];
    final seasons = _tvDetails!['seasons'] as List? ?? [];
    seasons.sort((a, b) =>
        (a['season_number'] as int).compareTo(b['season_number'] as int));
    return seasons;
  }

  @override
  Widget build(BuildContext context) {
    Media displayMedia = widget.media;
    if (_tvDetails != null && _tvDetails!['certification'] != null)
      displayMedia =
          widget.media.copyWith(certification: _tvDetails!['certification']);

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(AppColors.background),
        body: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Container(
                        height: 450.h,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: CachedNetworkImageProvider(
                                widget.media.backdropPath != null
                                    ? AppConstants.tmdbBackdropBaseUrl +
                                        widget.media.backdropPath!
                                    : AppConstants.tmdbImageBaseUrl +
                                        (widget.media.posterPath ?? '')),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Container(
                          height: 450.h,
                          decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                Colors.transparent,
                                Color(AppColors.background)
                              ]))),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.media.title,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 28.sp,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Tajawal')),
                        SizedBox(height: 10.h),
                        Row(
                          children: [
                            Icon(Icons.star,
                                color: Color(AppColors.ratingStar), size: 20),
                            SizedBox(width: 5.w),
                            Text(
                                "${widget.media.voteAverage?.toStringAsFixed(1) ?? '0.0'}",
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                            SizedBox(width: 20.w),
                            Text(widget.media.year,
                                style: const TextStyle(
                                    color: Colors.white70,
                                    fontFamily: 'Tajawal')),
                            if (displayMedia.certification != null &&
                                displayMedia.certification!.isNotEmpty) ...[
                              SizedBox(width: 10.w),
                              Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8.w, vertical: 2.h),
                                  decoration: BoxDecoration(
                                      border: Border.all(color: Colors.white30),
                                      borderRadius: BorderRadius.circular(4.r)),
                                  child: Text(displayMedia.certification!,
                                      style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12.sp,
                                          fontFamily: 'Tajawal'))),
                            ],
                          ],
                        ),
                        SizedBox(height: 25.h),
                        Row(
                          children: [
                            Expanded(
                                child: _buildActionButton(
                                    Icons.play_arrow_rounded,
                                    _resumePosition != null
                                        ? context.tr('resume')
                                        : context.tr('watch_now'),
                                    const Color(AppColors.primary),
                                    true,
                                    _playMedia)),
                            SizedBox(width: 15.w),
                            Expanded(
                                child: _buildActionButton(
                                    _isInList
                                        ? Icons.check_circle_outline
                                        : Icons.add_rounded,
                                    _isInList
                                        ? context.tr('in_list')
                                        : context.tr('add_to_list'),
                                    _isInList
                                        ? const Color(AppColors.primary)
                                        : Colors.white,
                                    false,
                                    _toggleList)),
                          ],
                        ),
                        SizedBox(height: 25.h),
                        Text(widget.media.overview ?? '',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14.sp,
                                height: 1.5,
                                fontFamily: 'Tajawal')),
                      ],
                    ),
                  ),
                  if (widget.media.mediaType == 'tv') ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(context.tr('episodes'),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Tajawal')),
                          if (_tvDetails != null)
                            DropdownButton<int>(
                              dropdownColor: Colors.black87,
                              value: _selectedSeason,
                              menuMaxHeight: 300,
                              elevation: 8,
                              items: _getAllSeasonsForDropdown().map((s) {
                                final seasonNum = s['season_number'] as int;
                                String seasonName = seasonNum == 0
                                    ? "Specials"
                                    : "${context.tr('season')} $seasonNum";
                                return DropdownMenuItem<int>(
                                    value: seasonNum,
                                    child: Text(seasonName,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontFamily: 'Tajawal')));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedSeason = val);
                                  _loadEpisodes(val);
                                }
                              },
                            ),
                        ],
                      ),
                    ),
                    if (_isLoadingEpisodes)
                      const Center(
                          child: CircularProgressIndicator(
                              color: Color(AppColors.primary)))
                    else if (_episodes.isEmpty && _selectedSeason == 0)
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                            child: Column(children: [
                          Icon(Icons.info_outline,
                              color: Colors.white54, size: 48),
                          SizedBox(height: 10.h),
                          Text(context.tr('no_episodes_available'),
                              style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 14.sp,
                                  fontFamily: 'Tajawal'))
                        ])),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _episodes.length,
                        itemBuilder: (context, index) {
                          final ep = _episodes[index];
                          final int epNum = ep['episode_number'];
                          final bool isResumeEpisode =
                              _resumeSeason == _selectedSeason &&
                                  _resumeEpisode == epNum;
                          return ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl:
                                    "https://image.tmdb.org/t/p/w200${ep['still_path'] ?? ''}",
                                width: 100,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                    width: 100,
                                    color: Colors.white10,
                                    child: const Icon(Icons.image,
                                        color: Colors.white24)),
                                errorWidget: (context, url, error) => Container(
                                    width: 100,
                                    color: Colors.white10,
                                    child: const Icon(Icons.play_circle,
                                        color: Colors.white54)),
                              ),
                            ),
                            title: Row(
                              children: [
                                Text("${context.tr('episode')} $epNum",
                                    style:
                                        const TextStyle(color: Colors.white)),
                                if (isResumeEpisode) ...[
                                  SizedBox(width: 8.w),
                                  Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 6.w, vertical: 2.h),
                                      decoration: BoxDecoration(
                                          color: const Color(AppColors.primary)
                                              .withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(4.r)),
                                      child: Text(context.tr('resume'),
                                          style: TextStyle(
                                              color: const Color(
                                                  AppColors.primary),
                                              fontSize: 10.sp))),
                                ],
                              ],
                            ),
                            subtitle: Text(ep['name'] ?? '',
                                style: const TextStyle(
                                    color: Colors.white54, fontSize: 12)),
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => PlayerScreen(
                                        media: widget.media,
                                        season: _selectedSeason,
                                        episode: epNum))),
                          );
                        },
                      ),
                  ],
                  const SizedBox(height: 120),
                ],
              ),
            ),
            Positioned(
                top: 45,
                left: 15,
                child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context))),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color,
      bool isPrimary, VoidCallback onTap) {
    return GestureDetector(
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
            Icon(icon, color: isPrimary ? Colors.black : color, size: 20.sp),
            SizedBox(width: 8.w),
            Text(label,
                style: TextStyle(
                    color: isPrimary ? Colors.black : color,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Tajawal')),
          ],
        ),
      ),
    );
  }
}
