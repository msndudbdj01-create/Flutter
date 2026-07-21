import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../utils/localization.dart';
import '../widgets/custom_avatars.dart';

class AvatarSelectorScreen extends StatefulWidget {
  const AvatarSelectorScreen({Key? key}) : super(key: key);

  @override
  State<AvatarSelectorScreen> createState() => _AvatarSelectorScreenState();
}

class _AvatarSelectorScreenState extends State<AvatarSelectorScreen> {
  String _selectedAvatar = '';

  final List<Map<String, dynamic>> _avatars = [
    {'type': 'happy', 'color': 0xFF1CE783, 'name': 'سعيد', 'nameEn': 'Happy'},
    {'type': 'sad', 'color': 0xFF1E88E5, 'name': 'حزين', 'nameEn': 'Sad'},
    {
      'type': 'surprised',
      'color': 0xFF43A047,
      'name': 'متفاجئ',
      'nameEn': 'Surprised'
    },
    {'type': 'angry', 'color': 0xFFFB8C00, 'name': 'غاضب', 'nameEn': 'Angry'},
    {'type': 'love', 'color': 0xFFE91E63, 'name': 'عاشق', 'nameEn': 'Love'},
    {
      'type': 'sleepy',
      'color': 0xFF6D4C41,
      'name': 'نعسان',
      'nameEn': 'Sleepy'
    },
    {'type': 'grumpy', 'color': 0xFF5E35B1, 'name': 'عابس', 'nameEn': 'Grumpy'},
    {
      'type': 'smiley',
      'color': 0xFFFFC107,
      'name': 'مبتسم',
      'nameEn': 'Smiley'
    },
    {'type': 'tired', 'color': 0xFF78909C, 'name': 'متعب', 'nameEn': 'Tired'},
    {'type': 'happy', 'color': 0xFF00ACC1, 'name': 'مرح', 'nameEn': 'Cheerful'},
    {
      'type': 'surprised',
      'color': 0xFF9C27B0,
      'name': 'مندهش',
      'nameEn': 'Astonished'
    },
    {'type': 'love', 'color': 0xFFF44336, 'name': 'غارم', 'nameEn': 'In Love'},
  ];

  @override
  void initState() {
    super.initState();
    _loadSelectedAvatar();
  }

  Future<void> _loadSelectedAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    final savedAvatar = prefs.getString('user_avatar') ?? '';
    if (mounted) {
      setState(() {
        _selectedAvatar = savedAvatar;
      });
    }
  }

  Future<void> _saveAvatar(String avatarData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_avatar', avatarData);
    if (mounted) {
      setState(() {
        _selectedAvatar = avatarData;
      });
    }
  }

  String _getAvatarName(Map<String, dynamic> avatar) {
    final isArabic = LocalizationService.get(context, 'app_language') == 'ar';
    return isArabic ? avatar['name'] as String : avatar['nameEn'] as String;
  }

  Widget _buildAvatarItem(Map<String, dynamic> avatar) {
    final avatarKey = '${avatar['type']}_${avatar['color']}';
    final isSelected = _selectedAvatar == avatarKey;
    final color = Color(avatar['color']);
    final avatarName = _getAvatarName(avatar);

    Widget avatarWidget;
    switch (avatar['type']) {
      case 'happy':
        avatarWidget = HappyFaceAvatar(color: color, size: 70);
        break;
      case 'sad':
        avatarWidget = SadFaceAvatar(color: color, size: 70);
        break;
      case 'surprised':
        avatarWidget = SurprisedFaceAvatar(color: color, size: 70);
        break;
      case 'angry':
        avatarWidget = AngryFaceAvatar(color: color, size: 70);
        break;
      case 'love':
        avatarWidget = LoveFaceAvatar(color: color, size: 70);
        break;
      case 'sleepy':
        avatarWidget = SleepyFaceAvatar(color: color, size: 70);
        break;
      case 'grumpy':
        avatarWidget = GrumpyFaceAvatar(color: color, size: 70);
        break;
      case 'smiley':
        avatarWidget = SmileyFaceAvatar(color: color, size: 70);
        break;
      case 'tired':
        avatarWidget = TiredFaceAvatar(color: color, size: 70);
        break;
      default:
        avatarWidget = HappyFaceAvatar(color: color, size: 70);
    }

    return GestureDetector(
      onTap: () async {
        await _saveAvatar(avatarKey);
        if (mounted) {}
      },
      child: Container(
        margin: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(
                  color: const Color(AppColors.primary),
                  width: 3,
                )
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(AppColors.primary).withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Container(
              width: 70.w,
              height: 70.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: avatarWidget,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              avatarName,
              style: TextStyle(
                color: isSelected
                    ? const Color(AppColors.primary)
                    : Colors.white54,
                fontSize: 11.sp,
                fontFamily: 'Tajawal',
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(AppColors.background),
        appBar: AppBar(
          title: Text(
            LocalizationService.get(context, 'select_avatar'),
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            Container(
              margin: EdgeInsets.symmetric(vertical: 20.h),
              child: Column(
                children: [
                  Text(
                    LocalizationService.get(context, 'avatar_preview'),
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 14.sp,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Container(
                    width: 100.w,
                    height: 100.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(AppColors.primary).withOpacity(0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(AppColors.primary).withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: _buildPreviewAvatar(),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    LocalizationService.get(context, 'selected_avatar'),
                    style: TextStyle(
                      color: const Color(AppColors.primary),
                      fontSize: 12.sp,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.all(16.w),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16.w,
                  mainAxisSpacing: 16.h,
                  childAspectRatio: 0.9,
                ),
                itemCount: _avatars.length,
                itemBuilder: (context, index) {
                  return _buildAvatarItem(_avatars[index]);
                },
              ),
            ),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                border: Border(
                  top: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await _saveAvatar('');
                        if (mounted) {
                          Navigator.pop(context);
                        }
                      },
                      icon: const Icon(Icons.sync, color: Colors.black),
                      label: Text(
                        LocalizationService.get(context, 'use_trakt_avatar'),
                        style: const TextStyle(
                          color: Colors.black,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(AppColors.primary),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.check, color: Colors.black),
                      label: Text(
                        LocalizationService.get(context, 'confirm'),
                        style: const TextStyle(
                          color: Colors.black,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(AppColors.primary),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewAvatar() {
    if (_selectedAvatar.isEmpty) {
      return HappyFaceAvatar(color: const Color(0xFF1CE783), size: 100);
    }

    final parts = _selectedAvatar.split('_');
    if (parts.length >= 2) {
      final type = parts[0];
      final colorHex = int.parse(parts[1]);
      final color = Color(colorHex);

      switch (type) {
        case 'happy':
          return HappyFaceAvatar(color: color, size: 100);
        case 'sad':
          return SadFaceAvatar(color: color, size: 100);
        case 'surprised':
          return SurprisedFaceAvatar(color: color, size: 100);
        case 'angry':
          return AngryFaceAvatar(color: color, size: 100);
        case 'love':
          return LoveFaceAvatar(color: color, size: 100);
        case 'sleepy':
          return SleepyFaceAvatar(color: color, size: 100);
        case 'grumpy':
          return GrumpyFaceAvatar(color: color, size: 100);
        case 'smiley':
          return SmileyFaceAvatar(color: color, size: 100);
        case 'tired':
          return TiredFaceAvatar(color: color, size: 100);
        default:
          return HappyFaceAvatar(color: color, size: 100);
      }
    }

    return HappyFaceAvatar(color: const Color(0xFF1CE783), size: 100);
  }
}
