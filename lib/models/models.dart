import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:isar/isar.dart';

// Generates the underlying code needed for queries
part 'models.g.dart';

/// Memory-only presentation class used to parse TMDB search queries or discovery loops
class TmdbPageResponse<T> {
  final int page;
  final List<T> results;
  final int totalPages;
  final int totalResults;

  TmdbPageResponse({
    required this.page,
    required this.results,
    required this.totalPages,
    required this.totalResults,
  });

  factory TmdbPageResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> json) fromJsonModel,
  ) {
    return TmdbPageResponse(
      page: json['page'] ?? 1,
      results:
          (json['results'] as List?)
              ?.map((item) => fromJsonModel(Map<String, dynamic>.from(item)))
              .toList() ??
          [],
      totalPages: json['total_pages'] ?? 0,
      totalResults: json['total_results'] ?? 0,
    );
  }
}

// ==========================================
// EMBEDDED OBJECTS (Stored inside Collections)
// ==========================================
@embedded
class Genre {
  int id = 0;
  String name = '';

  Genre();
  factory Genre.fromJson(Map<dynamic, dynamic> json) {
    return Genre()
      ..id = json['id'] ?? 0
      ..name = json['name'] ?? '';
  }
}

@embedded
class ProductionCompany {
  int id = 0;
  String name = '';
  String logoPath = '';
  String originCountry = '';

  ProductionCompany();
  factory ProductionCompany.fromJson(Map<dynamic, dynamic> json) {
    return ProductionCompany()
      ..id = json['id'] ?? 0
      ..name = json['name'] ?? ''
      ..logoPath = json['logo_path'] ?? ''
      ..originCountry = json['origin_country'] ?? '';
  }
}

@embedded
class ProductionCountry {
  String iso31661 = '';
  String name = '';

  ProductionCountry();
  factory ProductionCountry.fromJson(Map<dynamic, dynamic> json) {
    return ProductionCountry()
      ..iso31661 = json['iso_3166_1'] ?? ''
      ..name = json['name'] ?? '';
  }
}

@embedded
class SpokenLanguage {
  String englishName = '';
  String iso6391 = '';
  String name = '';

  SpokenLanguage();
  factory SpokenLanguage.fromJson(Map<dynamic, dynamic> json) {
    return SpokenLanguage()
      ..englishName = json['english_name'] ?? ''
      ..iso6391 = json['iso_639_1'] ?? ''
      ..name = json['name'] ?? '';
  }
}

@embedded
class Keyword {
  int id = 0;
  String name = '';

  Keyword();
  factory Keyword.fromJson(Map<dynamic, dynamic> json) {
    return Keyword()
      ..id = json['id'] ?? 0
      ..name = json['name'] ?? '';
  }
}

@embedded
class MovieDetail {
  bool adult = false;
  String? backdropPath;
  List<int> genreIds = const [];
  List<Genre> genres = const [];
  String originalLanguage = '';
  String originalTitle = '';
  String overview = '';
  double popularity = 0.0;
  String? posterPath;
  String releaseDate = '';
  bool video = false;
  double voteAverage = 0.0;
  int voteCount = 0;

  String? belongsToCollection;
  int? budget;
  String? homepage;
  String? imdbId;
  List<String> originCountry = const [];
  List<ProductionCompany> productionCompanies = const [];
  List<ProductionCountry> productionCountries = const [];
  int? revenue;
  int? runtime;
  List<SpokenLanguage> spokenLanguages = const [];
  String? status;
  String? tagline;
  List<Keyword> keywords = const [];
  bool hasDetails = false;
  MovieDetail();
  factory MovieDetail.fromJson(Map<String, dynamic> json) {
    return MovieDetail()
      ..adult = json['adult'] ?? false
      ..backdropPath = json['backdrop_path'] ?? ''
      ..voteAverage = json['vote_average'] ?? 0.0
      ..voteCount = json['vote_count'] ?? 0
      ..belongsToCollection = json['belongs_to_collection'] ?? ''
      ..genres = json['genres'] ?? ''
      ..homepage = json['homepage'] ?? ''
      ..imdbId = json['imdb_id'] ?? ''
      ..originCountry = json['origin_country'] ?? ''
      ..originalLanguage = json['original_language'] ?? ''
      ..originalTitle = json['original_title'] ?? ''
      ..overview = json['overview'] ?? ''
      ..popularity = json['popularity'] ?? 0.0
      ..posterPath = json['poster_path'] ?? ''
      ..releaseDate = json['release_date'] ?? ''
      ..status = json['status'] ?? ''
      ..tagline = json['tagline'] ?? ''
      ..runtime = json['runtime'] ?? 0;
  }
}

@embedded
class Cast {
  bool adult = false;
  int gender = 0;
  int id = 0; // TMDB Person ID
  String knownForDepartment = '';
  String name = '';
  String originalName = '';
  double popularity = 0.0;
  String? profilePath;
  int castId = 0;
  String character = '';
  String creditId = '';
  int order = 0;

  Cast();

  factory Cast.fromJson(Map<String, dynamic> json) {
    return Cast()
      ..adult = json['adult'] ?? false
      ..gender = json['gender'] ?? 0
      ..id = json['id'] ?? 0
      ..knownForDepartment = json['known_for_department'] ?? ''
      ..name = json['name'] ?? ''
      ..originalName = json['original_name'] ?? ''
      ..popularity = (json['popularity'] ?? 0.0).toDouble()
      ..profilePath = json['profile_path']
      ..castId = json['cast_id'] ?? 0
      ..character = json['character'] ?? ''
      ..creditId = json['credit_id'] ?? ''
      ..order = json['order'] ?? 0;
  }

  String get fullProfilePath =>
      profilePath != null ? 'https://db.inosuke.sbs/t/p/w500$profilePath' : '';

  String get genderText {
    switch (gender) {
      case 1:
        return 'Female';
      case 2:
        return 'Male';
      default:
        return 'Not specified';
    }
  }
}

@embedded
class Creator {
  int id = 0;
  String creditId = '';
  String name = '';
  int gender = 0;
  String? profilePath;

  Creator();
  factory Creator.fromJson(Map<String, dynamic> json) {
    return Creator()
      ..id = json['id'] ?? 0
      ..creditId = json['credit_id'] ?? ''
      ..name = json['name'] ?? ''
      ..gender = json['gender'] ?? 0
      ..profilePath = json['profile_path'];
  }
}

@embedded
class TvShowDetail {
  int tmdbSeriesId = 0;
  bool adult = false;
  String? backdropPath;
  List<int> genreIds = const [];
  List<Genre> genres = const [];
  List<String> originCountry = const [];
  String originalLanguage = '';
  String originalName = '';
  String overview = '';
  double popularity = 0.0;
  String? posterPath;
  String? firstAirDate;
  String? lastAirDate;
  String name = '';
  double voteAverage = 0.0;
  int voteCount = 0;

  List<Creator> createdBy = const [];
  List<int> episodeRunTime = const [];
  String? homepage;
  bool inProduction = false;
  List<String> languages = const [];
  int numberOfEpisodes = 0;
  int numberOfSeasons = 0;
  List<ProductionCompany> productionCompanies = const [];
  List<ProductionCountry> productionCountries = const [];
  List<SpokenLanguage> spokenLanguages = const [];
  String? status;
  String? tagline;
  String? type;
  bool hasDetails = false;

  TvShowDetail();

  factory TvShowDetail.fromJson(Map<String, dynamic> json) {
    final detail = TvShowDetail()
      ..tmdbSeriesId = json['id'] ?? 0
      ..adult = json['adult'] ?? false
      ..backdropPath = json['backdrop_path']
      ..originalLanguage = json['original_language'] ?? ''
      ..originalName = json['original_name'] ?? ''
      ..overview = json['overview'] ?? ''
      ..popularity = (json['popularity'] ?? 0.0).toDouble()
      ..posterPath = json['poster_path']
      ..firstAirDate = json['first_air_date']
      ..lastAirDate = json['last_air_date']
      ..name = json['name'] ?? ''
      ..voteAverage = (json['vote_average'] ?? 0.0).toDouble()
      ..voteCount = json['vote_count'] ?? 0
      ..homepage = json['homepage']
      ..inProduction = json['in_production'] ?? false
      ..numberOfEpisodes = json['number_of_episodes'] ?? 0
      ..numberOfSeasons = json['number_of_seasons'] ?? 0
      ..status = json['status']
      ..tagline = json['tagline']
      ..type = json['type']
      ..hasDetails =
          json.containsKey('number_of_seasons') || json.containsKey('seasons');

    if (json['genre_ids'] != null) {
      detail.genreIds = List<int>.from(json['genre_ids']);
    } else if (json['genres'] != null) {
      detail.genreIds = (json['genres'] as List)
          .map((g) => g['id'] as int)
          .toList();
    }

    if (json['genres'] != null) {
      detail.genres = (json['genres'] as List)
          .map((g) => Genre.fromJson(g))
          .toList();
    }
    if (json['origin_country'] != null) {
      detail.originCountry = List<String>.from(json['origin_country']);
    }
    if (json['languages'] != null) {
      detail.languages = List<String>.from(json['languages']);
    }
    if (json['episode_run_time'] != null) {
      detail.episodeRunTime = List<int>.from(json['episode_run_time']);
    }
    if (json['created_by'] != null) {
      detail.createdBy = (json['created_by'] as List)
          .map((c) => Creator.fromJson(c))
          .toList();
    }
    if (json['production_companies'] != null) {
      detail.productionCompanies = (json['production_companies'] as List)
          .map((c) => ProductionCompany.fromJson(c))
          .toList();
    }
    if (json['production_countries'] != null) {
      detail.productionCountries = (json['production_countries'] as List)
          .map((c) => ProductionCountry.fromJson(c))
          .toList();
    }
    if (json['spoken_languages'] != null) {
      detail.spokenLanguages = (json['spoken_languages'] as List)
          .map((l) => SpokenLanguage.fromJson(l))
          .toList();
    }

    return detail;
  }

  // ==========================================
  // READ-ONLY GETTERS
  // ==========================================
  String get fullPosterPath =>
      posterPath != null ? 'https://db.inosuke.sbs/t/p/w500$posterPath' : '';
  String get fullBackdropPath => backdropPath != null
      ? 'https://db.inosuke.sbs/t/p/w780$backdropPath'
      : '';

  String get formattedFirstAirDate {
    if (firstAirDate == null || firstAirDate!.isEmpty) return 'Unknown';
    try {
      final date = DateTime.parse(firstAirDate!);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return firstAirDate!;
    }
  }
}

@embedded
class Network {
  int id = 0;
  String name = '';
  String logoPath = '';
  String originCountry = '';

  Network();
  factory Network.fromJson(Map<String, dynamic> json) {
    return Network()
      ..id = json['id'] ?? 0
      ..name = json['name'] ?? ''
      ..logoPath = json['logo_path'] ?? ''
      ..originCountry = json['origin_country'] ?? '';
  }
}

@embedded
class Crew {
  bool adult = false;
  int gender = 0;
  int id = 0;
  String knownForDepartment = '';
  String name = '';
  String originalName = '';
  double popularity = 0.0;
  String? profilePath;
  String creditId = '';
  String department = '';
  String job = '';

  Crew();

  factory Crew.fromJson(Map<String, dynamic> json) {
    return Crew()
      ..adult = json['adult'] ?? false
      ..gender = json['gender'] ?? 0
      ..id = json['id'] ?? 0
      ..knownForDepartment = json['known_for_department'] ?? ''
      ..name = json['name'] ?? ''
      ..originalName = json['original_name'] ?? ''
      ..popularity = (json['popularity'] ?? 0.0).toDouble()
      ..profilePath = json['profile_path']
      ..creditId = json['credit_id'] ?? ''
      ..department = json['department'] ?? ''
      ..job = json['job'] ?? '';
  }

  String get fullProfilePath =>
      profilePath != null ? 'https://db.inosuke.sbs/t/p/w500$profilePath' : '';
}

@embedded
class MovieCredits {
  List<Cast> cast = const [];
  List<Crew> crew = const [];

  MovieCredits();

  factory MovieCredits.fromJson(Map<String, dynamic> json) {
    return MovieCredits()
      ..cast =
          (json['cast'] as List?)?.map((c) => Cast.fromJson(c)).toList() ?? []
      ..crew =
          (json['crew'] as List?)?.map((c) => Crew.fromJson(c)).toList() ?? [];
  }

  // Get directors from crew
  List<Crew> get directors {
    return crew.where((c) => c.job == 'Director').toList();
  }

  // Get writers from crew
  List<Crew> get writers {
    return crew
        .where(
          (c) =>
              c.department == 'Writing' ||
              c.job == 'Screenplay' ||
              c.job == 'Writer' ||
              c.job == 'Story',
        )
        .toList();
  }

  // Get producers from crew
  List<Crew> get producers {
    return crew
        .where(
          (c) =>
              c.department == 'Production' &&
              (c.job == 'Producer' || c.job == 'Executive Producer'),
        )
        .toList();
  }
}

@embedded
class CrewMember {
  int id = 0;
  String name = '';
  String creditId = '';
  String department = '';
  String job = '';
  String? profilePath;

  CrewMember();
  factory CrewMember.fromJson(Map<String, dynamic> json) {
    return CrewMember()
      ..id = json['id'] ?? 0
      ..name = json['name'] ?? ''
      ..creditId = json['credit_id'] ?? ''
      ..department = json['department'] ?? ''
      ..job = json['job'] ?? ''
      ..profilePath = json['profile_path'];
  }
}

@embedded
class GuestStar {
  int id = 0;
  String name = '';
  String character = '';
  String creditId = '';
  int order = 0;
  String? profilePath;

  GuestStar();
  factory GuestStar.fromJson(Map<String, dynamic> json) {
    return GuestStar()
      ..id = json['id'] ?? 0
      ..name = json['name'] ?? ''
      ..character = json['character'] ?? ''
      ..creditId = json['credit_id'] ?? ''
      ..order = json['order'] ?? 0
      ..profilePath = json['profile_path'];
  }
}

@embedded
class EpisodeDetails {
  String airDate = '';
  int episodeNumber = 0;
  String episodeType = '';
  int tmdbEpisodeId = 0; // Renamed to avoid clashing with Isar primary key
  String name = '';
  String overview = '';
  int? runtime;
  int seasonNumber = 0;
  String? stillPath;
  double voteAverage = 0.0;
  int voteCount = 0;

  List<CrewMember> crew = const [];
  List<GuestStar> guestStars = const [];

  EpisodeDetails();
  factory EpisodeDetails.fromJson(Map<String, dynamic> json) {
    return EpisodeDetails()
      ..airDate = json['air_date'] ?? ''
      ..episodeNumber = json['episode_number'] ?? 0
      ..episodeType = json['episode_type'] ?? ''
      ..tmdbEpisodeId = json['id'] ?? 0
      ..name = json['name'] ?? ''
      ..overview = json['overview'] ?? ''
      ..runtime = json['runtime']
      ..seasonNumber = json['season_number'] ?? 0
      ..stillPath = json['still_path']
      ..voteAverage = (json['vote_average'] ?? 0.0).toDouble()
      ..voteCount = json['vote_count'] ?? 0
      ..crew =
          (json['crew'] as List?)
              ?.map((x) => CrewMember.fromJson(x))
              .toList() ??
          []
      ..guestStars =
          (json['guest_stars'] as List?)
              ?.map((x) => GuestStar.fromJson(x))
              .toList() ??
          [];
  }

  String get fullStillPath =>
      stillPath != null ? 'https://db.inosuke.sbs/t/p/w500$stillPath' : '';
}

@embedded
class TvShowSearchResult {
  int tmdbSeriesId = 0; // Renamed from id to avoid Isar keyword clash
  String name = '';
  String originalName = '';
  String? overview;
  String? backdropPath;
  String? posterPath;
  List<int> genreIds = const [];
  List<String> originCountry = const [];
  String originalLanguage = '';
  bool adult = false;
  double popularity = 0.0;
  String? firstAirDate;
  double voteAverage = 0.0;
  int voteCount = 0;

  TvShowSearchResult();
  factory TvShowSearchResult.fromJson(Map<String, dynamic> json) {
    return TvShowSearchResult()
      ..tmdbSeriesId = json['id'] ?? 0
      ..name = json['name'] ?? ''
      ..originalName = json['original_name'] ?? ''
      ..overview = json['overview']
      ..backdropPath = json['backdrop_path']
      ..posterPath = json['poster_path']
      ..genreIds = List<int>.from(json['genre_ids'] ?? [])
      ..originCountry = List<String>.from(json['origin_country'] ?? [])
      ..originalLanguage = json['original_language'] ?? ''
      ..adult = json['adult'] ?? false
      ..popularity = (json['popularity'] ?? 0.0).toDouble()
      ..firstAirDate = json['first_air_date']
      ..voteAverage = (json['vote_average'] ?? 0.0).toDouble()
      ..voteCount = json['vote_count'] ?? 0;
  }

  String get formattedFirstAirDate {
    if (firstAirDate == null || firstAirDate!.isEmpty) return 'Unknown';
    try {
      final date = DateTime.parse(firstAirDate!);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return firstAirDate!;
    }
  }

  String get truncatedOverview {
    if (overview == null) return 'No overview available';
    return overview!.length > 200
        ? '${overview!.substring(0, 200)}...'
        : overview!;
  }
}

@embedded
class PlayState {
  bool isPlayed = false;
  bool isDone = false;
  int playCount = 0;
  List<DateTime> timeIsWatched = const [];
  List<int> watchingTimeMs =
      const []; // Isar prefers primitive lists (Duration mapped to ms)
}

@embedded
class Rating {
  bool isLiked = false;
  bool isDisliked = false;
  int starsCount = 0;
  bool isBookmarked = false;
}

@embedded
class PlayNowState {
  bool isPlaying = false;
  double soundVol = 1.0;
  double screenBright = 1.0;
  double playSpeed = 1.0;
  int timeWatched = 0;
}

@embedded
class MetaData {
  String title = '';
  String description = 'no data exist';
  List<String> genres = const [];
  List<String> tags = const [];
  List<String> covers = const [];
  List<String> backgrounds = const [];
  MovieDetail? movieDetail;
  MovieCredits? credits;
}

@embedded
class PlayUrls {
  String url4k = '';
  String url2k = '';
  String url1080p = '';
  String url720p = '';
  String url540p = '';
  String url480p = '';
  String url360p = '';
}

@embedded
class IsarUserProgress {
  bool isBookmarked = false;
  bool isLiked = false;
  String? lastReadChapterId;
  int lastReadPage = 0;
  DateTime? lastReadAt;
}

class MangaPanel {
   String id;
   double x; // Center X coordinate of the panel
   double y; // Center Y coordinate of the panel
   double width; // Total panel width
   double height; // Total panel height
   double scale; // Optional manual zoom bias multiplier

  MangaPanel({
    required this.id,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.scale = 1.0,
  });

  bool get isHorizontal => width >= height;

  bool get isVertical => height > width;

  String get orientationLabel {
    if (isHorizontal && !isVertical) {
      return 'horizontal';
    }
    if (isVertical && !isHorizontal) {
      return 'vertical';
    }
    return 'square';
  }

  Rect get bounds =>
      Rect.fromLTWH(x - (width / 2), y - (height / 2), width, height);

  double targetScaleForViewport(
    Size viewport, {
    double paddingFraction = 0.12,
    double minScale = 0.05,
    double maxScale = 6.0,
  }) {
     double safePanelWidth = math.max(width, 1.0);
     double safePanelHeight = math.max(height, 1.0);
     double safeViewportWidth = math.max(viewport.width, 1.0);
     double safeViewportHeight = math.max(viewport.height, 1.0);

     double clampedPadding = paddingFraction.clamp(0.0, 0.45);
     double usableWidth = safeViewportWidth * (1.0 - clampedPadding);
     double usableHeight = safeViewportHeight * (1.0 - clampedPadding);

     double fitScale = math.min(
      usableWidth / safePanelWidth,
      usableHeight / safePanelHeight,
    );

     double orientationBias = isHorizontal
        ? 1.10
        : isVertical
        ? 0.95
        : 1.0;

     double targetScale = fitScale * orientationBias * scale;

    return targetScale.clamp(minScale, maxScale).toDouble();
  }

  // Factory to construct instances straight out of your Python script output
  factory MangaPanel.fromJson(Map<String, dynamic> json) {
    return MangaPanel(
      id: json['id'],
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
    );
  }
   // Added toJson method for MangaPanel
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'scale': scale,
    };
  }
}

// ==========================================
// COLLECTIONS (Your Database Tables)
// ==========================================
@collection
class Movie {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  String? movieId; // App UUID lookup string if needed

  String? playableFileId;
  @Index(unique: true, replace: true)
  String? tmdbId;
  @Index(unique: true, replace: true)
  String? malId;
  @Index(unique: true, replace: true)
  String? anilistId;
  String? coverPath;

  MetaData metaData = MetaData();

  Movie();

  factory Movie.fromJson(Map<dynamic, dynamic> json) {
    final movie = Movie();

    // 1. Assign Main Collection Identity properties
    movie.tmdbId = json['id']?.toString();
    movie.coverPath = json['poster_path'];

    // 2. Base Metadata properties initialization
    movie.metaData.title = json['title'] ?? '';
    movie.metaData.description = json['overview'] ?? 'no data exist';

    // 3. Extract Deep TMDB Details
    final detail = MovieDetail()
      ..adult = json['adult'] ?? false
      ..backdropPath = json['backdrop_path']
      ..originalLanguage = json['original_language'] ?? ''
      ..originalTitle = json['original_title'] ?? ''
      ..overview = json['overview'] ?? ''
      ..popularity = (json['popularity'] ?? 0.0).toDouble()
      ..posterPath = json['poster_path']
      ..releaseDate = json['release_date'] ?? ''
      ..video = json['video'] ?? false
      ..voteAverage = (json['vote_average'] ?? 0.0).toDouble()
      ..voteCount = json['vote_count'] ?? 0
      ..belongsToCollection = json['belongs_to_collection']?.toString()
      ..budget = json['budget']
      ..homepage = json['homepage']
      ..imdbId = json['imdb_id']
      ..revenue = json['revenue']
      ..runtime = json['runtime']
      ..status = json['status']
      ..tagline = json['tagline']
      ..hasDetails = json.containsKey('runtime') || json.containsKey('genres');

    // Handle Genre ID Mapping
    if (json.containsKey('genre_ids')) {
      detail.genreIds = List<int>.from(json['genre_ids'] ?? []);
    } else if (json.containsKey('genres')) {
      detail.genreIds =
          (json['genres'] as List?)?.map((g) => g['id'] as int).toList() ?? [];
    }

    // Handle Complex Nested Arrays safely
    if (json['genres'] != null) {
      detail.genres = (json['genres'] as List)
          .map((g) => Genre.fromJson(g))
          .toList();
      movie.metaData.genres = detail.genres.map((g) => g.name).toList();
    }
    if (json['origin_country'] != null) {
      detail.originCountry = List<String>.from(json['origin_country']);
    }
    if (json['production_companies'] != null) {
      detail.productionCompanies = (json['production_companies'] as List)
          .map((c) => ProductionCompany.fromJson(c))
          .toList();
    }
    if (json['production_countries'] != null) {
      detail.productionCountries = (json['production_countries'] as List)
          .map((c) => ProductionCountry.fromJson(c))
          .toList();
    }
    if (json['spoken_languages'] != null) {
      detail.spokenLanguages = (json['spoken_languages'] as List)
          .map((l) => SpokenLanguage.fromJson(l))
          .toList();
    }
    if (json['credits'] != null) {
      movie.metaData.credits = MovieCredits.fromJson(
        Map<String, dynamic>.from(json['credits']),
      );
    }
    // Keyword structure safe parsing logic
    var parsedKeywords = <Keyword>[];
    if (json['keywords'] != null && json['keywords']['keywords'] != null) {
      parsedKeywords = (json['keywords']['keywords'] as List)
          .map((k) => Keyword.fromJson(k))
          .toList();
    } else if (json['keywords'] is List) {
      parsedKeywords = (json['keywords'] as List)
          .map((k) => Keyword.fromJson(k))
          .toList();
    }
    detail.keywords = parsedKeywords;

    // Attach populated details packet directly to the base tracking object
    movie.metaData.movieDetail = detail;
    return movie;
  }

  // ==========================================
  // READ-ONLY GETTERS (Safe Null Checking Guards)
  // ==========================================

  String get fullPosterPath =>
      coverPath != null ? 'https://db.inosuke.sbs/t/p/w500$coverPath' : '';

  String get fullBackdropPath {
    final path = metaData.movieDetail?.backdropPath;
    return path != null ? 'https://db.inosuke.sbs/t/p/w780$path' : '';
  }

  String get formattedRuntime {
    final runtime = metaData.movieDetail?.runtime;
    if (runtime == null || runtime == 0) return 'N/A';
    final hours = runtime ~/ 60;
    final minutes = runtime % 60;
    return hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
  }

  String get formattedBudget {
    final budget = metaData.movieDetail?.budget;
    if (budget == null || budget == 0) return 'N/A';
    return '\$${(budget / 1000000).toStringAsFixed(1)}M';
  }

  String get formattedRevenue {
    final revenue = metaData.movieDetail?.revenue;
    if (revenue == null || revenue == 0) return 'N/A';
    return '\$${(revenue / 1000000).toStringAsFixed(1)}M';
  }

  String get genresText {
    if (metaData.genres.isEmpty) return 'N/A';
    return metaData.genres.join(', ');
  }
}

@collection
class MangaSeries {
  Id id = Isar.autoIncrement; // Isar internal primary key

  @Index(unique: true, replace: true)
  late String seriesId; // App business ID

  @Index(type: IndexType.value, caseSensitive: false)
  late String title;

  @Index(type: IndexType.value, caseSensitive: false)
  late String author;

  late String coverPath;
  late String description;
  IsarUserProgress? progress;

  @Backlink(to: 'seriesLink')
  final chapters = IsarLinks<MangaChapter>();
}

@collection
class MangaChapter {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String chapterId; // App business ID

  @Index()
  late String seriesId; // Foreign reference key

  @Index(type: IndexType.value, caseSensitive: false)
  late String title;

  @Index()
  late double chapterNumber;

  late String pathToChapterData;
  late int totalPages;

  final seriesLink = IsarLink<MangaSeries>();

  @Backlink(to: 'chapterLink')
  final pages = IsarLinks<ChapterPage>();
}

@collection
class ChapterPage {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String pageId; // App business ID

  @Index()
  late String chapterId; // Foreign reference key

  @Index()
  late int pageNumber;

  late String pageFilePath;
  late List<String> panelRawJson;

  final chapterLink = IsarLink<MangaChapter>();
@ignore
List<MangaPanel> get panels => panelRawJson
    .map((str) => MangaPanel.fromJson(jsonDecode(Uri.decodeComponent(str)) as Map<String, dynamic>))
    .toList();}

@collection
class Person {
  @Index(unique: true, replace: true)
  Id id = Isar.autoIncrement; // Isar internal primary key

  @Index(unique: true, replace: true)
  String? tmdbPersonId; // Unique TMDB ID mapped as a searchable String index

  bool adult = false;
  List<String> alsoKnownAs = const []; // Isar handles primitive lists natively
  String? biography;
  String? birthday;
  String? deathday;
  int gender = 0;
  String? homepage;
  @Index(unique: true, replace: true)
  String? imdbId;
  String knownForDepartment = '';
  String name = '';
  String? placeOfBirth;
  double popularity = 0.0;
  String? profilePath;

  Person();

  factory Person.fromJson(Map<String, dynamic> json) {
    final person = Person()
      ..tmdbPersonId = json['id']?.toString()
      ..adult = json['adult'] ?? false
      ..alsoKnownAs = json['also_known_as'] != null
          ? List<String>.from(json['also_known_as'])
          : const []
      ..biography = json['biography']
      ..birthday = json['birthday']
      ..deathday = json['deathday']
      ..gender = json['gender'] ?? 0
      ..homepage = json['homepage']
      ..imdbId = json['imdb_id']
      ..knownForDepartment = json['known_for_department'] ?? ''
      ..name = json['name'] ?? ''
      ..placeOfBirth = json['place_of_birth']
      ..popularity = (json['popularity'] ?? 0.0).toDouble()
      ..profilePath = json['profile_path'];

    return person;
  }

  // ==========================================
  // HELPER GETTERS (Read-Only UI Accessors)
  // ==========================================

  String get fullProfilePath =>
      profilePath != null ? 'https://db.inosuke.sbs/t/p/w500$profilePath' : '';

  String get genderText {
    switch (gender) {
      case 1:
        return 'Female';
      case 2:
        return 'Male';
      default:
        return 'Not specified';
    }
  }

  String get formattedBirthday {
    if (birthday == null || birthday!.isEmpty) return 'Unknown';

    final parts = birthday!.split('-');
    if (parts.length != 3) return birthday!;

    try {
      final year = parts[0];
      final month = _getMonthName(int.parse(parts[1]));
      final day = int.parse(parts[2]);
      return '$month $day, $year';
    } catch (_) {
      return birthday!;
    }
  }

  String get age {
    if (birthday == null || birthday!.isEmpty) return 'Unknown';

    try {
      final birthDate = DateTime.parse(birthday!);
      final today = DateTime.now();

      int calculatedAge = today.year - birthDate.year;
      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        calculatedAge--;
      }

      if (deathday != null && deathday!.isNotEmpty) {
        final deathDate = DateTime.parse(deathday!);
        calculatedAge = deathDate.year - birthDate.year;
        if (deathDate.month < birthDate.month ||
            (deathDate.month == birthDate.month &&
                deathDate.day < birthDate.day)) {
          calculatedAge--;
        }
        return '$calculatedAge (Deceased)';
      }

      return '$calculatedAge years old';
    } catch (_) {
      return 'Unknown';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    if (month < 1 || month > 12) return '';
    return months[month - 1];
  }
}

@collection
class PlayableFile {
  Id id = Isar.autoIncrement; // Auto-generated integer ID for fast indexing

  @Index(unique: true, replace: true)
  String? fileId; // Your custom string UUID if you use one

  String filePath = '';
  PlayState watchState = PlayState();
  Rating rating = Rating();
  PlayNowState playState = PlayNowState();
  bool isVideo = true;
  PlayUrls urls = PlayUrls();
  Map<String, String> getAvailableQualityUrls() {
    final Map<String, String> qualities = {};

    // 1. Check the local file path first
    if (filePath.isNotEmpty) {
      qualities['Local File'] = filePath;
    }

    // 2. Check each streaming resolution url
    if (urls.url4k.isNotEmpty) qualities['4K'] = urls.url4k;
    if (urls.url2k.isNotEmpty) qualities['2K'] = urls.url2k;
    if (urls.url1080p.isNotEmpty) qualities['1080p'] = urls.url1080p;
    if (urls.url720p.isNotEmpty) qualities['720p'] = urls.url720p;
    if (urls.url540p.isNotEmpty) qualities['540p'] = urls.url540p;
    if (urls.url480p.isNotEmpty) qualities['480p'] = urls.url480p;
    if (urls.url360p.isNotEmpty) qualities['360p'] = urls.url360p;

    return qualities;
  }
}

@collection
class Series {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  String? seriesId;
  @Index(unique: true)
  String? malId;
  @Index(unique: true)
  String? tmdbId;
  @Index(unique: true)
  String? anilistId;

  MetaData metaData = MetaData();
  TvShowDetail? tvDetails;
}

@collection
class Season {
  @Index(unique: true)
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  String? seasonId;

  @Index()
  String? seriesId; // Foreign-key lookup index
  @Index()
  int seasonNumber = 1;

  MetaData metaData = MetaData();
}

@collection
class Episode {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  String? episodeId;
  String? playableFileId;
  @Index()
  String? seriesId;
  @Index()
  String? seasonId;

  MetaData metaData = MetaData();
  @Index(unique: true)
  int episodeIndex = 0;

  // Link details directly here!
  EpisodeDetails? details;
}
