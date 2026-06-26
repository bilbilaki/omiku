import 'package:anilist/anilist.dart' as al;
import 'package:dio/dio.dart';

import '../../models/models.dart';
import '../database.dart';

/// Comprehensive AniList service wrapping the full anilist package.
/// Provides every major query type + automatic Isar caching where applicable.
/// Designed to be the single source for AniList data in the app.
class AnilistService {
  final DatabaseService _db;
  final Dio? _client;

  AnilistService({DatabaseService? db, this._client})
      : _db = db ?? DatabaseService();

  // ============================================================
  // MEDIA (Anime + Manga)
  // ============================================================

  /// Get single media by AniList ID. Saves to DB.
  Future<al.AnilistMedia?> getMediaById(int id, {bool saveToDb = true}) async {
    final req = al.AnilistMediaRequest(client: _client)
      ..withTitle()
      ..withCoverImage()
      ..withBannerImage()
      ..withDescription()
      ..withGenres()
      ..withTags()
      ..withFormat()
      ..withStatus()
      ..withEpisodes()
      ..withChapters()
      ..withVolumes()
      ..withAverageScore()
      ..withMeanScore()
      ..withPopularity()
      ..withFavourites()
      ..withSeason()
      ..withSeasonYear()
      ..withStartDate()
      ..withEndDate()
      ..withSource()
      ..withCountryOfOrigin()
      ..withIsLicensed();

    final media = await req.byId(id);
    if (saveToDb) {
      await _saveMediaToDb(media);
    }
    return media;
  }

  /// Search media with flexible filters.
  Future<al.AnilistQueryResult<al.AnilistMedia>> searchMedia(
    String search, {
    al.AnilistMediaType? type,
    List<al.AnilistMediaSort>? sort,
    int perPage = 20,
    int page = 1,
    List<String>? genres,
    List<String>? tags,
    bool? isAdult,
    int? seasonYear,
    al.AnilistMediaSeason? season,
    al.AnilistMediaFormat? format,
    al.AnilistMediaStatus? status,
    int? minPopularity,
    int? minScore,
  }) async {
    final req = al.AnilistMediaRequest(client: _client)
      ..withTitle()
      ..withCoverImage()
      ..withGenres()
      ..withAverageScore()
      ..withPopularity()
      ..withFormat()
      ..withStatus()
      ..withSeason()
      ..withSeasonYear();

    if (search.isNotEmpty) req.querySearch(search);
    if (type != null) req.queryType(type);
    if (sort != null && sort.isNotEmpty) req.sort(sort);
    if (genres != null && genres.isNotEmpty) req.queryGenre_in(genres);
    if (tags != null && tags.isNotEmpty) req.queryTag_in(tags);
    if (isAdult != null) req.queryIsAdult(isAdult);
    if (seasonYear != null) req.querySeasonYear(seasonYear);
    if (season != null) req.querySeason(season);
    if (format != null) req.queryFormat(format);
    if (status != null) req.queryStatus(status);
    if (minPopularity != null) req.queryPopularity_greater(minPopularity);
    if (minScore != null) req.queryAverageScore_greater(minScore);

    final result = await req.list(perPage, page);

    if (result.results != null) {
      for (final m in result.results!) {
        await _saveMediaToDb(m);
      }
    }
    return result;
  }

  /// Trending media (global).
  Future<al.AnilistQueryResult<al.AnilistMedia>> getTrendingMedia({
    al.AnilistMediaType? type,
    int perPage = 20,
    int page = 1,
  }) async {
    final req = al.AnilistMediaRequest(client: _client)
      ..withTitle()
      ..withCoverImage()
      ..withAverageScore()
      ..withPopularity();
    if (type != null) req.queryType(type);
    req.sort([al.AnilistMediaSort.TRENDING_DESC]);
    return req.list(perPage, page);
  }

  /// Popular media.
  Future<al.AnilistQueryResult<al.AnilistMedia>> getPopularMedia({
    al.AnilistMediaType? type,
    int perPage = 20,
    int page = 1,
  }) async {
    final req = al.AnilistMediaRequest(client: _client)
      ..withTitle()
      ..withCoverImage()
      ..withAverageScore()
      ..withPopularity();
    if (type != null) req.queryType(type);
    req.sort([al.AnilistMediaSort.POPULARITY_DESC]);
    return req.list(perPage, page);
  }

  /// Top rated / score.
  Future<al.AnilistQueryResult<al.AnilistMedia>> getTopRatedMedia({
    al.AnilistMediaType? type,
    int perPage = 20,
    int page = 1,
  }) async {
    final req = al.AnilistMediaRequest(client: _client)
      ..withTitle()
      ..withCoverImage()
      ..withAverageScore();
    if (type != null) req.queryType(type);
    req.sort([al.AnilistMediaSort.SCORE_DESC]);
    return req.list(perPage, page);
  }

  /// Current season / upcoming.
  Future<al.AnilistQueryResult<al.AnilistMedia>> getSeasonalMedia({
    required int year,
    required al.AnilistMediaSeason season,
    al.AnilistMediaType type = al.AnilistMediaType.ANIME,
    int perPage = 30,
    int page = 1,
  }) async {
    final req = al.AnilistMediaRequest(client: _client)
      ..withTitle()
      ..withCoverImage()
      ..withGenres()
      ..withStatus()
      ..withAverageScore();
    req.queryType(type);
    req.querySeasonYear(year);
    req.querySeason(season);
    req.sort([al.AnilistMediaSort.POPULARITY_DESC]);
    return req.list(perPage, page);
  }

  /// Media by MAL ID (useful for cross-sync).
  Future<al.AnilistMedia?> getMediaByMalId(int malId) async {
    final req = al.AnilistMediaRequest(client: _client)
      ..withTitle()
      ..withCoverImage()
      ..queryIdMal(malId);
    final result = await req.list(1, 1);
    if (result.results != null && result.results!.isNotEmpty) {
      final m = result.results!.first;
      await _saveMediaToDb(m);
      return m;
    }
    return null;
  }

  // ============================================================
  // CHARACTERS
  // ============================================================

  Future<al.AnilistCharacter?> getCharacterById(int id) async {
    final req = al.AnilistCharacterRequest(client: _client)
      ..withName()
      ..withImage()
      ..withDescription()
      ..withGender()
      ..withAge()
      ..withBloodType()
      ..withFavourites()
      ..withSiteUrl();
    return req.byId(id);
  }

  Future<al.AnilistQueryResult<al.AnilistCharacter>> searchCharacters(
    String search, {
    int perPage = 20,
    int page = 1,
    List<al.AnilistCharacterSort>? sort,
  }) async {
    final req = al.AnilistCharacterRequest(client: _client)
      ..withName()
      ..withImage()
      ..withFavourites();
    if (search.isNotEmpty) req.querySearch(search);
    if (sort != null) req.sort(sort);
    return req.list(perPage, page);
  }

  // ============================================================
  // STAFF
  // ============================================================

  Future<al.AnilistStaff?> getStaffById(int id) async {
    final req = al.AnilistStaffRequest(client: _client)
      ..withName()
      ..withImage()
      ..withDescription()
      ..withGender()
      ..withAge()
      ..withPrimaryOccupations()
      ..withFavourites()
      ..withSiteUrl();
    return req.byId(id);
  }

  Future<al.AnilistQueryResult<al.AnilistStaff>> searchStaff(
    String search, {
    int perPage = 20,
    int page = 1,
  }) async {
    final req = al.AnilistStaffRequest(client: _client)
      ..withName()
      ..withImage()
      ..withFavourites();
    if (search.isNotEmpty) req.querySearch(search);
    return req.list(perPage, page);
  }

  // ============================================================
  // USERS + VIEWER
  // ============================================================

  Future<al.AnilistUser?> getUserById(int id) async {
    final req = al.AnilistUserRequest(client: _client)
      ..withName()
      ..withAvatar()
      ..withBannerImage()
      ..withAbout()
      ..withStatistics()
      ..withMediaListOptions();
    return req.byId(id);
  }

  Future<al.AnilistUser?> getViewer() async {
    final req = al.AnilistUserRequest(client: _client)
      ..withName()
      ..withAvatar()
      ..withStatistics()
      ..withUnreadNotificationCount();
    return req.viewer();
  }

  Future<al.AnilistQueryResult<al.AnilistUser>> searchUsers(
    String search, {
    int perPage = 20,
    int page = 1,
  }) async {
    final req = al.AnilistUserRequest(client: _client)..withName()..withAvatar();
    if (search.isNotEmpty) req.querySearch(search);
    return req.list(perPage, page);
  }

  Future<List<al.AnilistUser>> getFollowing(int userId, {int perPage = 50, int page = 1}) async {
    final req = al.AnilistFollowRequest(client: _client);
    return req.fetchFollowing(userId, perPage: perPage, page: page);
  }

  Future<List<al.AnilistUser>> getFollowers(int userId, {int perPage = 50, int page = 1}) async {
    final req = al.AnilistFollowRequest(client: _client);
    return req.fetchFollowers(userId, perPage: perPage, page: page);
  }

  // ============================================================
  // MEDIA LIST + COLLECTIONS
  // ============================================================

  Future<al.AnilistMediaListCollection> getUserMediaListCollection({
    int? userId,
    String? userName,
    required al.AnilistMediaType type,
    int? chunk,
    int? perChunk,
  }) async {
    final req = al.AnilistMediaListCollectionRequest(client: _client)
      ..withLists()
      ..withUser()
      ..withHasNextChunk();
    return req.fetch(
      userId: userId,
      userName: userName,
      type: type,
      chunk: chunk,
      perChunk: perChunk,
    );
  }

  Future<al.AnilistMediaList?> getMediaListEntryById(int id) async {
    final req = al.AnilistMediaListRequest(client: _client)
      ..withId()
      ..withStatus()
      ..withScore()
      ..withProgress()
      ..withMedia(al.AnilistSubquery(al.AnilistMediaSelect()
        ..withTitle()
        ..withCoverImage()));
    return req.byId(id);
  }

  // ============================================================
  // TRENDS, AIRING, SCHEDULES
  // ============================================================

  Future<al.AnilistMediaTrend?> getMediaTrendByMediaId(int mediaId) async {
    final req = al.AnilistMediaTrendRequest(client: _client)
      ..withMediaId()
      ..withTrending()
      ..withAverageScore()
      ..withPopularity()
      ..withEpisode()
      ..withDate()
      ..withReleasing()
      ..withMedia(al.AnilistSubquery(al.AnilistMediaSelect()..withTitle()));
    return req.byMediaId(mediaId);
  }

  Future<al.AnilistQueryResult<al.AnilistMediaTrend>> getMediaTrends({
    int perPage = 20,
    int page = 1,
  }) async {
    final req = al.AnilistMediaTrendRequest(client: _client)
      ..withMediaId()
      ..withTrending();
    return req.list(perPage, page);
  }

  Future<al.AnilistAiringSchedule?> getAiringScheduleById(int id) async {
    final req = al.AnilistAiringScheduleRequest(client: _client)
      ..withId()
      ..withEpisode()
      ..withAiringAt()
      ..withTimeUntilAiring()
      ..withMedia(al.AnilistSubquery(al.AnilistMediaSelect()..withTitle()));
    return req.byId(id);
  }

  Future<al.AnilistQueryResult<al.AnilistAiringSchedule>> getAiringSchedule({
    int? mediaId,
    int? episode,
    bool? notYetAired,
    List<al.AnilistAiringSort>? sort,
    int perPage = 30,
    int page = 1,
  }) async {
    final req = al.AnilistAiringScheduleRequest(client: _client)
      ..withId()
      ..withEpisode()
      ..withAiringAt()
      ..withMedia(al.AnilistSubquery(al.AnilistMediaSelect()..withTitle()..withCoverImage()));

    if (mediaId != null) req.queryMediaId(mediaId);
    if (episode != null) req.queryEpisode(episode);
    if (notYetAired != null) req.queryNotYetAired(notYetAired);
    if (sort != null) req.sort(sort);

    return req.list(perPage, page);
  }

  // ============================================================
  // STUDIOS, REVIEWS, RECOMMENDATIONS
  // ============================================================

  Future<al.AnilistStudio?> getStudioById(int id) async {
    final req = al.AnilistStudioRequest(client: _client)
      ..withName()
      ..withIsAnimationStudio()
      ..withFavourites()
      ..withSiteUrl()
      ..withMedia(al.AnilistSubquery(al.AnilistMediaSelect()..withTitle()));
    return req.byId(id);
  }

  Future<al.AnilistQueryResult<al.AnilistStudio>> searchStudios(String search, {int perPage = 20, int page = 1}) async {
    final req = al.AnilistStudioRequest(client: _client)..withName()..withFavourites();
    if (search.isNotEmpty) req.querySearch(search);
    return req.list(perPage, page);
  }

  Future<al.AnilistReview?> getReviewById(int id) async {
    final req = al.AnilistReviewRequest(client: _client)
      ..withSummary()
      ..withBody()
      ..withScore()
      ..withRating()
      ..withUser(al.AnilistSubquery(al.AnilistUserSelect()..withName()..withAvatar()))
      ..withMedia(al.AnilistSubquery(al.AnilistMediaSelect()..withTitle()));
    return req.byId(id);
  }

  Future<al.AnilistQueryResult<al.AnilistReview>> getReviewsForMedia(int mediaId, {int perPage = 10, int page = 1}) async {
    final req = al.AnilistReviewRequest(client: _client)
      ..withSummary()
      ..withScore()
      ..withUser(al.AnilistSubquery(al.AnilistUserSelect()..withName()));
    req.queryMediaId(mediaId);
    req.sort([al.AnilistReviewSort.RATING_DESC]);
    return req.list(perPage, page);
  }

  Future<al.AnilistRecommendation?> getRecommendationById(int id) async {
    final req = al.AnilistRecommendationRequest(client: _client)
      ..withRating()
      ..withMedia(al.AnilistSubquery(al.AnilistMediaSelect()..withTitle()..withCoverImage()))
      ..withMediaRecommendation(al.AnilistSubquery(al.AnilistMediaSelect()..withTitle()..withCoverImage()));
    return req.byId(id);
  }

  Future<al.AnilistQueryResult<al.AnilistRecommendation>> getRecommendationsForMedia(
    int mediaId, {
    int perPage = 10,
    int page = 1,
  }) async {
    final req = al.AnilistRecommendationRequest(client: _client)
      ..withRating()
      ..withMediaRecommendation(al.AnilistSubquery(al.AnilistMediaSelect()..withTitle()..withCoverImage()));
    req.queryMediaId(mediaId);
    return req.list(perPage, page);
  }

  // ============================================================
  // NOTIFICATIONS + ACTIVITY
  // ============================================================

  Future<al.AnilistQueryResult<al.AnilistNotification>> getNotifications({
    bool resetCount = false,
    int perPage = 20,
    int page = 1,
  }) async {
    final req = al.AnilistNotificationRequest(client: _client)
      ..withId()
      ..withType()
      ..withContext()
      ..withCreatedAt()
      ..withMedia(al.AnilistSubquery(al.AnilistMediaSelect()..withTitle()));
    return req.list(perPage, page);
  }

  Future<List<al.AnilistNotification>> fetchNotifications({bool resetCount = false}) async {
    final req = al.AnilistNotificationRequest(client: _client);
    return req.fetch(resetCount: resetCount);
  }

  Future<al.AnilistActivity?> getActivityById(int id) async {
    final req = al.AnilistActivityRequest(client: _client)
      ..withId()
      ..withType()
      ..withText()
      ..withCreatedAt()
      ..withUser(al.AnilistSubquery(al.AnilistUserSelect()..withName()..withAvatar()))
      ..withMedia(al.AnilistSubquery(al.AnilistMediaSelect()..withTitle()));
    return req.byId(id);
  }

  Future<al.AnilistQueryResult<al.AnilistActivity>> getActivities({
    int? userId,
    int? mediaId,
    al.AnilistActivityType? type,
    int perPage = 20,
    int page = 1,
  }) async {
    final req = al.AnilistActivityRequest(client: _client)
      ..withId()
      ..withType()
      ..withText()
      ..withCreatedAt();
    if (userId != null) req.queryUserId(userId);
    if (mediaId != null) req.queryMediaId(mediaId);
    if (type != null) req.queryType(type);
    return req.list(perPage, page);
  }

  // ============================================================
  // LIKES
  // ============================================================

  Future<List<al.AnilistUser>> getLikes({
    required int likeableId,
    required al.AnilistLikeableType type,
  }) async {
    final req = al.AnilistLikeRequest(client: _client)..withUser(al.AnilistSubquery(al.AnilistUserSelect()..withName()..withAvatar()));
    return req.fetchLikes(likeableId: likeableId, type: type);
  }

  // ============================================================
  // GLOBAL COLLECTIONS (Genres / Tags)
  // ============================================================

  Future<List<String>> getGenreCollection() async {
    final req = al.AnilistCollectionRequest(client: _client);
    return req.genreCollection();
  }

  Future<List<al.AnilistTag>> getMediaTagCollection() async {
    final req = al.AnilistCollectionRequest(client: _client);
    return req.mediaTagCollection();
  }

  // ============================================================
  // EXTERNAL LINKS + MARKDOWN
  // ============================================================

  Future<List<al.AnilistExternalLink>> getExternalLinkSources({
    int? id,
    String? type,
    al.AnilistMediaType? mediaType,
  }) async {
    final req = al.AnilistExternalLinkRequest(client: _client);
    return req.fetch(id: id, type: type, mediaType: mediaType);
  }

  Future<String> parseMarkdown(String markdown) async {
    final req = al.AnilistMarkdownRequest(client: _client);
    return req.parse(markdown);
  }

  // ============================================================
  // INTERNAL HELPERS
  // ============================================================

  Future<void> _saveMediaToDb(al.AnilistMedia? media) async {
    if (media == null) return;
    try {
      final isarMedia = _convertToIsarMedia(media);
      await _db.saveAnilistMedia(isarMedia);
    } catch (_) {}
  }

  IsarAnilistMedia _convertToIsarMedia(al.AnilistMedia m) {
    final im = IsarAnilistMedia()
      ..anilistId = m.id
      ..idMal = m.idMal
      ..titleRomaji = m.title?.romaji ?? ''
      ..title = (IsarAnilistTitle()
        ..romaji = m.title?.romaji
        ..english = m.title?.english
        ..native = m.title?.native)
      ..coverImage = (IsarAnilistCoverImage()
        ..large = m.coverImage?.large
        ..extraLarge = m.coverImage?.extraLarge
        ..medium = m.coverImage?.medium
        ..color = m.coverImage?.color)
      ..type = m.type == al.AnilistMediaType.ANIME ? AnilistMediaType.ANIME : AnilistMediaType.MANGA
      ..contentType = m.type == al.AnilistMediaType.ANIME ? AnilistMediaType.ANIME : AnilistMediaType.MANGA
      ..format = _mapFormat(m.format)
      ..status = _mapStatus(m.status)
      ..description = m.description
      ..genres = (m.genres?.toList() ?? []).cast<String>()
      ..averageScore = m.averageScore
      ..meanScore = m.meanScore
      ..popularity = m.popularity
      ..favourites = m.favourites
      ..trending = m.trending
      ..episodes = m.episodes
      ..chapters = m.chapters
      ..volumes = m.volumes
      ..seasonYear = m.seasonYear
      ..season = _mapSeason(m.season)
      ..bannerImage = m.bannerImage
      ..countryOfOrigin = m.countryOfOrigin
      ..source = _mapSource(m.source)
      ..isLicensed = m.isLicensed
      ..updatedAt = m.updatedAt
      ..lastSyncedAt = DateTime.now();

    if (m.tags != null) {
      im.tags = m.tags!
          .map((t) => IsarAnilistTag()
            ..anilistId = t.id ?? 0
            ..name = t.name
            ..description = t.description
            ..category = t.category
            ..rank = t.rank
            ..isAdult = t.isAdult
            ..isGeneralSpoiler = t.isGeneralSpoiler
            ..isMediaSpoiler = t.isMediaSpoiler)
          .toList();
    }
    return im;
  }

  AnilistMediaFormat _mapFormat(al.AnilistMediaFormat? f) {
    if (f == null) return AnilistMediaFormat.TV;
    return AnilistMediaFormat.values.firstWhere(
      (e) => e.toString().split('.').last == f.toString().split('.').last,
      orElse: () => AnilistMediaFormat.TV,
    );
  }

  AnilistMediaStatus _mapStatus(al.AnilistMediaStatus? s) {
    if (s == null) return AnilistMediaStatus.FINISHED;
    return AnilistMediaStatus.values.firstWhere(
      (e) => e.toString().split('.').last == s.toString().split('.').last,
      orElse: () => AnilistMediaStatus.FINISHED,
    );
  }

  AnilistMediaSource _mapSource(al.AnilistMediaSource? s) {
    if (s == null) return AnilistMediaSource.ORIGINAL;
    return AnilistMediaSource.values.firstWhere(
      (e) => e.toString().split('.').last == s.toString().split('.').last,
      orElse: () => AnilistMediaSource.ORIGINAL,
    );
  }

  AnilistMediaSeason _mapSeason(al.AnilistMediaSeason? s) {
    if (s == null) return AnilistMediaSeason.WINTER;
    return AnilistMediaSeason.values.firstWhere(
      (e) => e.toString().split('.').last == s.toString().split('.').last,
      orElse: () => AnilistMediaSeason.WINTER,
    );
  }
}
