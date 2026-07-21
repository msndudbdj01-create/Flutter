import 'package:flutter/material.dart';
import 'config.dart';

class AppConstants {
  // TMDB
  static String get tmdbApiKey => AppConfig.tmdbKey;
  static const String tmdbBaseUrl = AppConfig.tmdbBaseUrl;
  static const String tmdbImageBaseUrl = '${AppConfig.tmdbImageUrl}/w500';
  static const String tmdbBackdropBaseUrl = '${AppConfig.tmdbImageUrl}/original';
  static const String tmdbPosterBaseUrl = '${AppConfig.tmdbImageUrl}/w500';
  
  // VidKing
  static const String vidkingBaseUrl = AppConfig.vidkingBaseUrl;
  
  // Wyzie Subs
  static const String wyzieBaseUrl = 'https://sub.wyzie.io';
  
  // App Info
  static const String appName = AppConfig.appName;
  static const String appVersion = AppConfig.appVersion;
}

class AppColors {
  static const int background = 0xFF000000;
  static const int cardBackground = 0xFF0A0A0A;
  static const int primary = 0xFF1CE783;
  static const int primaryDark = 0xFF15B868;
  static const int textMain = 0xFFFFFFFF;
  static const int textSecondary = 0xFFB0B0B0;
  static const int textMuted = 0xFF707070;
  static const int ratingStar = 0xFFFFD700;
  static const int error = 0xFFFF4D4D;
  static const int success = 0xFF1CE783;
  static const int warning = 0xFFFFB800;
}