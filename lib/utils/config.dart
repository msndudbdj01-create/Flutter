/// ملف إدارة الإعدادات والمفاتيح الحساسة

class AppConfig {
  // مفاتيح API - يجب تخزينها في Firebase Remote Config أو .env
  static const String tmdbApiKey = String.fromEnvironment('TMDB_API_KEY');
  static const String traktClientId = String.fromEnvironment('TRAKT_CLIENT_ID');
  static const String traktClientSecret =
      String.fromEnvironment('TRAKT_CLIENT_SECRET');

  // مفتاح Subdl API - سيتم جلبه من الرابط، هذا للاحتياط فقط
  static const String subdlApiKey = ''; // سيتم جلب المفتاح من الرابط

  // القيم الافتراضية للتطوير فقط
  static const String _devTmdbKey = '876ca2a0903e3e492a47d54a552951c5';
  static const String _devTraktId =
      '0f07d29f8d9cdc3a3c80ec0ae0ceb5b09c43e9282f9805facee156ffee1b6c1a';
  static const String _devTraktSecret =
      'bf5e05d446102c457c03e5c17e7d4450beab60133800d100acec8d84c7b1ebe8';

  // الحصول على المفتاح المناسب
  static String get tmdbKey => tmdbApiKey.isEmpty ? _devTmdbKey : tmdbApiKey;
  static String get traktId =>
      traktClientId.isEmpty ? _devTraktId : traktClientId;
  static String get traktSecret =>
      traktClientSecret.isEmpty ? _devTraktSecret : traktClientSecret;

  // إعدادات التطبيق
  static const String appName = 'Zora';
  static const String appVersion = '1.0.0';
  static const String appScheme = 'zora';
  static const String redirectUri = 'zora://auth';

  // روابط API
  static const String tmdbBaseUrl = 'https://api.themoviedb.org/3';
  static const String tmdbImageUrl = 'https://image.tmdb.org/t/p';
  static const String traktBaseUrl = 'https://api.trakt.tv';
  static const String vidkingBaseUrl = 'https://vidking.net/embed';

  // روابط Subdl API
  static const String subdlBaseUrl = 'https://api.subdl.com/api/v1/subtitles';
  static const String subdlDownloadBaseUrl = 'https://dl.subdl.com';

  // روابط الدعم
  static const String websiteUrl = 'https://zora.app';
  static const String privacyUrl = 'https://zora.app/privacy';
  static const String termsUrl = 'https://zora.app/terms';
  static const String supportEmail = 'support@zora.app';
}
