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
class MainPicture {
  String? medium;
  String? large;

  MainPicture({this.medium, this.large});

  factory MainPicture.fromJson(Map<String, dynamic> json) {
    return MainPicture(
      medium: json['medium'] as String?,
      large: json['large'] as String?,
    );
  }
}

class Node {
  final int id;
  final String title;
  final MainPicture mainPicture;

  Node({required this.id, required this.title, required this.mainPicture});

  Node copyWith({int? id, String? title, MainPicture? mainPicture}) {
    return Node(
      id: id ?? this.id,
      title: title ?? this.title,
      mainPicture: mainPicture ?? this.mainPicture,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'title': title, 'main_picture': mainPicture};
  }

  factory Node.fromJson(Map<String, dynamic> json) {
    return Node(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      mainPicture: MainPicture.fromJson(
        json['main_picture'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
    );
  }
}

class AData {
  final Node node;

  AData({required this.node});

  AData copyWith({Node? node}) {
    return AData(node: node ?? this.node);
  }

  Map<String, dynamic> toJson() {
    return {'node': node.toJson()};
  }

  factory AData.fromJson(Map<String, dynamic> json) {
    return AData(
      node: Node.fromJson(
        json['node'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
    );
  }
}

class GetAnimeListResult {
  final List<AData> data;

  GetAnimeListResult({required this.data});

  GetAnimeListResult copyWith({List<AData>? data}) {
    return GetAnimeListResult(data: data ?? this.data);
  }

  Map<String, dynamic> toJson() {
    return {'data': data.map((item) => item.toJson()).toList()};
  }

  factory GetAnimeListResult.fromJson(Map<String, dynamic> json) {
    return GetAnimeListResult(
      data:
          (json['data'] as List<dynamic>?)
              ?.map((item) => AData.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class Genres {
  final int id;
  final String name;

  Genres({required this.id, required this.name});

  Genres copyWith({int? id, String? name}) {
    return Genres(id: id ?? this.id, name: name ?? this.name);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }

  factory Genres.fromJson(Map<String, dynamic> json) {
    return Genres(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
    );
  }
}

class AlternativeTitles {
  List<String> synonyms = [];
  String? en;
  String? ja;

  AlternativeTitles({this.synonyms = const [], this.en, this.ja});

  factory AlternativeTitles.fromJson(Map<String, dynamic> json) {
    return AlternativeTitles(
      synonyms:
          (json['synonyms'] as List<dynamic>?)
              ?.map((item) => item as String)
              .toList() ??
          [],
      en: json['en'] as String? ?? '',
      ja: json['ja'] as String? ?? '',
    );
  }
}

class StartSeason {
  final int year;
  final String season;

  StartSeason({required this.year, required this.season});

  StartSeason copyWith({int? year, String? season}) {
    return StartSeason(year: year ?? this.year, season: season ?? this.season);
  }

  Map<String, dynamic> toJson() {
    return {'year': year, 'season': season};
  }

  factory StartSeason.fromJson(Map<String, dynamic> json) {
    return StartSeason(
      year: json['year'] as int? ?? 0,
      season: json['season'] as String? ?? '',
    );
  }
}

class Broadcast {
  final String dayOfTheWeek;
  final String startTime;

  Broadcast({required this.dayOfTheWeek, required this.startTime});

  Broadcast copyWith({String? dayOfTheWeek, String? startTime}) {
    return Broadcast(
      dayOfTheWeek: dayOfTheWeek ?? this.dayOfTheWeek,
      startTime: startTime ?? this.startTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {'day_of_the_week': dayOfTheWeek, 'start_time': startTime};
  }

  factory Broadcast.fromJson(Map<String, dynamic> json) {
    return Broadcast(
      dayOfTheWeek: json['day_of_the_week'] as String? ?? '',
      startTime: json['start_time'] as String? ?? '',
    );
  }
}

class RelatedAnime {
  final Node node;
  final String relationType;
  final String relationTypeFormatted;

  RelatedAnime({
    required this.node,
    required this.relationType,
    required this.relationTypeFormatted,
  });

  RelatedAnime copyWith({
    Node? node,
    String? relationType,
    String? relationTypeFormatted,
  }) {
    return RelatedAnime(
      node: node ?? this.node,
      relationType: relationType ?? this.relationType,
      relationTypeFormatted:
          relationTypeFormatted ?? this.relationTypeFormatted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'node': node.toJson(),
      'relation_type': relationType,
      'relation_type_formatted': relationTypeFormatted,
    };
  }

  factory RelatedAnime.fromJson(Map<String, dynamic> json) {
    return RelatedAnime(
      node: Node.fromJson(
        json['node'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
      relationType: json['relation_type'] as String? ?? '',
      relationTypeFormatted: json['relation_type_formatted'] as String? ?? '',
    );
  }
}

class Studio {
  final int id;
  final String name;

  Studio({required this.id, required this.name});

  Studio copyWith({int? id, String? name}) {
    return Studio(id: id ?? this.id, name: name ?? this.name);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }

  factory Studio.fromJson(Map<String, dynamic> json) {
    return Studio(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
    );
  }
}

class Picture {
  final String medium;
  final String large;

  Picture({required this.medium, required this.large});

  Picture copyWith({String? medium, String? large}) {
    return Picture(medium: medium ?? this.medium, large: large ?? this.large);
  }

  Map<String, dynamic> toJson() {
    return {'medium': medium, 'large': large};
  }

  factory Picture.fromJson(Map<String, dynamic> json) {
    return Picture(
      medium: json['medium'] as String? ?? '',
      large: json['large'] as String? ?? '',
    );
  }
}

class MyListStatus {
  final String status;
  final int score;
  final int numEpisodesWatched;
  final bool isRewatching;
  final String updatedAt;

  MyListStatus({
    required this.status,
    required this.score,
    required this.numEpisodesWatched,
    required this.isRewatching,
    required this.updatedAt,
  });

  MyListStatus copyWith({
    String? status,
    int? score,
    int? numEpisodesWatched,
    bool? isRewatching,
    String? updatedAt,
  }) {
    return MyListStatus(
      status: status ?? this.status,
      score: score ?? this.score,
      numEpisodesWatched: numEpisodesWatched ?? this.numEpisodesWatched,
      isRewatching: isRewatching ?? this.isRewatching,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'score': score,
      'num_episodes_watched': numEpisodesWatched,
      'is_rewatching': isRewatching,
      'updated_at': updatedAt,
    };
  }

  factory MyListStatus.fromJson(Map<String, dynamic> json) {
    return MyListStatus(
      status: json['status'] as String? ?? '',
      score: json['score'] as int? ?? 0,
      numEpisodesWatched: json['num_episodes_watched'] as int? ?? 0,
      isRewatching: json['is_rewatching'] as bool? ?? false,
      updatedAt: json['updated_at'] as String? ?? '',
    );
  }
}

class StatisticsStatus {
  final String watching;
  final String completed;
  final String onHold;
  final String dropped;
  final String planToWatch;

  StatisticsStatus({
    required this.watching,
    required this.completed,
    required this.onHold,
    required this.dropped,
    required this.planToWatch,
  });

  StatisticsStatus copyWith({
    String? watching,
    String? completed,
    String? onHold,
    String? dropped,
    String? planToWatch,
  }) {
    return StatisticsStatus(
      watching: watching ?? this.watching,
      completed: completed ?? this.completed,
      onHold: onHold ?? this.onHold,
      dropped: dropped ?? this.dropped,
      planToWatch: planToWatch ?? this.planToWatch,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'watching': watching,
      'completed': completed,
      'on_hold': onHold,
      'dropped': dropped,
      'plan_to_watch': planToWatch,
    };
  }

  factory StatisticsStatus.fromJson(Map<String, dynamic> json) {
    return StatisticsStatus(
      watching: json['watching'] as String? ?? '',
      completed: json['completed'] as String? ?? '',
      onHold: json['on_hold'] as String? ?? '',
      dropped: json['dropped'] as String? ?? '',
      planToWatch: json['plan_to_watch'] as String? ?? '',
    );
  }
}

class Statistics {
  final StatisticsStatus status;
  final int numListUsers;

  Statistics({required this.status, required this.numListUsers});

  Statistics copyWith({StatisticsStatus? status, int? numListUsers}) {
    return Statistics(
      status: status ?? this.status,
      numListUsers: numListUsers ?? this.numListUsers,
    );
  }

  Map<String, dynamic> toJson() {
    return {'status': status.toJson(), 'num_list_users': numListUsers};
  }

  factory Statistics.fromJson(Map<String, dynamic> json) {
    return Statistics(
      status: StatisticsStatus.fromJson(
        json['status'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
      numListUsers: json['num_list_users'] as int? ?? 0,
    );
  }
}

class Recommendation {
  final Node node;
  final int numRecommendations;

  Recommendation({required this.node, required this.numRecommendations});

  Recommendation copyWith({Node? node, int? numRecommendations}) {
    return Recommendation(
      node: node ?? this.node,
      numRecommendations: numRecommendations ?? this.numRecommendations,
    );
  }

  Map<String, dynamic> toJson() {
    return {'node': node.toJson(), 'num_recommendations': numRecommendations};
  }

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      node: Node.fromJson(
        json['node'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
      numRecommendations: json['num_recommendations'] as int? ?? 0,
    );
  }
}

class GetAnimeDetailResult {
  final int id;
  final String title;
  final MainPicture mainPicture;
  final AlternativeTitles alternativeTitles;
  final String startDate;
  final String endDate;
  final String synopsis;
  final double mean;
  final int rank;
  final int popularity;
  final int numListUsers;
  final int numScoringUsers;
  final String nsfw;
  final String createdAt;
  final String updatedAt;
  final String mediaType;
  final String status;
  final List<Genres> genres;
  final MyListStatus myListStatus;
  final int numEpisodes;
  final StartSeason startSeason;
  final Broadcast broadcast;
  final String source;
  final int averageEpisodeDuration;
  final String rating;
  final List<Picture> pictures;
  final String background;
  final List<RelatedAnime> relatedAnime;
  final List<dynamic> relatedManga;
  final List<Recommendation> recommendations;
  final List<Studio> studios;
  final Statistics statistics;

  GetAnimeDetailResult({
    required this.id,
    required this.title,
    required this.mainPicture,
    required this.alternativeTitles,
    required this.startDate,
    required this.endDate,
    required this.synopsis,
    required this.mean,
    required this.rank,
    required this.popularity,
    required this.numListUsers,
    required this.numScoringUsers,
    required this.nsfw,
    required this.createdAt,
    required this.updatedAt,
    required this.mediaType,
    required this.status,
    required this.genres,
    required this.myListStatus,
    required this.numEpisodes,
    required this.startSeason,
    required this.broadcast,
    required this.source,
    required this.averageEpisodeDuration,
    required this.rating,
    required this.pictures,
    required this.background,
    required this.relatedAnime,
    required this.relatedManga,
    required this.recommendations,
    required this.studios,
    required this.statistics,
  });

  GetAnimeDetailResult copyWith({
    int? id,
    String? title,
    MainPicture? mainPicture,
    AlternativeTitles? alternativeTitles,
    String? startDate,
    String? endDate,
    String? synopsis,
    double? mean,
    int? rank,
    int? popularity,
    int? numListUsers,
    int? numScoringUsers,
    String? nsfw,
    String? createdAt,
    String? updatedAt,
    String? mediaType,
    String? status,
    List<Genres>? genres,
    MyListStatus? myListStatus,
    int? numEpisodes,
    StartSeason? startSeason,
    Broadcast? broadcast,
    String? source,
    int? averageEpisodeDuration,
    String? rating,
    List<Picture>? pictures,
    String? background,
    List<RelatedAnime>? relatedAnime,
    List<dynamic>? relatedManga,
    List<Recommendation>? recommendations,
    List<Studio>? studios,
    Statistics? statistics,
  }) {
    return GetAnimeDetailResult(
      id: id ?? this.id,
      title: title ?? this.title,
      mainPicture: mainPicture ?? this.mainPicture,
      alternativeTitles: alternativeTitles ?? this.alternativeTitles,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      synopsis: synopsis ?? this.synopsis,
      mean: mean ?? this.mean,
      rank: rank ?? this.rank,
      popularity: popularity ?? this.popularity,
      numListUsers: numListUsers ?? this.numListUsers,
      numScoringUsers: numScoringUsers ?? this.numScoringUsers,
      nsfw: nsfw ?? this.nsfw,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      mediaType: mediaType ?? this.mediaType,
      status: status ?? this.status,
      genres: genres ?? this.genres,
      myListStatus: myListStatus ?? this.myListStatus,
      numEpisodes: numEpisodes ?? this.numEpisodes,
      startSeason: startSeason ?? this.startSeason,
      broadcast: broadcast ?? this.broadcast,
      source: source ?? this.source,
      averageEpisodeDuration:
          averageEpisodeDuration ?? this.averageEpisodeDuration,
      rating: rating ?? this.rating,
      pictures: pictures ?? this.pictures,
      background: background ?? this.background,
      relatedAnime: relatedAnime ?? this.relatedAnime,
      relatedManga: relatedManga ?? this.relatedManga,
      recommendations: recommendations ?? this.recommendations,
      studios: studios ?? this.studios,
      statistics: statistics ?? this.statistics,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'main_picture': mainPicture,
      'alternative_titles': alternativeTitles,
      'start_date': startDate,
      'end_date': endDate,
      'synopsis': synopsis,
      'mean': mean,
      'rank': rank,
      'popularity': popularity,
      'num_list_users': numListUsers,
      'num_scoring_users': numScoringUsers,
      'nsfw': nsfw,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'media_type': mediaType,
      'status': status,
      'genres': genres.map((item) => item).toList(),
      'my_list_status': myListStatus.toJson(),
      'num_episodes': numEpisodes,
      'start_season': startSeason.toJson(),
      'broadcast': broadcast.toJson(),
      'source': source,
      'average_episode_duration': averageEpisodeDuration,
      'rating': rating,
      'pictures': pictures.map((item) => item.toJson()).toList(),
      'background': background,
      'related_anime': relatedAnime.map((item) => item.toJson()).toList(),
      'related_manga': relatedManga,
      'recommendations': recommendations.map((item) => item.toJson()).toList(),
      'studios': studios.map((item) => item.toJson()).toList(),
      'statistics': statistics.toJson(),
    };
  }

  factory GetAnimeDetailResult.fromJson(Map<String, dynamic> json) {
    return GetAnimeDetailResult(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      mainPicture: MainPicture.fromJson(
        json['main_picture'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
      alternativeTitles: AlternativeTitles.fromJson(
        json['alternative_titles'] as Map<String, dynamic>? ??
            <String, dynamic>{},
      ),
      startDate: json['start_date'] as String? ?? '',
      endDate: json['end_date'] as String? ?? '',
      synopsis: json['synopsis'] as String? ?? '',
      mean: (json['mean'] as num?)?.toDouble() ?? 0.0,
      rank: json['rank'] as int? ?? 0,
      popularity: json['popularity'] as int? ?? 0,
      numListUsers: json['num_list_users'] as int? ?? 0,
      numScoringUsers: json['num_scoring_users'] as int? ?? 0,
      nsfw: json['nsfw'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
      mediaType: json['media_type'] as String? ?? '',
      status: json['status'] as String? ?? '',
      genres:
          (json['genres'] as List<dynamic>?)
              ?.map((item) => Genres.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      myListStatus: MyListStatus.fromJson(
        json['my_list_status'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
      numEpisodes: json['num_episodes'] as int? ?? 0,
      startSeason: StartSeason.fromJson(
        json['start_season'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
      broadcast: Broadcast.fromJson(
        json['broadcast'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
      source: json['source'] as String? ?? '',
      averageEpisodeDuration: json['average_episode_duration'] as int? ?? 0,
      rating: json['rating'] as String? ?? '',
      pictures:
          (json['pictures'] as List<dynamic>?)
              ?.map((item) => Picture.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      background: json['background'] as String? ?? '',
      relatedAnime:
          (json['related_anime'] as List<dynamic>?)
              ?.map(
                (item) => RelatedAnime.fromJson(item as Map<String, dynamic>),
              )
              .toList() ??
          [],
      relatedManga: (json['related_manga'] as List<dynamic>?)?.toList() ?? [],
      recommendations:
          (json['recommendations'] as List<dynamic>?)
              ?.map(
                (item) => Recommendation.fromJson(item as Map<String, dynamic>),
              )
              .toList() ??
          [],
      studios:
          (json['studios'] as List<dynamic>?)
              ?.map((item) => Studio.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      statistics: Statistics.fromJson(
        json['statistics'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
    );
  }
}

class MangaCoverImage {
  final String medium;
  final String large;
  final String extraLarge;
  final String color;

  MangaCoverImage({
    required this.medium,
    required this.large,
    required this.extraLarge,
    required this.color,
  });

  MangaCoverImage copyWith({
    String? medium,
    String? large,
    String? extraLarge,
    String? color,
  }) {
    return MangaCoverImage(
      medium: medium ?? this.medium,
      large: large ?? this.large,
      extraLarge: extraLarge ?? this.extraLarge,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'medium': medium,
      'large': large,
      'extraLarge': extraLarge,
      'color': color,
    };
  }

  factory MangaCoverImage.fromJson(Map<String, dynamic> json) {
    return MangaCoverImage(
      medium: json['medium'] as String? ?? '',
      large: json['large'] as String? ?? '',
      extraLarge: json['extraLarge'] as String? ?? '',
      color: json['color'] as String? ?? '',
    );
  }
}

class MangaTitle {
  final String english;
  final String romaji;
  final String native;

  MangaTitle({
    required this.english,
    required this.romaji,
    required this.native,
  });

  MangaTitle copyWith({String? english, String? romaji, String? native}) {
    return MangaTitle(
      english: english ?? this.english,
      romaji: romaji ?? this.romaji,
      native: native ?? this.native,
    );
  }

  Map<String, dynamic> toJson() {
    return {'english': english, 'romaji': romaji, 'native': native};
  }

  factory MangaTitle.fromJson(Map<String, dynamic> json) {
    return MangaTitle(
      english: json['english'] as String? ?? '',
      romaji: json['romaji'] as String? ?? '',
      native: json['native'] as String? ?? '',
    );
  }
}

class MangaMedia {
  final int id;
  final String description;
  final MangaCoverImage coverImage;
  final int? chapters;
  final String bannerImage;
  final List<String> genres;
  final String hashtag;
  final MangaTitle title;

  MangaMedia({
    required this.id,
    required this.description,
    required this.coverImage,
    required this.chapters,
    required this.bannerImage,
    required this.genres,
    required this.hashtag,
    required this.title,
  });

  MangaMedia copyWith({
    int? id,
    String? description,
    MangaCoverImage? coverImage,
    int? chapters,
    String? bannerImage,
    List<String>? genres,
    String? hashtag,
    MangaTitle? title,
  }) {
    return MangaMedia(
      id: id ?? this.id,
      description: description ?? this.description,
      coverImage: coverImage ?? this.coverImage,
      chapters: chapters ?? this.chapters,
      bannerImage: bannerImage ?? this.bannerImage,
      genres: genres ?? this.genres,
      hashtag: hashtag ?? this.hashtag,
      title: title ?? this.title,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'coverImage': coverImage.toJson(),
      'chapters': chapters,
      'bannerImage': bannerImage,
      'genres': genres,
      'hashtag': hashtag,
      'title': title.toJson(),
    };
  }

  factory MangaMedia.fromJson(Map<String, dynamic> json) {
    return MangaMedia(
      id: json['id'] as int? ?? 0,
      description: json['description'] as String? ?? '',
      coverImage: MangaCoverImage.fromJson(
        json['coverImage'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
      chapters: json['chapters'] as int?,
      bannerImage: json['bannerImage'] as String? ?? '',
      genres:
          (json['genres'] as List<dynamic>?)
              ?.map((item) => item as String)
              .toList() ??
          [],
      hashtag: json['hashtag'] as String? ?? '',
      title: MangaTitle.fromJson(
        json['title'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
    );
  }
}

class MangaData {
  final MangaMedia media;

  MangaData({required this.media});

  MangaData copyWith({MangaMedia? media}) {
    return MangaData(media: media ?? this.media);
  }

  Map<String, dynamic> toJson() {
    return {'Media': media.toJson()};
  }

  factory MangaData.fromJson(Map<String, dynamic> json) {
    return MangaData(
      media: MangaMedia.fromJson(
        json['Media'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
    );
  }
}

class GetMangaResult {
  final MangaData data;

  GetMangaResult({required this.data});

  GetMangaResult copyWith({MangaData? data}) {
    return GetMangaResult(data: data ?? this.data);
  }

  Map<String, dynamic> toJson() {
    return {'data': data.toJson()};
  }

  factory GetMangaResult.fromJson(Map<String, dynamic> json) {
    return GetMangaResult(
      data: MangaData.fromJson(
        json['data'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
    );
  }
}

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
  String? overview;
  String? backdropPath;
  String? posterPath;
  double voteAverage = 0.0;
  String releaseDate = '';
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
  MovieDetail moviedetail= MovieDetail();
  Movie();

  factory Movie.fromJson(Map<dynamic, dynamic> json) {
    final movie = Movie();

    // 1. Assign Main Collection Identity properties
    movie.tmdbId = json['id']?.toString();
    movie.coverPath = json['poster_path'];

    // 2. Base Metadata properties initialization
    movie.metaData.title = json['title'] ?? '';
    movie.metaData.overview = json['overview'] ?? 'no data exist';

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
    // if (json['genres'] != null) {
    //   detail.genres = (json['genres'] as List)
    //       .map((g) => Genre.fromJson(g))
    //       .toList();
    //   movie.metaData = detail.genres.map((g) => g.name).toList();
    // }
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
    // if (json['credits'] != null) {
    //   movie.moviedetail.credits = MovieCredits.fromJson(
    //     Map<String, dynamic>.from(json['credits']),
    //   );
    // }
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
     movie.moviedetail = detail;
    return movie;
  }

  // ==========================================
  // READ-ONLY GETTERS (Safe Null Checking Guards)
  // ==========================================

  String get fullPosterPath =>
      coverPath != null ? 'https://db.inosuke.sbs/t/p/w500$coverPath' : '';

  String get fullBackdropPath {
    final path = moviedetail.backdropPath;
    return path != null ? 'https://db.inosuke.sbs/t/p/w780$path' : '';
  }

  String get formattedRuntime {
    final runtime = moviedetail.runtime;
    if (runtime == null || runtime == 0) return 'N/A';
    final hours = runtime ~/ 60;
    final minutes = runtime % 60;
    return hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
  }

  String get formattedBudget {
    final budget = moviedetail.budget;
    if (budget == null || budget == 0) return 'N/A';
    return '\$${(budget / 1000000).toStringAsFixed(1)}M';
  }

  String get formattedRevenue {
    final revenue = moviedetail.revenue;
    if (revenue == null || revenue == 0) return 'N/A';
    return '\$${(revenue / 1000000).toStringAsFixed(1)}M';
  }

  String get genresText {
    if (moviedetail.genres.isEmpty) return 'N/A';
    return moviedetail.genres.join(', ');
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
  String? onlineCoverUrl;
  String? anilistId;
  String? malId;
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
      .map(
        (str) => MangaPanel.fromJson(
          jsonDecode(Uri.decodeComponent(str)) as Map<String, dynamic>,
        ),
      )
      .toList();
}

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

class AnimeNode {
  final AnimeItem node;

  AnimeNode({required this.node});

  factory AnimeNode.fromJson(Map<String, dynamic> json) {
    return AnimeNode(node: AnimeItem.fromJson(json['node']));
  }
}

class AnimeItem {
  final int id;
  final String title;
  final MainPicture? mainPicture;
  final String? synopsis;

  AnimeItem({
    required this.id,
    required this.title,
    this.mainPicture,
    this.synopsis,
  });

  factory AnimeItem.fromJson(Map<String, dynamic> json) {
    return AnimeItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      mainPicture: json['main_picture'] != null
          ? MainPicture.fromJson(json['main_picture'])
          : null,
      synopsis: json['synopsis'] as String?,
    );
  }
}
