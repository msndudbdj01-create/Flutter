/// نموذج بيانات الترجمة
class SubtitleEntry {
  final Duration start;
  final Duration end;
  final String text;

  const SubtitleEntry({
    required this.start,
    required this.end,
    required this.text,
  });

  @override
  String toString() => 'SubtitleEntry(start: $start, end: $end, text: $text)';
}

/// نموذج ترجمة خارجية (من Wyzie أو مدمجة)
class SubtitleSource {
  final String name;
  final String url;
  final String? lang;
  final String? format;

  const SubtitleSource({
    required this.name,
    required this.url,
    this.lang,
    this.format,
  });
}

/// نموذج جودة الفيديو
class VideoQuality {
  final String quality;
  final String url;

  const VideoQuality({
    required this.quality,
    required this.url,
  });
}

/// نموذج إعدادات الترجمة
class SubtitleSettings {
  final double fontSize;
  final int? textColorValue;
  final int? bgColorValue;
  final String fontFamily;
  final double position;

  const SubtitleSettings({
    this.fontSize = 10.0,
    this.textColorValue,
    this.bgColorValue,
    this.fontFamily = 'Default',
    this.position = 20.0,
  });

  SubtitleSettings copyWith({
    double? fontSize,
    int? textColorValue,
    int? bgColorValue,
    String? fontFamily,
    double? position,
  }) {
    return SubtitleSettings(
      fontSize: fontSize ?? this.fontSize,
      textColorValue: textColorValue ?? this.textColorValue,
      bgColorValue: bgColorValue ?? this.bgColorValue,
      fontFamily: fontFamily ?? this.fontFamily,
      position: position ?? this.position,
    );
  }
}

/// حالة المشغل الكاملة
class PlayerState {
  final bool isLoading;
  final bool showControls;
  final bool showSubtitles;
  final bool isDisposed;
  final bool hasNextEpisode;
  final bool isLoadingWyzie;

  final String? extractedUrl;
  final String? selectedQuality;
  final String activeSubText;

  final int currentSeason;
  final int currentEpisode;
  final int ratioIndex;

  final List<SubtitleEntry> parsedSubtitles;
  final List<SubtitleSource> extractedSubUrls;
  final List<VideoQuality> extractedQualities;
  final List<dynamic> wyzieSubtitles;
  final List<dynamic> seasonEpisodes;

  final SubtitleSettings subtitleSettings;

  final List<double?> aspectRatios;

  const PlayerState({
    this.isLoading = true,
    this.showControls = true,
    this.showSubtitles = true,
    this.isDisposed = false,
    this.hasNextEpisode = true,
    this.isLoadingWyzie = false,
    this.extractedUrl,
    this.selectedQuality,
    this.activeSubText = "",
    this.currentSeason = 1,
    this.currentEpisode = 1,
    this.ratioIndex = 0,
    this.parsedSubtitles = const [],
    this.extractedSubUrls = const [],
    this.extractedQualities = const [],
    this.wyzieSubtitles = const [],
    this.seasonEpisodes = const [],
    this.subtitleSettings = const SubtitleSettings(),
    this.aspectRatios = const [null, 16 / 9, 18 / 9, 21 / 9],
  });

  PlayerState copyWith({
    bool? isLoading,
    bool? showControls,
    bool? showSubtitles,
    bool? isDisposed,
    bool? hasNextEpisode,
    bool? isLoadingWyzie,
    String? extractedUrl,
    String? selectedQuality,
    String? activeSubText,
    int? currentSeason,
    int? currentEpisode,
    int? ratioIndex,
    List<SubtitleEntry>? parsedSubtitles,
    List<SubtitleSource>? extractedSubUrls,
    List<VideoQuality>? extractedQualities,
    List<dynamic>? wyzieSubtitles,
    List<dynamic>? seasonEpisodes,
    SubtitleSettings? subtitleSettings,
    List<double?>? aspectRatios,
  }) {
    return PlayerState(
      isLoading: isLoading ?? this.isLoading,
      showControls: showControls ?? this.showControls,
      showSubtitles: showSubtitles ?? this.showSubtitles,
      isDisposed: isDisposed ?? this.isDisposed,
      hasNextEpisode: hasNextEpisode ?? this.hasNextEpisode,
      isLoadingWyzie: isLoadingWyzie ?? this.isLoadingWyzie,
      extractedUrl: extractedUrl ?? this.extractedUrl,
      selectedQuality: selectedQuality ?? this.selectedQuality,
      activeSubText: activeSubText ?? this.activeSubText,
      currentSeason: currentSeason ?? this.currentSeason,
      currentEpisode: currentEpisode ?? this.currentEpisode,
      ratioIndex: ratioIndex ?? this.ratioIndex,
      parsedSubtitles: parsedSubtitles ?? this.parsedSubtitles,
      extractedSubUrls: extractedSubUrls ?? this.extractedSubUrls,
      extractedQualities: extractedQualities ?? this.extractedQualities,
      wyzieSubtitles: wyzieSubtitles ?? this.wyzieSubtitles,
      seasonEpisodes: seasonEpisodes ?? this.seasonEpisodes,
      subtitleSettings: subtitleSettings ?? this.subtitleSettings,
      aspectRatios: aspectRatios ?? this.aspectRatios,
    );
  }
}
