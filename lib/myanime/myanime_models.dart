class MainPicture {
  final String medium;
  final String large;

  MainPicture({required this.medium, required this.large});

  MainPicture copyWith({String? medium, String? large}) {
    return MainPicture(
      medium: medium ?? this.medium,
      large: large ?? this.large,
    );
  }

  Map<String, dynamic> toJson() {
    return {'medium': medium, 'large': large};
  }

  factory MainPicture.fromJson(Map<String, dynamic> json) {
    return MainPicture(
      medium: json['medium'] as String? ?? '',
      large: json['large'] as String? ?? '',
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
    return {'id': id, 'title': title, 'main_picture': mainPicture.toJson()};
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
  final List<String> synonyms;
  final String en;
  final String ja;

  AlternativeTitles({
    required this.synonyms,
    required this.en,
    required this.ja,
  });

  AlternativeTitles copyWith({List<String>? synonyms, String? en, String? ja}) {
    return AlternativeTitles(
      synonyms: synonyms ?? this.synonyms,
      en: en ?? this.en,
      ja: ja ?? this.ja,
    );
  }

  Map<String, dynamic> toJson() {
    return {'synonyms': synonyms, 'en': en, 'ja': ja};
  }

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
      'main_picture': mainPicture.toJson(),
      'alternative_titles': alternativeTitles.toJson(),
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
      'genres': genres.map((item) => item.toJson()).toList(),
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
