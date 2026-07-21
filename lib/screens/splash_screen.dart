import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import '../utils/constants.dart';
import '../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _letterSpacingAnimation;

  bool _isCheckingConnection = true;
  bool _hasConnection = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 1.2, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _letterSpacingAnimation = Tween<double>(begin: 15.0, end: 4.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.9, curve: Curves.fastOutSlowIn),
      ),
    );

    _controller.forward();
    _checkInternetConnection();
  }

  Future<void> _checkInternetConnection() async {
    setState(() => _isCheckingConnection = true);

    final connectivity = Connectivity();
    final result = await connectivity.checkConnectivity();

    _hasConnection = result != ConnectivityResult.none;

    setState(() => _isCheckingConnection = false);

    if (_hasConnection) {
      await _syncStoredLanguage();
      _navigateToHome();
    } else {
      _controller.stop();
      _showNoInternetDialog();
    }
  }

  Future<void> _syncStoredLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    // اللغة الافتراضية هي الإنجليزية إذا لم تكن محفوظة
    final savedLocale = prefs.getString('app_locale') ?? 'en';
    final appState = ZoraAppState.instance;
    if (appState != null) {
      final currentLocaleCode = appState.currentLocale.languageCode;
      if (currentLocaleCode != savedLocale) {
        appState.changeLocale(savedLocale);
      }
    }
  }

  Future<void> _retryConnection() async {
    Navigator.of(context).pop();
    await _checkInternetConnection();
    if (_hasConnection) {
      _controller.forward(from: 0);
    }
  }

  void _showNoInternetDialog() {
    final isRTL = false; // Splash screen قبل تحميل اللغة

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            title: Column(
              children: [
                Icon(
                  Icons.wifi_off_rounded,
                  color: Colors.redAccent,
                  size: 50.sp,
                ),
                SizedBox(height: 15.h),
                Text(
                  "No Internet Connection",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Tajawal',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            content: Text(
              "Please check your internet connection and try again",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14.sp,
                fontFamily: 'Tajawal',
              ),
              textAlign: TextAlign.center,
            ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white10,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                      child: Text(
                        "Exit",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14.sp,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 15.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _retryConnection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(AppColors.primary),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                      child: Text(
                        "Try Again",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToHome() {
    Timer(const Duration(milliseconds: 3500), () {
      if (mounted && _hasConnection) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const HomeScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 1000),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return FadeTransition(
              opacity: _opacityAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: const Color(AppColors.primary)
                                .withOpacity(0.15),
                            blurRadius: 50,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Text(
                        "ZORA",
                        style: TextStyle(
                          color: const Color(AppColors.primary),
                          fontSize: 60.sp,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Tajawal',
                          letterSpacing: _letterSpacingAnimation.value,
                          shadows: [
                            Shadow(
                              blurRadius: 10.0,
                              color: Colors.black.withOpacity(0.5),
                              offset: const Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    if (_isCheckingConnection)
                      SizedBox(
                        width: 40.w,
                        child: LinearProgressIndicator(
                          backgroundColor: Colors.white10,
                          color: const Color(AppColors.primary),
                          minHeight: 2,
                        ),
                      ),
                    if (!_isCheckingConnection && !_hasConnection)
                      Text(
                        "Connection Failed",
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 14.sp,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
