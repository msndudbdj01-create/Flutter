import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../services/tmdb_service.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';

class EpisodeSelector {
  static Future<void> show({
    required BuildContext context,
    required int tvId,
    required int currentSeason,
    required int currentEpisode,
    required Function(int season, int episode) onEpisodeSelected,
  }) async {
    final TmdbService _tmdbService = TmdbService();

    final tvDetails = await _tmdbService.getTVDetails(tvId);
    if (tvDetails == null) return;

    final seasons = (tvDetails['seasons'] as List?) ?? [];

    final validSeasons = seasons.where((s) {
      final seasonNum = s['season_number'] as int? ?? -1;
      return seasonNum > 0;
    }).toList();

    if (validSeasons.isEmpty) return;

    List<Map<String, dynamic>> episodes = [];
    int selectedSeason = currentSeason;
    bool isLoading = true;

    Future<void> loadEpisodes(int seasonNum) async {
      isLoading = true;
      episodes = await _tmdbService.getSeasonEpisodes(tvId, seasonNum);
      isLoading = false;
    }

    await loadEpisodes(selectedSeason);

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Directionality(
              textDirection: TextDirection.ltr,
              child: StatefulBuilder(
                builder: (context, setState) {
                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(20)),
                      border: Border(
                        top: BorderSide(
                          color:
                              const Color(AppColors.primary).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(AppColors.primary)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.playlist_play,
                                  color: const Color(AppColors.primary),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.tr('select_episode'),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Tajawal',
                                      ),
                                    ),
                                    if (!isLoading)
                                      Text(
                                        "${context.tr('season')} $selectedSeason • ${episodes.length} ${context.tr('episodes')}",
                                        style: TextStyle(
                                          color: const Color(AppColors.primary),
                                          fontSize: 11,
                                          fontFamily: 'Tajawal',
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(AppColors.primary)
                                        .withOpacity(0.3),
                                  ),
                                ),
                                child: DropdownButton<int>(
                                  value: selectedSeason,
                                  dropdownColor: const Color(0xFF2A2A2A),
                                  underline: const SizedBox(),
                                  icon: Icon(
                                    Icons.arrow_drop_down,
                                    color: const Color(AppColors.primary),
                                    size: 20,
                                  ),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontFamily: 'Tajawal',
                                  ),
                                  items: validSeasons.map((season) {
                                    final seasonNum =
                                        season['season_number'] as int;
                                    String seasonName =
                                        "${context.tr('season')} $seasonNum";
                                    return DropdownMenuItem<int>(
                                      value: seasonNum,
                                      child: Text(seasonName),
                                    );
                                  }).toList(),
                                  onChanged: (newSeason) async {
                                    if (newSeason != null &&
                                        newSeason != selectedSeason) {
                                      setState(() {
                                        selectedSeason = newSeason;
                                        isLoading = true;
                                        episodes = [];
                                      });
                                      final newEpisodes =
                                          await _tmdbService.getSeasonEpisodes(
                                        tvId,
                                        newSeason,
                                      );
                                      setState(() {
                                        episodes = newEpisodes;
                                        isLoading = false;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(
                            color: Colors.white12, height: 1, thickness: 1),
                        Expanded(
                          child: isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(AppColors.primary),
                                  ),
                                )
                              : episodes.isEmpty
                                  ? _buildEmptyState(context)
                                  : ListView.builder(
                                      controller: scrollController,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      itemCount: episodes.length,
                                      itemBuilder: (context, index) {
                                        final episode = episodes[index];
                                        final episodeNum =
                                            episode['episode_number'] as int;
                                        final isCurrentEpisode =
                                            selectedSeason == currentSeason &&
                                                episodeNum == currentEpisode;
                                        final isLast =
                                            index == episodes.length - 1;
                                        return RepaintBoundary(
                                          child: _EpisodeTile(
                                            episode: episode,
                                            seasonNum: selectedSeason,
                                            episodeNum: episodeNum,
                                            isCurrentEpisode: isCurrentEpisode,
                                            isLast: isLast,
                                            onTap: () {
                                              Navigator.pop(context);
                                              onEpisodeSelected(
                                                  selectedSeason, episodeNum);
                                            },
                                          ),
                                        );
                                      },
                                    ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Text(
                            context.tr('episode_selection_info'),
                            style: TextStyle(
                              color: Colors.white24,
                              fontSize: 10,
                              fontFamily: 'Tajawal',
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  static Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.movie_creation_outlined,
              color: Colors.white38,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('no_episodes_available'),
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 15,
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _EpisodeTile extends StatelessWidget {
  final Map<String, dynamic> episode;
  final int seasonNum;
  final int episodeNum;
  final bool isCurrentEpisode;
  final bool isLast;
  final VoidCallback onTap;

  const _EpisodeTile({
    Key? key,
    required this.episode,
    required this.seasonNum,
    required this.episodeNum,
    required this.isCurrentEpisode,
    required this.isLast,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String episodeName = episode['name'] ?? 'Episode $episodeNum';
    final String? stillPath = episode['still_path'];
    final String? airDate = episode['air_date'];
    final double? voteAverage = episode['vote_average'];

    String formattedDate = '';
    if (airDate != null && airDate.isNotEmpty && airDate.length >= 10) {
      final parts = airDate.split('-');
      if (parts.length == 3) {
        formattedDate = '${parts[2]}/${parts[1]}/${parts[0]}';
      }
    }

    Color? tileColor;
    if (isCurrentEpisode) {
      tileColor = const Color(AppColors.primary).withOpacity(0.1);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          margin: EdgeInsets.only(
            left: 12,
            right: 12,
            bottom: isLast ? 0 : 4,
          ),
          decoration: BoxDecoration(
            color: tileColor,
            borderRadius: BorderRadius.circular(12),
            border: isCurrentEpisode
                ? Border.all(
                    color: const Color(AppColors.primary).withOpacity(0.3),
                  )
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 80,
                  height: 60,
                  child: _buildEpisodeImage(stillPath),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            "${context.tr('episode')} $episodeNum",
                            style: TextStyle(
                              color: isCurrentEpisode
                                  ? const Color(AppColors.primary)
                                  : Colors.white,
                              fontSize: 14,
                              fontFamily: 'Tajawal',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (isCurrentEpisode) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(AppColors.primary)
                                  .withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              context.tr('current'),
                              style: TextStyle(
                                color: const Color(AppColors.primary),
                                fontSize: 9,
                                fontFamily: 'Tajawal',
                              ),
                            ),
                          ),
                        ],
                        if (voteAverage != null && voteAverage > 0) ...[
                          const Spacer(),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star,
                                color: const Color(AppColors.ratingStar),
                                size: 12,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                voteAverage.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Color(AppColors.ratingStar),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      episodeName,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontFamily: 'Tajawal',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (formattedDate.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: Colors.white38,
                            size: 10,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            formattedDate,
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                              fontFamily: 'Tajawal',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isCurrentEpisode
                    ? const Color(AppColors.primary).withOpacity(0.7)
                    : Colors.white24,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEpisodeImage(String? stillPath) {
    final imageUrl = stillPath != null && stillPath.isNotEmpty
        ? '${AppConstants.tmdbImageBaseUrl}$stillPath'
        : 'https://image.tmdb.org/t/p/w500${episode['still_path'] ?? ''}';

    if (imageUrl.isEmpty || imageUrl == 'https://image.tmdb.org/t/p/w500') {
      return Container(
        color: Colors.white10,
        child: const Icon(
          Icons.tv,
          color: Colors.white24,
          size: 30,
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      placeholder: (context, url) => Container(
        color: Colors.white10,
        child: const Icon(
          Icons.image,
          color: Colors.white24,
          size: 24,
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.white10,
        child: const Icon(
          Icons.broken_image,
          color: Colors.white24,
          size: 24,
        ),
      ),
    );
  }
}
