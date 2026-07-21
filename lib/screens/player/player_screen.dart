import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../models/media_model.dart';
import '../../utils/constants.dart';
import '../../utils/config.dart';
import '../../utils/localization.dart';
import '../../services/tmdb_service.dart';
import '../../services/subtitle_service.dart';
import 'models/subtitle_entry.dart';
import 'controllers/video_controller.dart';
import 'controllers/subtitle_controller.dart';
import 'controllers/web_extractor_controller.dart';
import 'controllers/progress_controller.dart';
import 'widgets/player_top_bar.dart';
import 'widgets/player_center_controls.dart';
import 'widgets/player_bottom_bar.dart';
import 'widgets/subtitle_overlay.dart';
import 'widgets/quality_selector.dart';
import 'widgets/subtitle_selector.dart';
import 'widgets/episode_selector.dart';
import 'widgets/loading_indicator.dart';

class PlayerScreen extends StatefulWidget {
  final Media media;
  final int? season;
  final int? episode;

  const PlayerScreen({
    Key? key,
    required this.media,
    this.season,
    this.episode,
  }) : super(key: key);

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with WidgetsBindingObserver {
  final VideoController _videoController = VideoController();
  final SubtitleController _subtitleController = SubtitleController();
  final WebExtractorController _webExtractorController =
      WebExtractorController();
  final ProgressController _progressController = ProgressController();
  final TmdbService _tmdbService = TmdbService();
  PlayerState _state = const PlayerState();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _state = _state.copyWith(
      currentSeason: widget.season ?? 1,
      currentEpisode: widget.episode ?? 1,
    );
    WakelockPlus.enable();
    _initialize();
  }

  Future<void> _initialize() async {
    await _videoController.setLandscapeMode();
    await _loadSubtitleSettings();
    _setupWebExtractor();
    _fetchSubdlSubtitles();
    _checkNextEpisode();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _state = _state.copyWith(isDisposed: true);
    _videoController.disposeController();
    _webExtractorController.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _videoController.pause();
      WakelockPlus.disable();
    } else if (state == AppLifecycleState.resumed) {
      _videoController.setLandscapeMode();
      _videoController.play();
      WakelockPlus.enable();
    }
  }

  Future<void> _loadSubtitleSettings() async {
    final settings = await SubtitleController.loadSettings();
    if (mounted)
      setState(() => _state = _state.copyWith(subtitleSettings: settings));
  }

  void _setupWebExtractor() {
    _webExtractorController.onVideoUrlFound = (url) {
      _handleVideoUrl(url, quality: null);
    };
    _webExtractorController.onSubtitleUrlFound = (url) {
      _handleSubtitleUrl(url);
    };
  }

  void _handleVideoUrl(String url, {String? quality}) {
    final newQualities = List<VideoQuality>.from(_state.extractedQualities);
    if (!newQualities.any((e) => e.url == url)) {
      String qualityName = quality ?? "Auto";
      if (url.contains("1080"))
        qualityName = "1080p";
      else if (url.contains("720"))
        qualityName = "720p";
      else if (url.contains("480"))
        qualityName = "480p";
      else if (url.contains("360")) qualityName = "360p";
      newQualities.add(VideoQuality(quality: qualityName, url: url));
    }
    if (_state.extractedUrl == null) _setupPlayer(url, quality: quality);
    if (mounted)
      setState(
          () => _state = _state.copyWith(extractedQualities: newQualities));
  }

  void _handleSubtitleUrl(String url) {
    final newSubUrls = List<SubtitleSource>.from(_state.extractedSubUrls);
    if (!newSubUrls.any((e) => e.url == url)) {
      newSubUrls.add(SubtitleSource(
          name: 'Embedded Subtitle ${newSubUrls.length + 1}', url: url));
      if (mounted)
        setState(() => _state = _state.copyWith(extractedSubUrls: newSubUrls));
    }
  }

  Future<void> _setupPlayer(String url, {String? quality}) async {
    if (_state.extractedUrl != null && quality == null) return;
    if (_state.isDisposed) return;
    try {
      await _videoController.initializePlayer(url);
      final savedProgress = await _progressController.getResumePosition(
        mediaId: widget.media.id,
        mediaType: widget.media.mediaType,
        season: _state.currentSeason,
        episode: _state.currentEpisode,
      );
      if (savedProgress > 0.05 &&
          savedProgress < 0.95 &&
          _videoController.playerController != null) {
        final position = Duration(
            milliseconds: (_videoController
                        .playerController!.value.duration.inMilliseconds *
                    savedProgress)
                .toInt());
        await _videoController.playerController!.seekTo(position);
      }
      _videoController.play();
      _videoController.onStateChanged = () {
        if (!mounted || _state.isDisposed) return;
        if (_videoController.playerController != null &&
            _videoController.playerController!.value.isInitialized) {
          final pos = _videoController.playerController!.value.position;
          if (pos.inSeconds % 10 == 0) _saveProgress();
          if (_state.parsedSubtitles.isNotEmpty && _state.showSubtitles) {
            final activeText = _subtitleController.getActiveSubtitleText(
              _videoController.playerController!.value.position,
              _state.parsedSubtitles,
            );
            if (_state.activeSubText != activeText)
              setState(
                  () => _state = _state.copyWith(activeSubText: activeText));
          }
          setState(() {});
        }
      };
      if (mounted) {
        setState(() => _state = _state.copyWith(
            isLoading: false,
            extractedUrl: url,
            selectedQuality: quality ?? _state.selectedQuality));
        _videoController.startControlsTimer(() {
          if (mounted &&
              (_videoController.playerController?.value.isPlaying ?? false)) {
            setState(() => _state = _state.copyWith(showControls: false));
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _state = _state.copyWith(isLoading: false));
        _showErrorSnackBar('Failed to play video');
      }
    }
  }

  Future<void> _fetchSubdlSubtitles() async {
    if (_state.isDisposed) return;
    setState(() => _state = _state.copyWith(isLoadingWyzie: true));
    try {
      final subtitles = await _subtitleController.fetchSubdlSubtitles(
        tmdbId: widget.media.id,
        isMovie: widget.media.isMovie,
        season: _state.currentSeason,
        episode: _state.currentEpisode,
      );
      final newSubUrls = List<SubtitleSource>.from(_state.extractedSubUrls);
      Map<String, dynamic>? bestSubtitle;
      Map<String, dynamic>? exactMatchSubtitle;
      for (var sub in subtitles) {
        final source = _subtitleController.addSubdlSubtitleToList(sub);
        if (source.url.isNotEmpty &&
            !newSubUrls.any((e) => e.url == source.url)) {
          newSubUrls.add(source);
          if (sub['season'] == _state.currentSeason &&
              sub['episode'] == _state.currentEpisode) {
            if (exactMatchSubtitle == null) exactMatchSubtitle = sub;
          }
          if (bestSubtitle == null) bestSubtitle = sub;
        }
      }
      if (exactMatchSubtitle != null) bestSubtitle = exactMatchSubtitle;
      if (mounted)
        setState(() => _state = _state.copyWith(
            isLoadingWyzie: false,
            wyzieSubtitles: subtitles,
            extractedSubUrls: newSubUrls));
      final prefs = await SharedPreferences.getInstance();
      final autoSubtitleEnabled =
          prefs.getBool('auto_subtitle_enabled') ?? true;
      if (autoSubtitleEnabled &&
          bestSubtitle != null &&
          _state.parsedSubtitles.isEmpty) {
        String? bestUrl = bestSubtitle['url']?.toString();
        final unpackedFiles = bestSubtitle['unpack_files'] as List?;
        if (unpackedFiles != null && unpackedFiles.isNotEmpty) {
          for (var file in unpackedFiles) {
            if (file is Map &&
                file['season'] == _state.currentSeason &&
                file['episode'] == _state.currentEpisode) {
              bestUrl = file['url'].toString();
              break;
            }
          }
        }
        if (bestUrl != null && bestUrl.isNotEmpty) await _loadSubtitle(bestUrl);
      }
    } catch (e) {
      if (mounted)
        setState(() => _state = _state.copyWith(isLoadingWyzie: false));
    }
  }

  Future<void> _loadSubtitle(String url) async {
    try {
      setState(() => _state = _state.copyWith(isLoading: true));
      final parsed = await _subtitleController.loadSubtitle(url);
      if (parsed != null && parsed.isNotEmpty) {
        setState(() => _state = _state.copyWith(
            parsedSubtitles: parsed,
            activeSubText: "",
            isLoading: false,
            showSubtitles: true));
        _showInfoSnackBar(
            '${context.tr('subtitle_loaded')} (${parsed.length} ${context.tr('lines')})');
      } else {
        setState(() => _state = _state.copyWith(isLoading: false));
        _showErrorSnackBar(context.tr('subtitle_load_failed'));
      }
    } catch (e) {
      setState(() => _state = _state.copyWith(isLoading: false));
      _showErrorSnackBar(context.tr('subtitle_load_failed'));
    }
  }

  Future<void> _saveProgress() async {
    if (_videoController.playerController == null ||
        !_videoController.playerController!.value.isInitialized) return;
    final progress =
        _videoController.playerController!.value.position.inMilliseconds /
            _videoController.playerController!.value.duration.inMilliseconds;
    await _progressController.saveProgress(
      mediaId: widget.media.id,
      mediaType: widget.media.mediaType,
      season: _state.currentSeason,
      episode: _state.currentEpisode,
      position: progress,
      title: widget.media.title,
      posterPath: widget.media.posterPath,
      backdropPath: widget.media.backdropPath,
    );
  }

  Future<void> _checkNextEpisode() async {
    if (widget.media.isMovie) {
      setState(() => _state = _state.copyWith(hasNextEpisode: false));
      return;
    }
    try {
      final details = await _tmdbService.getTVDetails(widget.media.id);
      if (details == null) return;
      final seasons = (details['seasons'] as List?) ?? [];
      Map<String, dynamic>? currentSeasonData;
      for (var s in seasons) {
        if (s is Map && s['season_number'] == _state.currentSeason) {
          currentSeasonData = Map<String, dynamic>.from(s);
          break;
        }
      }
      final episodeCount = currentSeasonData?['episode_count'] as int? ?? 0;
      if (_state.currentEpisode < episodeCount) {
        setState(() => _state = _state.copyWith(hasNextEpisode: true));
        _subtitleController.preloadNextEpisodeSubtitles(
          tmdbId: widget.media.id,
          season: _state.currentSeason,
          episode: _state.currentEpisode + 1,
        );
        return;
      }
      seasons.sort((a, b) =>
          (a['season_number'] as int).compareTo(b['season_number'] as int));
      Map<String, dynamic>? nextSeason;
      for (var s in seasons) {
        if (s is Map && (s['season_number'] as int) > _state.currentSeason) {
          nextSeason = Map<String, dynamic>.from(s);
          break;
        }
      }
      setState(
          () => _state = _state.copyWith(hasNextEpisode: nextSeason != null));
      if (nextSeason != null) {
        _subtitleController.preloadNextEpisodeSubtitles(
          tmdbId: widget.media.id,
          season: nextSeason['season_number'] as int,
          episode: 1,
        );
      }
    } catch (e) {
      setState(() => _state = _state.copyWith(hasNextEpisode: true));
    }
  }

  Future<void> _playNextEpisode() async {
    setState(() => _state = _state.copyWith(isLoading: true));
    try {
      final details = await _tmdbService.getTVDetails(widget.media.id);
      if (details == null) {
        await _navigateToEpisode(
            _state.currentSeason, _state.currentEpisode + 1);
        return;
      }
      final seasons = (details['seasons'] as List?) ?? [];
      Map<String, dynamic>? currentSeasonData;
      for (var s in seasons) {
        if (s is Map && s['season_number'] == _state.currentSeason) {
          currentSeasonData = Map<String, dynamic>.from(s);
          break;
        }
      }
      final episodeCount = currentSeasonData?['episode_count'] as int? ?? 0;
      if (_state.currentEpisode < episodeCount) {
        await _navigateToEpisode(
            _state.currentSeason, _state.currentEpisode + 1);
        return;
      }
      seasons.sort((a, b) =>
          (a['season_number'] as int).compareTo(b['season_number'] as int));
      Map<String, dynamic>? nextSeason;
      for (var s in seasons) {
        if (s is Map && (s['season_number'] as int) > _state.currentSeason) {
          nextSeason = Map<String, dynamic>.from(s);
          break;
        }
      }
      if (nextSeason != null) {
        await _navigateToEpisode(nextSeason['season_number'] as int, 1);
      } else {
        setState(() => _state = _state.copyWith(isLoading: false));
        _showInfoSnackBar(context.tr('no_next_episode'));
      }
    } catch (e) {
      await _navigateToEpisode(_state.currentSeason, _state.currentEpisode + 1);
    }
  }

  Future<void> _navigateToEpisode(int season, int episode) async {
    _videoController.disposeController();
    _webExtractorController.dispose();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PlayerScreen(
            media: widget.media,
            season: season,
            episode: episode,
          ),
        ),
      );
    }
  }

  void _toggleControls() {
    setState(
        () => _state = _state.copyWith(showControls: !_state.showControls));
    if (_state.showControls) {
      _videoController.startControlsTimer(() {
        if (mounted &&
            (_videoController.playerController?.value.isPlaying ?? false)) {
          setState(() => _state = _state.copyWith(showControls: false));
        }
      });
    }
  }

  void _handleDoubleTap(TapDownDetails details) {
    final width = MediaQuery.of(context).size.width;
    if (details.globalPosition.dx > width / 2) {
      _videoController.seekForward();
    } else {
      _videoController.seekBackward();
    }
  }

  void _cycleAspectRatio() {
    final nextIndex = (_state.ratioIndex + 1) % _state.aspectRatios.length;
    setState(() => _state = _state.copyWith(ratioIndex: nextIndex));
  }

  Future<void> _showEpisodesList() async {
    await EpisodeSelector.show(
      context: context,
      tvId: widget.media.id,
      currentSeason: _state.currentSeason,
      currentEpisode: _state.currentEpisode,
      onEpisodeSelected: (season, episode) async {
        _videoController.disposeController();
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PlayerScreen(
                media: widget.media,
                season: season,
                episode: episode,
              ),
            ),
          );
        }
      },
    );
  }

  void _showQualityPicker() {
    QualitySelector.show(
      context: context,
      qualities: _state.extractedQualities,
      selectedQuality: _state.selectedQuality,
      onQualitySelected: (url, quality) => _setupPlayer(url, quality: quality),
    );
  }

  void _showSubPicker() {
    SubtitleSelector.show(
      context: context,
      subUrls: _state.extractedSubUrls,
      isLoadingSubdl: _state.isLoadingWyzie,
      hasActiveSubtitles: _state.parsedSubtitles.isNotEmpty,
      activeSubtitlesCount: _state.parsedSubtitles.length,
      onRefreshSubdl: () {
        final newSubUrls = _state.extractedSubUrls
            .where((e) => !e.name.contains('[Subdl]'))
            .toList();
        setState(() => _state = _state.copyWith(extractedSubUrls: newSubUrls));
        _fetchSubdlSubtitles();
      },
      onSubtitleSelected: _loadSubtitle,
      onRemoveSubtitles: () {
        setState(() =>
            _state = _state.copyWith(parsedSubtitles: [], activeSubText: ""));
        _showInfoSnackBar(context.tr('subtitle_removed'));
      },
    );
  }

  Future<void> _forceExit() async {
    await _saveProgress();
    _videoController.disposeController();
    _webExtractorController.dispose();
    await _videoController.resetOrientation();
    WakelockPlus.disable();
    if (mounted) Navigator.of(context).pop();
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13)),
        backgroundColor: const Color(AppColors.error),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13)),
        backgroundColor: const Color(AppColors.primary),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: PopScope(
        onPop: () async {
          await _forceExit();
          return false;
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: -1000,
                child: SizedBox(
                  width: 1,
                  height: 1,
                  child: _webExtractorController.buildWebView(
                    mediaId: widget.media.id,
                    isMovie: widget.media.isMovie,
                    season: _state.currentSeason,
                    episode: _state.currentEpisode,
                  ),
                ),
              ),
              if (_videoController.playerController != null &&
                  _videoController.playerController!.value.isInitialized)
                GestureDetector(
                  onTap: _toggleControls,
                  onDoubleTapDown: _handleDoubleTap,
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: (_state.aspectRatios[_state.ratioIndex] ??
                          _videoController.playerController!.value.aspectRatio),
                      child: VideoPlayer(_videoController.playerController!),
                    ),
                  ),
                ),
              if (_state.showControls && !_state.isLoading)
                Stack(
                  children: [
                    PlayerTopBar(
                      title: widget.media.title,
                      season: _state.currentSeason,
                      episode: _state.currentEpisode,
                      isTV: widget.media.isTV,
                      onBackPressed: _forceExit,
                    ),
                    PlayerCenterControls(
                      isPlaying:
                          _videoController.playerController?.value.isPlaying ==
                              true,
                      onPlayPause: () {
                        _videoController.togglePlayPause();
                        _videoController.startControlsTimer(() {
                          if (mounted &&
                              (_videoController
                                      .playerController?.value.isPlaying ??
                                  false)) {
                            setState(() =>
                                _state = _state.copyWith(showControls: false));
                          }
                        });
                        setState(() {});
                      },
                      onSeekForward: _videoController.seekForward,
                      onSeekBackward: _videoController.seekBackward,
                    ),
                    if (_videoController.playerController != null)
                      PlayerBottomBar(
                        controller: _videoController.playerController!,
                        isTV: widget.media.isTV,
                        hasNextEpisode: _state.hasNextEpisode,
                        qualitiesCount: _state.extractedQualities.length,
                        onEpisodesList: _showEpisodesList,
                        onNextEpisode: _playNextEpisode,
                        onQualityPicker: _showQualityPicker,
                        onSubPicker: _showSubPicker,
                        onAspectRatio: _cycleAspectRatio,
                      ),
                  ],
                ),
              if (_state.isLoading) const PlayerLoadingIndicator(),
              if (_state.activeSubText.isNotEmpty && _state.showSubtitles)
                SubtitleOverlay(
                  activeSubText: _state.activeSubText,
                  showControls: _state.showControls,
                  settings: _state.subtitleSettings,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
