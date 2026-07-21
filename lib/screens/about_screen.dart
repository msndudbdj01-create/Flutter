import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../utils/constants.dart';
import '../utils/localization.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(AppColors.background),
        appBar: AppBar(
          title: Text(context.tr('about_app'),
              style: const TextStyle(
                  fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context)),
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              SizedBox(height: 20.h),
              _buildAppLogo(),
              SizedBox(height: 16.h),
              _buildAppInfo(context),
              SizedBox(height: 24.h),
              _buildDescription(context),
              SizedBox(height: 24.h),
              _buildFeaturesSection(context),
              SizedBox(height: 24.h),
              _buildDeveloperSection(context),
              SizedBox(height: 20.h),
              _buildSocialLinks(),
              SizedBox(height: 20.h),
              _buildShareButton(context),
              SizedBox(height: 16.h),
              _buildCopyright(context),
              SizedBox(height: 30.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppLogo() {
    return Container(
      width: 90.w,
      height: 90.w,
      decoration: BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(AppColors.primary).withOpacity(0.9),
              const Color(AppColors.primary).withOpacity(0.5)
            ]),
        borderRadius: BorderRadius.circular(25.r),
        boxShadow: [
          BoxShadow(
              color: const Color(AppColors.primary).withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 2)
        ],
      ),
      child: Center(
          child: Text("Z",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 48.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Tajawal'))),
    );
  }

  Widget _buildAppInfo(BuildContext context) {
    return Column(
      children: [
        Text("Zora",
            style: TextStyle(
                color: Colors.white,
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'Tajawal')),
        SizedBox(height: 6.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
          decoration: BoxDecoration(
              color: const Color(AppColors.primary).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20.r)),
          child: Text("${context.tr('version')} 1.0.0",
              style: TextStyle(
                  color: const Color(AppColors.primary),
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Tajawal')),
        ),
      ],
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.white.withOpacity(0.08))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.info_outline,
                color: const Color(AppColors.primary), size: 20.sp),
            SizedBox(width: 8.w),
            Text(context.tr('about_app'),
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Tajawal'))
          ]),
          SizedBox(height: 12.h),
          Text(
              context.tr('app_language') == 'ar'
                  ? "Zora هو تطبيق لمشاهدة الأفلام والمسلسلات بجودة عالية. استمتع بمكتبة ضخمة من المحتوى مع إمكانية متابعة المشاهدة ومزامنة القوائم عبر Trakt."
                  : "Zora is a high-quality app for watching movies and TV shows. Enjoy a huge library of content with watch progress tracking and playlist syncing via Trakt.",
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13.sp,
                  height: 1.5,
                  fontFamily: 'Tajawal'),
              textAlign: TextAlign.justify),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection(BuildContext context) {
    final isArabic = context.tr('app_language') == 'ar';
    final features = isArabic
        ? [
            {
              'icon': Icons.play_circle_outline,
              'title': 'مشاهدة مباشرة',
              'description': 'تشغيل سريع بدون تقطيع'
            },
            {
              'icon': Icons.sync,
              'title': 'مزامنة Trakt',
              'description': 'مزامنة المشاهدة والقوائم'
            },
            {
              'icon': Icons.subtitles,
              'title': 'ترجمات متعددة',
              'description': 'دعم ترجمات Subdl'
            },
            {
              'icon': Icons.bookmark_border,
              'title': 'قائمة المشاهدة',
              'description': 'حفظ المحتوى للمتابعة'
            },
          ]
        : [
            {
              'icon': Icons.play_circle_outline,
              'title': 'Direct Playback',
              'description': 'Fast streaming without buffering'
            },
            {
              'icon': Icons.sync,
              'title': 'Trakt Sync',
              'description': 'Sync watch progress and lists'
            },
            {
              'icon': Icons.subtitles,
              'title': 'Multiple Subtitles',
              'description': 'Subdl subtitle support'
            },
            {
              'icon': Icons.bookmark_border,
              'title': 'Watchlist',
              'description': 'Save content for later'
            },
          ];
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.white.withOpacity(0.08))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.star,
                color: const Color(AppColors.primary), size: 20.sp),
            SizedBox(width: 8.w),
            Text(isArabic ? "الميزات الرئيسية" : "Key Features",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Tajawal'))
          ]),
          SizedBox(height: 12.h),
          ...features
              .map((feature) => Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: Row(
                      children: [
                        Container(
                            width: 36.w,
                            height: 36.w,
                            decoration: BoxDecoration(
                                color: const Color(AppColors.primary)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10.r)),
                            child: Icon(feature['icon'] as IconData,
                                color: const Color(AppColors.primary),
                                size: 18.sp)),
                        SizedBox(width: 12.w),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(feature['title'] as String,
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Tajawal')),
                              Text(feature['description'] as String,
                                  style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 11.sp,
                                      fontFamily: 'Tajawal'))
                            ])),
                      ],
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildDeveloperSection(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.white.withOpacity(0.08))),
      child: Row(
        children: [
          Container(
              width: 50.w,
              height: 50.w,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [
                    const Color(AppColors.primary).withOpacity(0.5),
                    const Color(AppColors.primary).withOpacity(0.2)
                  ])),
              child: Icon(Icons.person, color: Colors.white, size: 28.sp)),
          SizedBox(width: 15.w),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(context.tr('developer'),
                style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11.sp,
                    fontFamily: 'Tajawal')),
            Text("FAROU9",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Tajawal')),
            Text("Algeria 🇩🇿",
                style: TextStyle(
                    color: Colors.white38,
                    fontSize: 12.sp,
                    fontFamily: 'Tajawal')),
          ]),
        ],
      ),
    );
  }

  Widget _buildSocialLinks() {
    return Wrap(
      spacing: 12.w,
      runSpacing: 10.h,
      alignment: WrapAlignment.center,
      children: [
        _buildSocialButton(
            icon: Icons.telegram,
            label: "Telegram",
            url: "https://t.me/zora_dz"),
        _buildSocialButton(
            icon: Icons.email,
            label: "Email",
            url: "mailto:farou9valhalla@gmail.com"),
      ],
    );
  }

  Widget _buildSocialButton(
      {required IconData icon, required String label, required String url}) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri))
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      },
      child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(30.r),
              border: Border.all(color: Colors.white.withOpacity(0.1))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: const Color(AppColors.primary), size: 18.sp),
            SizedBox(width: 6.w),
            Text(label,
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.sp,
                    fontFamily: 'Tajawal'))
          ])),
    );
  }

  Widget _buildShareButton(BuildContext context) {
    final isArabic = context.tr('app_language') == 'ar';
    final shareText = isArabic
        ? 'مرحباً! قم بتحميل تطبيق Zora لمشاهدة الأفلام والمسلسلات بجودة عالية\n\nhttps://zora.rf.gd'
        : 'Hello! Download Zora app to watch movies and TV shows in high quality\n\nhttps://zora.rf.gd';
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      child: GestureDetector(
        onTap: () => Share.share(shareText),
        child: Container(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  const Color(AppColors.primary),
                  const Color(AppColors.primary).withOpacity(0.8)
                ]),
                borderRadius: BorderRadius.circular(30.r)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.share, color: Colors.black, size: 18.sp),
              SizedBox(width: 8.w),
              Text(context.tr('share_app'),
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Tajawal'))
            ])),
      ),
    );
  }

  Widget _buildCopyright(BuildContext context) {
    return Column(children: [
      Text("© ${DateTime.now().year} Zora",
          style: TextStyle(
              color: Colors.white38, fontSize: 11.sp, fontFamily: 'Tajawal')),
      SizedBox(height: 4.h),
      Text(context.tr('copyright'),
          style: TextStyle(
              color: Colors.white24, fontSize: 10.sp, fontFamily: 'Tajawal')),
    ]);
  }
}
