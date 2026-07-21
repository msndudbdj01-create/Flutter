import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../utils/localization.dart';
import '../main.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({Key? key}) : super(key: key);

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _selectedLanguage = 'en';
  bool _isLoading = true;

  final List<Map<String, dynamic>> _languages = [
    {'code': 'en', 'name': 'English', 'nameEn': 'English', 'flag': '🇺🇸'},
    {'code': 'ar', 'name': 'العربية', 'nameEn': 'Arabic', 'flag': '🇸🇦'},
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocale = prefs.getString('app_locale') ?? 'en';
    setState(() {
      _selectedLanguage = savedLocale;
      _isLoading = false;
    });
  }

  Future<void> _changeLanguage(String languageCode) async {
    if (_selectedLanguage == languageCode) return;

    setState(() {
      _selectedLanguage = languageCode;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_locale', languageCode);

    if (mounted) {
      final appState = ZoraAppState.instance;
      if (appState != null) {
        appState.changeLocale(languageCode);
      }

      String message = languageCode == 'ar'
          ? 'تم تغيير اللغة إلى العربية'
          : 'Language changed to English';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: TextStyle(fontFamily: 'Tajawal', fontSize: 13.sp),
          ),
          backgroundColor: const Color(AppColors.primary),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(AppColors.background),
        appBar: AppBar(
          title: Text(
            _selectedLanguage == 'ar' ? "تغيير اللغة" : "Change Language",
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
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
        body: _isLoading
            ? const Center(
                child:
                    CircularProgressIndicator(color: Color(AppColors.primary)),
              )
            : ListView(
                padding: EdgeInsets.all(20.w),
                children: [
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: const Color(AppColors.primary).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: const Color(AppColors.primary).withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.language,
                          color: const Color(AppColors.primary),
                          size: 24.sp,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            _selectedLanguage == 'ar'
                                ? "اختر لغتك المفضلة للتطبيق"
                                : "Choose your preferred language for the app",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13.sp,
                              fontFamily: 'Tajawal',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 30.h),
                  Text(
                    _selectedLanguage == 'ar'
                        ? "اللغات المتاحة"
                        : "Available Languages",
                    style: TextStyle(
                      color: const Color(AppColors.primary),
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                  SizedBox(height: 16.h),
                  ..._languages.map((lang) => _buildLanguageTile(lang)),
                  SizedBox(height: 30.h),
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.white54,
                              size: 16.sp,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              _selectedLanguage == 'ar' ? "ملاحظة:" : "Note:",
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Tajawal',
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          _selectedLanguage == 'ar'
                              ? "تغيير اللغة قد يتطلب إعادة تحميل بعض الشاشات. سيتم تحديث التطبيق تلقائياً."
                              : "Changing the language may require some screens to reload. The app will update automatically.",
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 11.sp,
                            fontFamily: 'Tajawal',
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

  Widget _buildLanguageTile(Map<String, dynamic> lang) {
    final isSelected = _selectedLanguage == lang['code'];

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(AppColors.primary).withOpacity(0.1)
            : Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isSelected
              ? const Color(AppColors.primary).withOpacity(0.3)
              : Colors.white.withOpacity(0.05),
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        leading: Container(
          width: 48.w,
          height: 48.w,
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(AppColors.primary).withOpacity(0.2)
                : Colors.white.withOpacity(0.05),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              lang['flag'],
              style: TextStyle(fontSize: 28.sp),
            ),
          ),
        ),
        title: Text(
          lang['name'],
          style: TextStyle(
            color: isSelected ? const Color(AppColors.primary) : Colors.white,
            fontSize: 16.sp,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontFamily: 'Tajawal',
          ),
        ),
        subtitle: Text(
          lang['nameEn'],
          style: TextStyle(
            color: Colors.white38,
            fontSize: 12.sp,
            fontFamily: 'Tajawal',
          ),
        ),
        trailing: isSelected
            ? Icon(
                Icons.check_circle,
                color: const Color(AppColors.primary),
                size: 24.sp,
              )
            : Icon(
                Icons.radio_button_unchecked,
                color: Colors.white38,
                size: 24.sp,
              ),
        onTap: () => _changeLanguage(lang['code']),
      ),
    );
  }
}
