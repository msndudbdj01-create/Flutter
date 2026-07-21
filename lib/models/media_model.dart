import '../utils/constants.dart';

class Media {
  final int id;
  final String title;
  final String? posterPath;
  final String? backdropPath;
  final String? overview;
  final double? voteAverage;
  final String? releaseDate;
  final String? firstAirDate;
  final String mediaType;
  final String? certification;
  final List<String>? genres;
  List<Season>? seasons;

  Media({
    required this.id,
    required this.title,
    this.posterPath,
    this.backdropPath,
    this.overview,
    this.voteAverage,
    this.releaseDate,
    this.firstAirDate,
    required this.mediaType,
    this.certification,
    this.genres,
    this.seasons,
  });

  factory Media.fromJson(Map<String, dynamic> json, String type) {
    return Media(
      id: json['id'] as int? ?? 0,
      title: type == 'movie' 
          ? (json['title'] as String? ?? json['name'] as String? ?? '')
          : (json['name'] as String? ?? json['title'] as String? ?? ''),
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      overview: json['overview'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
      releaseDate: type == 'movie' ? json['release_date'] as String? : null,
      firstAirDate: type == 'tv' ? json['first_air_date'] as String? : null,
      mediaType: type,
      certification: json['certification'] as String?,
      genres: (json['genres'] as List<dynamic>?)
          ?.map((g) => g['name'] as String? ?? '')
          .where((g) => g.isNotEmpty)
          .toList(),
    );
  }

  Media copyWith({
    int? id,
    String? title,
    String? posterPath,
    String? backdropPath,
    String? overview,
    double? voteAverage,
    String? releaseDate,
    String? firstAirDate,
    String? mediaType,
    String? certification,
    List<String>? genres,
    List<Season>? seasons,
  }) {
    return Media(
      id: id ?? this.id,
      title: title ?? this.title,
      posterPath: posterPath ?? this.posterPath,
      backdropPath: backdropPath ?? this.backdropPath,
      overview: overview ?? this.overview,
      voteAverage: voteAverage ?? this.voteAverage,
      releaseDate: releaseDate ?? this.releaseDate,
      firstAirDate: firstAirDate ?? this.firstAirDate,
      mediaType: mediaType ?? this.mediaType,
      certification: certification ?? this.certification,
      genres: genres ?? this.genres,
      seasons: seasons ?? this.seasons,
    );
  }

  String get posterUrl {
    if (posterPath == null || posterPath!.isEmpty) return '';
    return '${AppConstants.tmdbImageBaseUrl}$posterPath';
  }

  String get backdropUrl {
    if (backdropPath == null || backdropPath!.isEmpty) return '';
    return '${AppConstants.tmdbBackdropBaseUrl}$backdropPath';
  }

  String get year {
    final date = mediaType == 'movie' ? releaseDate : firstAirDate;
    if (date != null && date.length >= 4) {
      return date.substring(0, 4);
    }
    return '';
  }

  String get displayTitle => title;
  
  String get typeText => mediaType == 'movie' ? 'فيلم' : 'مسلسل';
  
  bool get isMovie => mediaType == 'movie';
  bool get isTV => mediaType == 'tv';
}

class Season {
  final int seasonNumber;
  final int episodeCount;
  final String? posterPath;
  final String? name;
  final String? overview;

  Season({
    required this.seasonNumber,
    required this.episodeCount,
    this.posterPath,
    this.name,
    this.overview,
  });

  factory Season.fromJson(Map<String, dynamic> json) {
    return Season(
      seasonNumber: json['season_number'] as int? ?? 0,
      episodeCount: json['episode_count'] as int? ?? 0,
      posterPath: json['poster_path'] as String?,
      name: json['name'] as String?,
      overview: json['overview'] as String?,
    );
  }

  String get posterUrl {
    if (posterPath == null || posterPath!.isEmpty) return '';
    return '${AppConstants.tmdbImageBaseUrl}$posterPath';
  }
  
  String get displayName => name ?? 'الموسم $seasonNumber';
}

class Episode {
  final int episodeNumber;
  final String name;
  final String? overview;
  final String? stillPath;
  final double? voteAverage;
  final String? airDate;

  Episode({
    required this.episodeNumber,
    required this.name,
    this.overview,
    this.stillPath,
    this.voteAverage,
    this.airDate,
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      episodeNumber: json['episode_number'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      overview: json['overview'] as String?,
      stillPath: json['still_path'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
      airDate: json['air_date'] as String?,
    );
  }

  String get stillUrl {
    if (stillPath == null || stillPath!.isEmpty) return '';
    return '${AppConstants.tmdbImageBaseUrl}$stillPath';
  }
  
  String get displayName => 'الحلقة $episodeNumber: $name';
}