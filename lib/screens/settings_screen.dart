import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/trakt_service.dart';
import '../utils/constants.dart';
import '../utils/localization.dart';
import 'about_screen.dart';
import 'subtitle_settings_screen.dart';
import 'avatar_selector_screen.dart';
import 'language_screen.dart';
import '../widgets/custom_avatars.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoggedIn = false;
  String _userName = "";
  String _userAvatar = "";
  String _customAvatar = "";
  String _preferredSubtitleLanguage = "ar";
  bool _autoSubtitleEnabled = true;
  bool _isConnectingTrakt = false; // متغير لتتبع حالة الاتصال

  final List<Map<String, String>> _availableLanguages = [
    {'code': 'ar', 'name': 'العربية', 'flag': '🇸🇦'},
    {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
    {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷'},
    {'code': 'es', 'name': 'Español', 'flag': '🇪🇸'},
    {'code': 'de', 'name': 'Deutsch', 'flag': '🇩🇪'},
    {'code': 'it', 'name': 'Italiano', 'flag': '🇮🇹'},
    {'code': 'tr', 'name': 'Türkçe', 'flag': '🇹🇷'},
    {'code': 'fa', 'name': 'فارسی', 'flag': '🇮🇷'},
    {'code': 'ur', 'name': 'اردو', 'flag': '🇵🇰'},
    {'code': 'hi', 'name': 'हिन्दी', 'flag': '🇮🇳'},
    {'code': 'zh', 'name': '中文', 'flag': '🇨🇳'},
    {'code': 'ja', 'name': '日本語', 'flag': '🇯🇵'},
    {'code': 'ko', 'name': '한국어', 'flag': '🇰🇷'},
    {'code': 'pt', 'name': 'Português', 'flag': '🇧🇷'},
    {'code': 'ru', 'name': 'Русский', 'flag': '🇷🇺'},
  ];

  @override
  void initState() {
    super.initState();
    _loadLocalData();
    _checkTraktStatus();
    _loadCustomAvatar();
  }

  Future<void> _loadCustomAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    final customAvatar = prefs.getString('user_avatar') ?? '';
    if (mounted) setState(() => _customAvatar = customAvatar);
  }

  Future<void> _loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('subtitle_language') ?? 'ar';
    final autoSubtitle = prefs.getBool('auto_subtitle_enabled') ?? true;
    if (mounted)
      setState(() {
        _preferredSubtitleLanguage = lang;
        _autoSubtitleEnabled = autoSubtitle;
        _userName = prefs.getString('trakt_user_name') ?? "";
      });
  }

  Future<void> _checkTraktStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final traktLoggedIn = prefs.getBool('trakt_logged_in') ?? false;
    final savedUserName = prefs.getString('trakt_user_name') ?? "";
    final savedAvatar = prefs.getString('trakt_user_avatar') ?? "";

    if (traktLoggedIn) {
      final profile = await TraktService.getUserProfile();
      if (profile != null) {
        final name = profile['name'] ?? "Zora User";
        final avatar = profile['avatar'] ?? "";
        await prefs.setString('trakt_user_name', name);
        await prefs.setString('trakt_user_avatar', avatar);
        if (mounted)
          setState(() {
            _isLoggedIn = true;
            _userName = name;
            _userAvatar = avatar;
          });
      } else {
        if (mounted)
          setState(() {
            _isLoggedIn = traktLoggedIn;
            _userName = savedUserName.isNotEmpty ? savedUserName : "Zora User";
            _userAvatar = savedAvatar;
          });
      }
    } else {
      if (mounted)
        setState(() {
          _isLoggedIn = false;
          _userName = "Zora User";
          _userAvatar = "";
        });
    }
  }

  // دالة جديدة لتحديث حالة Trakt بعد الاتصال
  Future<void> _refreshTraktStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final traktLoggedIn = prefs.getBool('trakt_logged_in') ?? false;

    if (traktLoggedIn) {
      final profile = await TraktService.getUserProfile();
      if (profile != null) {
        final name = profile['name'] ?? "Zora User";
        final avatar = profile['avatar'] ?? "";
        await prefs.setString('trakt_user_name', name);
        await prefs.setString('trakt_user_avatar', avatar);
        if (mounted) {
          setState(() {
            _isLoggedIn = true;
            _userName = name;
            _userAvatar = avatar;
          });
        }
        return;
      }
    }

    // إذا لم يكن مسجلاً دخول
    if (mounted) {
      setState(() {
        _isLoggedIn = false;
        _userName = "Zora User";
        _userAvatar = "";
      });
    }
  }

  Future<void> _saveAutoSubtitleEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_subtitle_enabled', value);
    setState(() => _autoSubtitleEnabled = value);
  }

  Future<void> _openAvatarSelector() async {
    await Navigator.push(context,
        MaterialPageRoute(builder: (context) => const AvatarSelectorScreen()));
    await _loadCustomAvatar();
    if (mounted) setState(() {});
  }

  String _getDisplayAvatar() {
    if (_customAvatar.isNotEmpty && _customAvatar.contains('_'))
      return _customAvatar;
    if (_isLoggedIn && _userAvatar.isNotEmpty) return _userAvatar;
    return '';
  }

  // دالة لربط حساب Trakt مع تحديث تلقائي
  Future<void> _connectTrakt() async {
    if (_isConnectingTrakt) return;

    setState(() {
      _isConnectingTrakt = true;
    });

    try {
      // فتح صفحة المصادقة
      await TraktService.authorize();

      // انتظار لمدة 2 ثانية للسماح بعملية المصادقة
      await Future.delayed(const Duration(seconds: 2));

      // التحقق من حالة تسجيل الدخول
      final isNowLoggedIn = await TraktService.isLoggedIn();

      if (isNowLoggedIn && mounted) {
        // جلب بيانات المستخدم
        final profile = await TraktService.getUserProfile();
        if (profile != null) {
          final prefs = await SharedPreferences.getInstance();
          final name = profile['name'] ?? "Zora User";
          final avatar = profile['avatar'] ?? "";
          await prefs.setBool('trakt_logged_in', true);
          await prefs.setString('trakt_user_name', name);
          await prefs.setString('trakt_user_avatar', avatar);

          // تحديث الواجهة مباشرة
          setState(() {
            _isLoggedIn = true;
            _userName = name;
            _userAvatar = avatar;
          });

          // إظهار رسالة نجاح
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.tr('trakt_login_success'),
                style: const TextStyle(fontFamily: 'Tajawal'),
              ),
              backgroundColor: const Color(AppColors.primary),
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          // محاولة تحديث الحالة مرة أخرى إذا لم تنجح المرة الأولى
          await Future.delayed(const Duration(seconds: 1));
          await _refreshTraktStatus();

          if (_isLoggedIn && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  context.tr('trakt_login_success'),
                  style: const TextStyle(fontFamily: 'Tajawal'),
                ),
                backgroundColor: const Color(AppColors.primary),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      } else if (mounted) {
        // محاولة تحديث الحالة
        await _refreshTraktStatus();
      }
    } catch (e) {
      debugPrint('Error connecting to Trakt: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to connect to Trakt. Please try again.',
              style: const TextStyle(fontFamily: 'Tajawal'),
            ),
            backgroundColor: const Color(AppColors.error),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConnectingTrakt = false;
        });
      }
    }
  }

  // دالة لتسجيل الخروج من Trakt
  Future<void> _disconnectTrakt() async {
    setState(() {
      _isConnectingTrakt = true;
    });

    try {
      await TraktService.logout();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('trakt_logged_in', false);
      await prefs.remove('trakt_user_name');
      await prefs.remove('trakt_user_avatar');

      if (mounted) {
        setState(() {
          _isLoggedIn = false;
          _userName = "";
          _userAvatar = "";
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Logged out from Trakt',
              style: const TextStyle(fontFamily: 'Tajawal'),
            ),
            backgroundColor: const Color(AppColors.primary),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error disconnecting from Trakt: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isConnectingTrakt = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(AppColors.background),
        appBar: AppBar(
          title: Text(context.tr('settings'),
              style: const TextStyle(
                  fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: ListView(
          padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 100.h),
          children: [
            _buildProfileCard(),
            SizedBox(height: 30.h),
            _buildSectionTitle(context.tr('account_and_sync')),
            _buildTraktButton(),
            SizedBox(height: 20.h),
            _buildSectionTitle(context.tr('user_experience')),
            _buildLanguageButton(),
            _buildSubtitleLanguageButton(),
            _buildAutoSubtitleSwitch(),
            _buildSettingTile(
              Icons.text_fields,
              context.tr('subtitle_and_player'),
              context.tr('customize_subtitle_and_player'),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SubtitleSettingsScreen())),
            ),
            SizedBox(height: 20.h),
            _buildSectionTitle(context.tr('general')),
            _buildSettingTile(
              Icons.info_outline,
              context.tr('about_app'),
              context.tr('app_info_and_developer'),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const AboutScreen())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    final displayAvatar = _getDisplayAvatar();
    final isCustomAvatar =
        displayAvatar.contains('_') && !displayAvatar.startsWith('http');

    return GestureDetector(
      onTap: _openAvatarSelector,
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(25.r),
            border: Border.all(color: Colors.white.withOpacity(0.1))),
        child: Row(
          children: [
            Container(
              width: 70.w,
              height: 70.w,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: const Color(AppColors.primary).withOpacity(0.5),
                      width: 2),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(AppColors.primary).withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: 2)
                  ]),
              child: ClipOval(
                  child: _buildAvatarContent(displayAvatar, isCustomAvatar)),
            ),
            SizedBox(width: 20.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_userName.isNotEmpty ? _userName : context.tr('guest'),
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Tajawal')),
                  SizedBox(height: 5.h),
                  Text(
                      _isLoggedIn
                          ? context.tr('trakt_account_linked')
                          : context.tr('login_to_sync'),
                      style: TextStyle(
                          color: Colors.white38,
                          fontSize: 13.sp,
                          fontFamily: 'Tajawal')),
                  SizedBox(height: 8.h),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                        color: const Color(AppColors.primary).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15.r)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.edit,
                          color: const Color(AppColors.primary), size: 12.sp),
                      SizedBox(width: 5.w),
                      Text(context.tr('tap_to_change_avatar'),
                          style: TextStyle(
                              color: const Color(AppColors.primary),
                              fontSize: 11.sp,
                              fontFamily: 'Tajawal')),
                    ]),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white24, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarContent(String displayAvatar, bool isCustomAvatar) {
    if (isCustomAvatar && displayAvatar.isNotEmpty) {
      final parts = displayAvatar.split('_');
      if (parts.length >= 2) {
        final type = parts[0];
        final color = Color(int.parse(parts[1]));
        switch (type) {
          case 'happy':
            return HappyFaceAvatar(color: color, size: 70);
          case 'sad':
            return SadFaceAvatar(color: color, size: 70);
          case 'surprised':
            return SurprisedFaceAvatar(color: color, size: 70);
          case 'angry':
            return AngryFaceAvatar(color: color, size: 70);
          case 'love':
            return LoveFaceAvatar(color: color, size: 70);
          case 'sleepy':
            return SleepyFaceAvatar(color: color, size: 70);
          case 'grumpy':
            return GrumpyFaceAvatar(color: color, size: 70);
          case 'smiley':
            return SmileyFaceAvatar(color: color, size: 70);
          case 'tired':
            return TiredFaceAvatar(color: color, size: 70);
          default:
            return HappyFaceAvatar(color: color, size: 70);
        }
      }
    }

    if (displayAvatar.isNotEmpty && displayAvatar.startsWith('http')) {
      return Image.network(
        displayAvatar,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return HappyFaceAvatar(color: const Color(0xFF1CE783), size: 70);
        },
      );
    }

    return HappyFaceAvatar(color: const Color(0xFF1CE783), size: 70);
  }

  Widget _buildLanguageButton() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10.r)),
          child: const Icon(Icons.language, color: Colors.white70)),
      title: Text(context.tr('app_language'),
          style: const TextStyle(color: Colors.white, fontFamily: 'Tajawal')),
      subtitle: Text(context.tr('change_app_language'),
          style: const TextStyle(color: Colors.white38, fontSize: 12)),
      trailing:
          const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (context) => const LanguageScreen())),
    );
  }

  Widget _buildAutoSubtitleSwitch() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
              color: _autoSubtitleEnabled
                  ? const Color(AppColors.primary).withOpacity(0.1)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10.r)),
          child: Icon(Icons.auto_awesome,
              color: _autoSubtitleEnabled
                  ? const Color(AppColors.primary)
                  : Colors.white54,
              size: 24)),
      title: Text(context.tr('auto_subtitle'),
          style: const TextStyle(color: Colors.white, fontFamily: 'Tajawal')),
      subtitle: Text(
          _autoSubtitleEnabled
              ? context.tr('auto_subtitle_enabled_desc')
              : context.tr('auto_subtitle_disabled_desc'),
          style: TextStyle(
              color: _autoSubtitleEnabled
                  ? const Color(AppColors.primary)
                  : Colors.white38,
              fontSize: 12)),
      trailing: Switch(
          value: _autoSubtitleEnabled,
          onChanged: _saveAutoSubtitleEnabled,
          activeColor: const Color(AppColors.primary)),
    );
  }

  Widget _buildSubtitleLanguageButton() {
    final selectedLanguage = _availableLanguages.firstWhere(
        (lang) => lang['code'] == _preferredSubtitleLanguage,
        orElse: () => {'code': 'ar', 'name': 'العربية', 'flag': '🇸🇦'});

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10.r)),
          child: Text(selectedLanguage['flag']!,
              style: const TextStyle(fontSize: 24))),
      title: Text(context.tr('preferred_subtitle_language'),
          style: const TextStyle(color: Colors.white, fontFamily: 'Tajawal')),
      subtitle: Text(
          "${selectedLanguage['name']} (${selectedLanguage['code']})",
          style:
              TextStyle(color: const Color(AppColors.primary), fontSize: 12)),
      trailing:
          const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
      onTap: _showLanguagePicker,
    );
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(
              top: BorderSide(
                color: const Color(AppColors.primary).withOpacity(0.3),
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
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text(context.tr('subtitle_language'),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Tajawal')),
              const Divider(color: Colors.white24),
              Expanded(
                child: ListView.builder(
                  itemCount: _availableLanguages.length,
                  itemBuilder: (context, index) {
                    final lang = _availableLanguages[index];
                    final isSelected =
                        _preferredSubtitleLanguage == lang['code'];
                    return ListTile(
                      leading: Text(lang['flag']!,
                          style: const TextStyle(fontSize: 28)),
                      title: Text(lang['name']!,
                          style: TextStyle(
                              color: isSelected
                                  ? const Color(AppColors.primary)
                                  : Colors.white,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontFamily: 'Tajawal')),
                      trailing: isSelected
                          ? Icon(Icons.check_circle,
                              color: const Color(AppColors.primary), size: 24)
                          : null,
                      onTap: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString(
                            'subtitle_language', lang['code']!);
                        setState(
                            () => _preferredSubtitleLanguage = lang['code']!);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                                "${context.tr('subtitle_language_set')}: ${lang['name']}",
                                style: const TextStyle(fontFamily: 'Tajawal')),
                            backgroundColor: const Color(AppColors.primary)));
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTraktButton() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
              color: const Color(AppColors.primary).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.r)),
          child: _isConnectingTrakt
              ? SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(AppColors.primary),
                  ),
                )
              : Icon(Icons.sync, color: const Color(AppColors.primary))),
      title: Text(
          _isLoggedIn
              ? context.tr('logout_trakt')
              : context.tr('connect_trakt'),
          style: const TextStyle(color: Colors.white, fontFamily: 'Tajawal')),
      trailing: _isConnectingTrakt
          ? null
          : const Icon(Icons.arrow_forward_ios,
              color: Colors.white24, size: 16),
      onTap: _isConnectingTrakt
          ? null
          : () async {
              if (_isLoggedIn) {
                await _disconnectTrakt();
              } else {
                await _connectTrakt();
              }
            },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
        padding: EdgeInsets.only(bottom: 15.h),
        child: Text(title,
            style: TextStyle(
                color: const Color(AppColors.primary),
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'Tajawal')));
  }

  Widget _buildSettingTile(IconData icon, String title, String subtitle,
      {VoidCallback? onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10.r)),
          child: Icon(icon, color: Colors.white70)),
      title: Text(title,
          style: const TextStyle(color: Colors.white, fontFamily: 'Tajawal')),
      subtitle: subtitle.isNotEmpty
          ? Text(subtitle,
              style: const TextStyle(color: Colors.white38, fontSize: 12))
          : null,
      trailing:
          const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
      onTap: onTap ?? () {},
    );
  }
}
