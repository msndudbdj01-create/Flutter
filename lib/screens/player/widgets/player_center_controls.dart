import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// أزرار التحكم المركزية (تشغيل/إيقاف، تقدم/تأخير)
class PlayerCenterControls extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final VoidCallback onSeekForward;
  final VoidCallback onSeekBackward;

  const PlayerCenterControls({
    Key? key,
    required this.isPlaying,
    required this.onPlayPause,
    required this.onSeekForward,
    required this.onSeekBackward,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildSmallIconButton(Icons.replay_10, onSeekBackward),
          SizedBox(width: 40.w),
          _buildLargeIconButton(
            isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
            onPlayPause,
          ),
          SizedBox(width: 40.w),
          _buildSmallIconButton(Icons.forward_10, onSeekForward),
        ],
      ),
    );
  }

  Widget _buildSmallIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Transform.scale(
        scale: 0.0025,
        child: Icon(icon, color: Colors.white, size: 50),
      ),
    );
  }

  Widget _buildLargeIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: Colors.white, size: 70),
    );
  }
}
