import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/subtitle_entry.dart';

/// طبقة عرض الترجمة على الفيديو
class SubtitleOverlay extends StatelessWidget {
  final String activeSubText;
  final bool showControls;
  final SubtitleSettings settings;

  const SubtitleOverlay({
    Key? key,
    required this.activeSubText,
    required this.showControls,
    required this.settings,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (activeSubText.isEmpty) return const SizedBox.shrink();

    return IgnorePointer(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.only(
            bottom:
                showControls ? settings.position + 80.h : settings.position.h,
            left: 20.w,
            right: 20.w,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getBackgroundColor(),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              activeSubText,
              style: TextStyle(
                color: _getTextColor(),
                fontSize: settings.fontSize.sp,
                fontWeight: FontWeight.w500,
                height: 1.3,
                fontFamily: settings.fontFamily == 'Default'
                    ? null
                    : settings.fontFamily,
                shadows: settings.bgColorValue == null
                    ? [
                        const Shadow(
                            blurRadius: 3,
                            color: Colors.black,
                            offset: Offset(1, 1))
                      ]
                    : null,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Color _getTextColor() {
    return settings.textColorValue != null
        ? Color(settings.textColorValue!)
        : Colors.white;
  }

  Color _getBackgroundColor() {
    return settings.bgColorValue != null
        ? Color(settings.bgColorValue!)
        : Colors.black.withOpacity(0.6);
  }
}
