import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../utils/localization.dart';

class SubtitleSettingsScreen extends StatefulWidget {
  const SubtitleSettingsScreen({Key? key}) : super(key: key);

  @override
  _SubtitleSettingsScreenState createState() => _SubtitleSettingsScreenState();
}

class _SubtitleSettingsScreenState extends State<SubtitleSettingsScreen> {
  // إعدادات الخط
  String _fontFamily = 'Default';
  final List<String> _fontFamilies = [
    'Default',
    'Tajawal',
    'Cairo',
    'Roboto',
    'Arial'
  ];

  // إعدادات لون النص
  Color _textColor = Colors.white;
  final List<Map<String, dynamic>> _textColors = [
    {'name': 'أبيض', 'nameEn': 'White', 'color': Colors.white},
    {'name': 'أصفر', 'nameEn': 'Yellow', 'color': Colors.yellow},
    {'name': 'أخضر', 'nameEn': 'Green', 'color': Colors.green},
    {'name': 'سماوي', 'nameEn': 'Cyan', 'color': Colors.cyan},
    {'name': 'برتقالي', 'nameEn': 'Orange', 'color': Colors.orange},
  ];

  // إعدادات لون الخلفية
  Color _backgroundColor = Colors.black.withOpacity(0.6);
  final List<Map<String, dynamic>> _backgroundColors = [
    {'name': 'شفاف', 'nameEn': 'Transparent', 'color': Colors.transparent},
    {
      'name': 'أسود شفاف',
      'nameEn': 'Semi-transparent Black',
      'color': Colors.black.withOpacity(0.6)
    },
    {'name': 'أسود', 'nameEn': 'Black', 'color': Colors.black},
    {'name': 'رمادي', 'nameEn': 'Grey', 'color': Colors.grey},
  ];

  // حجم النص
  double _textSize = 10.0;
  final double _minTextSize = 8.0;
  final double _maxTextSize = 32.0;

  // موضع الترجمة
  double _position = 20.0;
  final double _minPosition = 10.0;
  final double _maxPosition = 200.0;

  // إعدادات المشغل
  String _defaultQuality = 'Auto';
  final List<String> _qualities = ['Auto', '1080p', '720p', '480p', '360p'];

  String _resizeMode = 'Fit';
  final List<String> _resizeModes = ['Fit', 'Fill', 'Zoom', 'Stretch'];

  // نص المعاينة
  String get _previewText1 =>
      LocalizationService.get(context, 'app_language') == 'ar'
          ? "هذا مثال على شكل الترجمة"
          : "This is a subtitle preview";

  String get _previewText2 =>
      LocalizationService.get(context, 'app_language') == 'ar'
          ? "يمكنك تخصيص الخط واللون والحجم"
          : "You can customize font, color and size";

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _fontFamily = prefs.getString('subtitle_font') ?? 'Default';

      final textColorValue =
          prefs.getInt('subtitle_text_color') ?? Colors.white.value;
      _textColor = Color(textColorValue);

      final bgColorValue = prefs.getInt('subtitle_bg_color');
      _backgroundColor = bgColorValue != null
          ? Color(bgColorValue)
          : Colors.black.withOpacity(0.6);

      _textSize = prefs.getDouble('subtitle_text_size') ?? 10.0;
      _position = prefs.getDouble('subtitle_position') ?? 20.0;
      _defaultQuality = prefs.getString('default_quality') ?? 'Auto';
      _resizeMode = prefs.getString('resize_mode') ?? 'Fit';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('subtitle_font', _fontFamily);
    await prefs.setInt('subtitle_text_color', _textColor.value);
    await prefs.setInt('subtitle_bg_color', _backgroundColor.value);
    await prefs.setDouble('subtitle_text_size', _textSize);
    await prefs.setDouble('subtitle_position', _position);
    await prefs.setString('default_quality', _defaultQuality);
    await prefs.setString('resize_mode', _resizeMode);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LocalizationService.get(context, 'settings_saved'),
            style: const TextStyle(fontFamily: 'Tajawal'),
          ),
          backgroundColor: const Color(AppColors.primary),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _resetToDefault() {
    setState(() {
      _fontFamily = 'Default';
      _textColor = Colors.white;
      _backgroundColor = Colors.black.withOpacity(0.6);
      _textSize = 10.0;
      _position = 20.0;
      _defaultQuality = 'Auto';
      _resizeMode = 'Fit';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          LocalizationService.get(context, 'settings_reset'),
          style: const TextStyle(fontFamily: 'Tajawal'),
        ),
        backgroundColor: Colors.grey,
      ),
    );
  }

  String _getTextForColor(Map<String, dynamic> colorItem) {
    final isArabic = LocalizationService.get(context, 'app_language') == 'ar';
    return isArabic
        ? colorItem['name'] as String
        : colorItem['nameEn'] as String;
  }

  String _getTextForBackground(Map<String, dynamic> bgItem) {
    final isArabic = LocalizationService.get(context, 'app_language') == 'ar';
    return isArabic ? bgItem['name'] as String : bgItem['nameEn'] as String;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(AppColors.background),
        appBar: AppBar(
          title: Text(
            LocalizationService.get(context, 'subtitle_and_player'),
            style: const TextStyle(
                fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white70),
              onPressed: () => _resetToDefault(),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(20.w),
                children: [
                  _buildSectionTitle(
                      LocalizationService.get(context, 'preview')),
                  _buildPreviewCard(),
                  SizedBox(height: 20.h),
                  _buildSectionTitle(LocalizationService.get(context, 'font')),
                  _buildFontSelector(),
                  SizedBox(height: 20.h),
                  _buildSectionTitle(
                      LocalizationService.get(context, 'background')),
                  _buildBackgroundColorSelector(),
                  SizedBox(height: 15.h),
                  _buildSectionTitle(
                      LocalizationService.get(context, 'text_color')),
                  _buildTextColorSelector(),
                  SizedBox(height: 20.h),
                  _buildSectionTitle(
                      LocalizationService.get(context, 'text_size')),
                  _buildTextSizeSlider(),
                  SizedBox(height: 5.h),
                  _buildSectionTitle(
                      LocalizationService.get(context, 'position')),
                  _buildPositionSlider(),
                  SizedBox(height: 20.h),
                  _buildSectionTitle(
                      LocalizationService.get(context, 'player')),
                  _buildSectionTitle(
                      LocalizationService.get(context, 'default_quality')),
                  _buildQualitySelector(),
                  SizedBox(height: 15.h),
                  _buildSectionTitle(
                      LocalizationService.get(context, 'default_resize_mode')),
                  _buildResizeModeSelector(),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: 10.h,
          top: title == LocalizationService.get(context, 'preview') ? 0 : 5.h),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white54,
          fontSize: 13.sp,
          fontWeight: FontWeight.w500,
          fontFamily: 'Tajawal',
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(15.r),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            image: const DecorationImage(
              image: NetworkImage(
                  'https://image.tmdb.org/t/p/w500/8uO0gUM8aNqYLs1OsTBQiXu0fEv.jpg'),
              fit: BoxFit.cover,
              opacity: 0.3,
            ),
          ),
          child: Column(
            children: [
              Text(
                LocalizationService.get(context, 'subtitle_preview'),
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12.sp,
                  fontFamily: 'Tajawal',
                ),
              ),
              SizedBox(height: 30.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: _backgroundColor,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Column(
                  children: [
                    Text(
                      _previewText1,
                      style: TextStyle(
                        color: _textColor,
                        fontSize: _textSize.sp,
                        fontFamily:
                            _fontFamily == 'Default' ? 'Tajawal' : _fontFamily,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                        shadows: _backgroundColor == Colors.transparent
                            ? [
                                Shadow(
                                  blurRadius: 4,
                                  color: Colors.black.withOpacity(0.7),
                                  offset: const Offset(1, 1),
                                ),
                              ]
                            : null,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      _previewText2,
                      style: TextStyle(
                        color: _textColor,
                        fontSize: _textSize.sp,
                        fontFamily:
                            _fontFamily == 'Default' ? 'Tajawal' : _fontFamily,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                        shadows: _backgroundColor == Colors.transparent
                            ? [
                                Shadow(
                                  blurRadius: 4,
                                  color: Colors.black.withOpacity(0.7),
                                  offset: const Offset(1, 1),
                                ),
                              ]
                            : null,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFontSelector() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _fontFamily,
          isExpanded: true,
          dropdownColor: const Color(0xFF1A1A1A),
          style: TextStyle(
            color: Colors.white,
            fontSize: 14.sp,
            fontFamily: 'Tajawal',
          ),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
          items: _fontFamilies.map((font) {
            return DropdownMenuItem(
              value: font,
              child: Text(
                font,
                style: TextStyle(
                  fontFamily: font == 'Default' ? 'Tajawal' : font,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _fontFamily = value);
            }
          },
        ),
      ),
    );
  }

  Widget _buildBackgroundColorSelector() {
    return Wrap(
      spacing: 10.w,
      runSpacing: 10.h,
      children: _backgroundColors.map((bg) {
        final color = bg['color'] as Color;
        final name = _getTextForBackground(bg);
        final isSelected = _backgroundColor.value == color.value;

        return GestureDetector(
          onTap: () => setState(() => _backgroundColor = color),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: color == Colors.transparent
                  ? Colors.white.withOpacity(0.1)
                  : color,
              borderRadius: BorderRadius.circular(25.r),
              border: Border.all(
                color: isSelected
                    ? const Color(AppColors.primary)
                    : Colors.white.withOpacity(0.2),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected)
                  Icon(Icons.check, color: Colors.white, size: 16.sp),
                if (isSelected) SizedBox(width: 5.w),
                Text(
                  name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.sp,
                    fontFamily: 'Tajawal',
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextColorSelector() {
    return Wrap(
      spacing: 10.w,
      runSpacing: 10.h,
      children: _textColors.map((tc) {
        final color = tc['color'] as Color;
        final isSelected = _textColor.value == color.value;

        return GestureDetector(
          onTap: () => setState(() => _textColor = color),
          child: Container(
            width: 45.w,
            height: 45.w,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 3,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.5),
                        blurRadius: 10,
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.black, size: 20)
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextSizeSlider() {
    return Row(
      children: [
        Text(
          _minTextSize.toInt().toString(),
          style: TextStyle(color: Colors.white54, fontSize: 12.sp),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(AppColors.primary),
              thumbColor: const Color(AppColors.primary),
              trackHeight: 3.0,
            ),
            child: Slider(
              value: _textSize,
              min: _minTextSize,
              max: _maxTextSize,
              divisions: 20,
              onChanged: (value) => setState(() => _textSize = value),
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text(
            _textSize.toInt().toString(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPositionSlider() {
    return Row(
      children: [
        Text(
          _minPosition.toInt().toString(),
          style: TextStyle(color: Colors.white54, fontSize: 12.sp),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(AppColors.primary),
              thumbColor: const Color(AppColors.primary),
              trackHeight: 3.0,
            ),
            child: Slider(
              value: _position,
              min: _minPosition,
              max: _maxPosition,
              divisions: 19,
              onChanged: (value) => setState(() => _position = value),
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text(
            _position.toInt().toString(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQualitySelector() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _defaultQuality,
          isExpanded: true,
          dropdownColor: const Color(0xFF1A1A1A),
          style: TextStyle(
            color: Colors.white,
            fontSize: 14.sp,
            fontFamily: 'Tajawal',
          ),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
          items: _qualities.map((quality) {
            return DropdownMenuItem(
              value: quality,
              child: Text(quality),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _defaultQuality = value);
            }
          },
        ),
      ),
    );
  }

  Widget _buildResizeModeSelector() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _resizeMode,
          isExpanded: true,
          dropdownColor: const Color(0xFF1A1A1A),
          style: TextStyle(
            color: Colors.white,
            fontSize: 14.sp,
            fontFamily: 'Tajawal',
          ),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
          items: _resizeModes.map((mode) {
            return DropdownMenuItem(
              value: mode,
              child: Text(mode),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _resizeMode = value);
            }
          },
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: const Color(AppColors.background),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: ElevatedButton(
        onPressed: _saveSettings,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(AppColors.primary),
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.r),
          ),
        ),
        child: Text(
          LocalizationService.get(context, 'save'),
          style: TextStyle(
            color: Colors.black,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            fontFamily: 'Tajawal',
          ),
        ),
      ),
    );
  }
}
