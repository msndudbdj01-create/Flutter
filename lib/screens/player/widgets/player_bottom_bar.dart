import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';

/// الشريط السفلي للمشغل (مؤشر التقدم، الوقت، أزرار الإجراءات)
class PlayerBottomBar extends StatelessWidget {
  final VideoPlayerController controller;
  final bool isTV;
  final bool hasNextEpisode;
  final int qualitiesCount;
  final VoidCallback onEpisodesList;
  final VoidCallback onNextEpisode;
  final VoidCallback onQualityPicker;
  final VoidCallback onSubPicker;
  final VoidCallback onAspectRatio;

  const PlayerBottomBar({
    Key? key,
    required this.controller,
    required this.isTV,
    required this.hasNextEpisode,
    required this.qualitiesCount,
    required this.onEpisodesList,
    required this.onNextEpisode,
    required this.onQualityPicker,
    required this.onSubPicker,
    required this.onAspectRatio,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black.withOpacity(0.8), Colors.transparent],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildProgressSlider(context),
              const SizedBox(height: 4),
              _buildTimeLabels(),
              const SizedBox(height: 8),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSlider(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: const Color(AppColors.primary),
        thumbColor: const Color(AppColors.primary),
        trackHeight: 2.0,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
      ),
      child: Slider(
        value: controller.value.position.inSeconds.toDouble().clamp(
              0.0,
              controller.value.duration.inSeconds.toDouble(),
            ),
        max: controller.value.duration.inSeconds.toDouble(),
        onChanged: (v) => controller.seekTo(Duration(seconds: v.toInt())),
      ),
    );
  }

  Widget _buildTimeLabels() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _formatDuration(controller.value.position),
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
        Text(
          _formatDuration(controller.value.duration),
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (isTV) ...[
          _buildActionButton(
            Icons.view_list,
            LocalizationService.get(context, 'episodes'),
            onEpisodesList,
          ),
          if (hasNextEpisode)
            _buildActionButton(
              Icons.skip_next,
              LocalizationService.get(context, 'next_episode'),
              onNextEpisode,
            ),
        ],
        if (qualitiesCount > 1)
          _buildActionButton(
            Icons.high_quality,
            LocalizationService.get(context, 'quality'),
            onQualityPicker,
          ),
        _buildActionButton(
          Icons.closed_caption,
          LocalizationService.get(context, 'subtitles'),
          onSubPicker,
        ),
        _buildActionButton(
          Icons.aspect_ratio,
          LocalizationService.get(context, 'aspect_ratio'),
          onAspectRatio,
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 9,
              fontFamily: 'Tajawal',
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0
        ? "${twoDigits(duration.inHours)}:$minutes:$seconds"
        : "$minutes:$seconds";
  }
}
