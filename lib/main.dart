import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:app_links/app_links.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/splash_screen.dart';
import 'services/trakt_service.dart';
import 'services/analytics_service.dart';
import 'services/ad_service.dart';
import 'utils/constants.dart';
import 'utils/config.dart';
import 'utils/localization.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  await AnalyticsService.init();
  await AdService.init();

  // تعيين اللغة الافتراضية إلى الإنجليزية
  final prefs = await SharedPreferences.getInstance();
  final savedLocale = prefs.getString('app_locale') ?? 'en';

  runApp(ZoraApp(savedLocale: savedLocale));
}

class ZoraApp extends StatefulWidget {
  final String savedLocale;

  const ZoraApp({super.key, required this.savedLocale});

  @override
  State<ZoraApp> createState() => ZoraAppState();
}

class ZoraAppState extends State<ZoraApp> with WidgetsBindingObserver {
  late AppLinks _appLinks;
  final Connectivity _connectivity = Connectivity();
  bool _isConnected = true;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  late Locale _locale;

  static ZoraAppState? _instance;
  static ZoraAppState? get instance => _instance;

  Locale get currentLocale => _locale;

  @override
  void initState() {
    super.initState();
    _instance = this;
    _locale = Locale(widget.savedLocale);
    WidgetsBinding.instance.addObserver(this);
    _initDeepLinks();
    _initConnectivityListener();
    AnalyticsService.trackSessionStart();
  }

  void changeLocale(String localeCode) {
    setState(() {
      _locale = Locale(localeCode);
    });
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('app_locale', localeCode);
    });
  }

  @override
  void dispose() {
    _instance = null;
    WidgetsBinding.instance.removeObserver(this);
    AnalyticsService.trackSessionEnd();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      AnalyticsService.trackSessionEnd();
    } else if (state == AppLifecycleState.resumed) {
      AnalyticsService.trackSessionStart();
    }
  }

  void _initDeepLinks() {
    _appLinks = AppLinks();
    _appLinks.allUriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) async {
    if (uri.scheme == AppConfig.appScheme && uri.host == 'auth') {
      final code = uri.queryParameters['code'];
      if (code != null) {
        final success = await TraktService.saveToken(code);
        if (success && mounted) {
          _showSnackBar(
              LocalizationService.get(context, 'trakt_connected_success'),
              isSuccess: true);
        }
      }
    }
  }

  void _initConnectivityListener() {
    _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      final isConnected = result != ConnectivityResult.none;
      if (_isConnected != isConnected) {
        _isConnected = isConnected;
        if (!_isConnected) {
          _showSnackBar(
              LocalizationService.get(context, 'no_internet_connection'),
              isError: true,
              isPersistent: true);
        } else {
          _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
          _showSnackBar(LocalizationService.get(context, 'internet_restored'),
              isSuccess: true);
        }
      }
    });

    _connectivity.checkConnectivity().then((result) {
      _isConnected = result != ConnectivityResult.none;
    });
  }

  void _showSnackBar(String message,
      {bool isSuccess = false,
      bool isError = false,
      bool isPersistent = false}) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Tajawal')),
        backgroundColor: isSuccess
            ? const Color(AppColors.success)
            : isError
                ? const Color(AppColors.error)
                : const Color(AppColors.primary),
        duration:
            isPersistent ? const Duration(days: 1) : const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (context, child) {
        return MaterialApp(
          title: AppConfig.appName,
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: _scaffoldMessengerKey,
          locale: _locale,
          // إبقاء الاتجاه دائماً LTR (من اليسار إلى اليمين)
          supportedLocales: const [
            Locale('en', ''), // الإنجليزية
            Locale('ar', ''), // العربية
          ],
          localizationsDelegates: const [
            // مترجم التطبيق المخصص
            LocalizationDelegate(),
            // مترجمات Material المدمجة للنصوص الافتراضية
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            primaryColor: const Color(AppColors.primary),
            scaffoldBackgroundColor: const Color(AppColors.background),
            fontFamily: 'Tajawal',
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Tajawal',
              ),
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Colors.transparent,
              selectedItemColor: Color(AppColors.primary),
              unselectedItemColor: Colors.white38,
              type: BottomNavigationBarType.fixed,
              showSelectedLabels: true,
              showUnselectedLabels: false,
            ),
          ),
          home: Directionality(
            textDirection: TextDirection.ltr,
            child: const SplashScreen(),
          ),
        );
      },
    );
  }
}
