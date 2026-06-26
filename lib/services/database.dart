import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:omiku/models/models.dart';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class DatabaseService with ChangeNotifier {
  // Singleton pattern so you don't accidentally open multiple instances
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  // ... rest of your code stays exactly the same
  late Isar _isar;
  late Isar isar;

  /// Call this in your main.dart BEFORE runApp()
  Future<void> init() async {
    debugPrint('[DatabaseService] Initializing Isar database...');
    final dir = await getApplicationDocumentsDirectory();
    debugPrint(
      '[DatabaseService] Application documents directory: ${dir.path}',
    );

    _isar = await Isar.open(
      [
        PlayableFileSchema,
        SeriesSchema,
        SeasonSchema,
        EpisodeSchema,
        MovieSchema,
        PersonSchema,
        MangaSeriesSchema,
        MangaChapterSchema,
        ChapterPageSchema,
        LibraryConfigSchema,
        LocalMovieSchema,
        LocalMovieItemSchema,
        LocalTvSeriesSchema,
        LocalTvSeasonSchema,
        LocalTvEpisodeSchema,
        IsarAnilistMediaSchema,
        IsarAnilistTagSchema,
        IsarAnilistCharacterSchema,
        IsarAnilistStaffSchema,
        IsarAnilistUserSchema,
        IsarAnilistMediaListSchema,
        IsarAnilistStudioSchema,
        IsarAnilistReviewSchema,
        IsarAnilistRecommendationSchema,
        IsarAnilistNotificationSchema,
      ],
      directory: dir.path,
      inspector:
          true, // Enables a web browser UI to look inside your DB during debug mode!
    );
    isar = _isar;
    debugPrint('[DatabaseService] Isar database successfully opened.');
  }

  Future<bool> requestAllFilesAccess() async {
    var status = await Permission.manageExternalStorage.status;

    if (status.isGranted) {
      debugPrint('[DatabaseService] All Files Access is already granted.');
      return true;
    }

    status = await Permission.manageExternalStorage.request();

    if (status.isGranted) {
      debugPrint('[DatabaseService] All Files Access granted by user.');
      return true;
    } else {
      debugPrint('[DatabaseService] All Files Access denied by user.');
      return false;
    }
  }

  // ==========================================
  // GENERIC EASY MANAGEMENT METHODS (CRUD)
  // ==========================================

  /// Insert or Update a single item
  Future<void> put<T>(T item) async {
    debugPrint('[DatabaseService] put() called for item type: $T');
    await _isar.writeTxn(() async {
      if (item is PlayableFile) await _isar.playableFiles.put(item);
      if (item is Series) await _isar.series.put(item);
      if (item is Season) await _isar.seasons.put(item);
      if (item is Episode) await _isar.episodes.put(item);
      if (item is Movie) await _isar.movies.put(item);
      if (item is Person) await _isar.persons.put(item);
      if (item is MangaChapter) await _isar.mangaChapters.put(item);
      if (item is MangaSeries) await _isar.mangaSeries.put(item);
      if (item is ChapterPage) await _isar.chapterPages.put(item);
      if (item is LibraryConfig) await _isar.libraryConfigs.put(item);
      if (item is LocalMovie) await _isar.localMovies.put(item);
      if (item is LocalMovieItem) await _isar.localMovieItems.put(item);
      if (item is LocalTvSeries) await _isar.localTvSeries.put(item);
      if (item is LocalTvSeason) await _isar.localTvSeasons.put(item);
      if (item is LocalTvEpisode) await _isar.localTvEpisodes.put(item);
      if (item is IsarAnilistMedia) await _isar.isarAnilistMedias.put(item);
      if (item is IsarAnilistTag) await _isar.isarAnilistTags.put(item);
      if (item is IsarAnilistCharacter)
        await _isar.isarAnilistCharacters.put(item);
      if (item is IsarAnilistStaff) await _isar.isarAnilistStaffs.put(item);
      if (item is IsarAnilistUser) await _isar.isarAnilistUsers.put(item);
      if (item is IsarAnilistMediaList)
        await _isar.isarAnilistMediaLists.put(item);
      if (item is IsarAnilistStudio) await _isar.isarAnilistStudios.put(item);
      if (item is IsarAnilistReview) await _isar.isarAnilistReviews.put(item);
      if (item is IsarAnilistRecommendation)
        await _isar.isarAnilistRecommendations.put(item);
      if (item is IsarAnilistNotification)
        await _isar.isarAnilistNotifications.put(item);
    });
    debugPrint('[DatabaseService] put() completed for item type: $T');
  }

  /// Bulk Insert or Update (Crucial for performance with 10,000+ items)
  Future<void> putAll<T>(List<T> items) async {
    debugPrint(
      '[DatabaseService] putAll() called with ${items.length} items of type: $T',
    );
    await _isar.writeTxn(() async {
      if (items is List<PlayableFile>) {
        await _isar.playableFiles.putAll(items as List<PlayableFile>);
      }
      if (items is List<Series>) {
        await _isar.series.putAll(items as List<Series>);
      }
      if (items is List<Season>) {
        await _isar.seasons.putAll(items as List<Season>);
      }
      if (items is List<Episode>) {
        await _isar.episodes.putAll(items as List<Episode>);
      }
      if (items is List<Movie>) await _isar.movies.putAll(items as List<Movie>);
      if (items is List<Person>) {
        await _isar.persons.putAll(items as List<Person>);
      }
      if (items is List<MangaSeries>) {
        await _isar.mangaSeries.putAll(items as List<MangaSeries>);
      }
      if (items is List<MangaChapter>) {
        await _isar.mangaChapters.putAll(items as List<MangaChapter>);
      }
      if (items is List<ChapterPage>) {
        await _isar.chapterPages.putAll(items as List<ChapterPage>);
      }
      if (items is List<LibraryConfig>) {
        await _isar.libraryConfigs.putAll(items as List<LibraryConfig>);
      }
      if (items is List<LocalMovie>) {
        await _isar.localMovies.putAll(items as List<LocalMovie>);
      }
      if (items is List<LocalMovieItem>) {
        await _isar.localMovieItems.putAll(items as List<LocalMovieItem>);
      }
      if (items is List<LocalTvSeries>) {
        await _isar.localTvSeries.putAll(items as List<LocalTvSeries>);
      }
      if (items is List<LocalTvSeason>) {
        await _isar.localTvSeasons.putAll(items as List<LocalTvSeason>);
      }
      if (items is List<LocalTvEpisode>) {
        await _isar.localTvEpisodes.putAll(items as List<LocalTvEpisode>);
      }
      if (items is List<IsarAnilistMedia>) {
        await _isar.isarAnilistMedias.putAll(items as List<IsarAnilistMedia>);
      }
      if (items is List<IsarAnilistTag>) {
        await _isar.isarAnilistTags.putAll(items as List<IsarAnilistTag>);
      }
      if (items is List<IsarAnilistCharacter>) {
        await _isar.isarAnilistCharacters.putAll(
          items as List<IsarAnilistCharacter>,
        );
      }
      if (items is List<IsarAnilistStaff>) {
        await _isar.isarAnilistStaffs.putAll(items as List<IsarAnilistStaff>);
      }
      if (items is List<IsarAnilistUser>) {
        await _isar.isarAnilistUsers.putAll(items as List<IsarAnilistUser>);
      }
      if (items is List<IsarAnilistMediaList>) {
        await _isar.isarAnilistMediaLists.putAll(
          items as List<IsarAnilistMediaList>,
        );
      }
      if (items is List<IsarAnilistStudio>) {
        await _isar.isarAnilistStudios.putAll(items as List<IsarAnilistStudio>);
      }
      if (items is List<IsarAnilistReview>) {
        await _isar.isarAnilistReviews.putAll(items as List<IsarAnilistReview>);
      }
      if (items is List<IsarAnilistRecommendation>) {
        await _isar.isarAnilistRecommendations.putAll(
          items as List<IsarAnilistRecommendation>,
        );
      }
      if (items is List<IsarAnilistNotification>) {
        await _isar.isarAnilistNotifications.putAll(
          items as List<IsarAnilistNotification>,
        );
      }
    });
    debugPrint('[DatabaseService] putAll() completed for items of type: $T');
  }

  /// Get an item by its internal Isar autoIncrement ID
  Future<T?> get<T>(Id id) async {
    debugPrint('[DatabaseService] get() requested for type $T with ID: $id');
    T? result;
    if (T == PlayableFile) result = await _isar.playableFiles.get(id) as T?;
    if (T == Series) result = await _isar.series.get(id) as T?;
    if (T == Season) result = await _isar.seasons.get(id) as T?;
    if (T == Episode) result = await _isar.episodes.get(id) as T?;
    if (T == Movie) result = await _isar.movies.get(id) as T?;
    if (T == Person) result = await _isar.persons.get(id) as T?;
    if (T == MangaSeries) result = await _isar.mangaSeries.get(id) as T?;
    if (T == MangaChapter) result = await _isar.mangaChapters.get(id) as T?;
    if (T == ChapterPage) result = await _isar.chapterPages.get(id) as T?;
    if (T == LibraryConfig) result = await _isar.libraryConfigs.get(id) as T?;
    if (T == LocalMovie) result = await _isar.localMovies.get(id) as T?;
    if (T == LocalMovieItem) result = await _isar.localMovieItems.get(id) as T?;
    if (T == LocalTvSeries) result = await _isar.localTvSeries.get(id) as T?;
    if (T == LocalTvSeason) result = await _isar.localTvSeasons.get(id) as T?;
    if (T == LocalTvEpisode) result = await _isar.localTvEpisodes.get(id) as T?;
    if (T == IsarAnilistMedia)
      result = await _isar.isarAnilistMedias.get(id) as T?;
    if (T == IsarAnilistTag) result = await _isar.isarAnilistTags.get(id) as T?;
    if (T == IsarAnilistCharacter)
      result = await _isar.isarAnilistCharacters.get(id) as T?;
    if (T == IsarAnilistStaff)
      result = await _isar.isarAnilistStaffs.get(id) as T?;
    if (T == IsarAnilistUser)
      result = await _isar.isarAnilistUsers.get(id) as T?;
    if (T == IsarAnilistMediaList)
      result = await _isar.isarAnilistMediaLists.get(id) as T?;
    if (T == IsarAnilistStudio)
      result = await _isar.isarAnilistStudios.get(id) as T?;
    if (T == IsarAnilistReview)
      result = await _isar.isarAnilistReviews.get(id) as T?;
    if (T == IsarAnilistRecommendation)
      result = await _isar.isarAnilistRecommendations.get(id) as T?;
    if (T == IsarAnilistNotification)
      result = await _isar.isarAnilistNotifications.get(id) as T?;

    debugPrint(
      '[DatabaseService] get() result for type $T (ID: $id) found: ${result != null}',
    );
    return result;
  }

  /// Get everything from a collection
  Future<List<T>> getAll<T>() async {
    debugPrint('[DatabaseService] getAll() requested for collection type: $T');
    List<T>? results;
    if (T == PlayableFile)
      results = await _isar.playableFiles.where().findAll() as List<T>;
    if (T == Series) results = await _isar.series.where().findAll() as List<T>;
    if (T == Season) results = await _isar.seasons.where().findAll() as List<T>;
    if (T == Episode)
      results = await _isar.episodes.where().findAll() as List<T>;
    if (T == Movie) results = await _isar.movies.where().findAll() as List<T>;
    if (T == Person) results = await _isar.persons.where().findAll() as List<T>;
    if (T == MangaSeries)
      results = await _isar.mangaSeries.where().findAll() as List<T>;
    if (T == MangaChapter)
      results = await _isar.mangaChapters.where().findAll() as List<T>;
    if (T == ChapterPage)
      results = await _isar.chapterPages.where().findAll() as List<T>;
    if (T == LibraryConfig)
      results = await _isar.libraryConfigs.where().findAll() as List<T>;
    if (T == LocalMovie)
      results = await _isar.localMovies.where().findAll() as List<T>;
    if (T == LocalMovieItem)
      results = await _isar.localMovieItems.where().findAll() as List<T>;
    if (T == LocalTvSeries)
      results = await _isar.localTvSeries.where().findAll() as List<T>;
    if (T == LocalTvSeason)
      results = await _isar.localTvSeasons.where().findAll() as List<T>;
    if (T == LocalTvEpisode)
      results = await _isar.localTvEpisodes.where().findAll() as List<T>;
    if (T == IsarAnilistMedia)
      results = await _isar.isarAnilistMedias.where().findAll() as List<T>;
    if (T == IsarAnilistTag)
      results = await _isar.isarAnilistTags.where().findAll() as List<T>;
    if (T == IsarAnilistCharacter)
      results = await _isar.isarAnilistCharacters.where().findAll() as List<T>;
    if (T == IsarAnilistStaff)
      results = await _isar.isarAnilistStaffs.where().findAll() as List<T>;
    if (T == IsarAnilistUser)
      results = await _isar.isarAnilistUsers.where().findAll() as List<T>;
    if (T == IsarAnilistMediaList)
      results = await _isar.isarAnilistMediaLists.where().findAll() as List<T>;
    if (T == IsarAnilistStudio)
      results = await _isar.isarAnilistStudios.where().findAll() as List<T>;
    if (T == IsarAnilistReview)
      results = await _isar.isarAnilistReviews.where().findAll() as List<T>;
    if (T == IsarAnilistRecommendation)
      results =
          await _isar.isarAnilistRecommendations.where().findAll() as List<T>;
    if (T == IsarAnilistNotification)
      results =
          await _isar.isarAnilistNotifications.where().findAll() as List<T>;

    results ??= [];
    debugPrint(
      '[DatabaseService] getAll() for type $T returned ${results.length} records.',
    );
    return results;
  }

  /// Delete an item by its Isar ID
  Future<bool> delete<T>(Id id) async {
    debugPrint(
      '[DatabaseService] delete() called for collection type $T with ID: $id',
    );
    final success = await _isar.writeTxn(() async {
      if (T == PlayableFile) return await _isar.playableFiles.delete(id);
      if (T == Series) return await _isar.series.delete(id);
      if (T == Season) return await _isar.seasons.delete(id);
      if (T == Episode) return await _isar.episodes.delete(id);
      if (T == Movie) return await _isar.movies.delete(id);
      if (T == Person) return await _isar.persons.delete(id);
      if (T == MangaSeries) return await _isar.mangaSeries.delete(id);
      if (T == MangaChapter) return await _isar.mangaChapters.delete(id);
      if (T == ChapterPage) return await _isar.chapterPages.delete(id);
      if (T == LibraryConfig) return await _isar.libraryConfigs.delete(id);
      if (T == LocalMovie) return await _isar.localMovies.delete(id);
      if (T == LocalMovieItem) return await _isar.localMovieItems.delete(id);
      if (T == LocalTvSeries) return await _isar.localTvSeries.delete(id);
      if (T == LocalTvSeason) return await _isar.localTvSeasons.delete(id);
      if (T == LocalTvEpisode) return await _isar.localTvEpisodes.delete(id);
      if (T == IsarAnilistMedia)
        return await _isar.isarAnilistMedias.delete(id);
      if (T == IsarAnilistTag) return await _isar.isarAnilistTags.delete(id);
      if (T == IsarAnilistCharacter)
        return await _isar.isarAnilistCharacters.delete(id);
      if (T == IsarAnilistStaff)
        return await _isar.isarAnilistStaffs.delete(id);
      if (T == IsarAnilistUser) return await _isar.isarAnilistUsers.delete(id);
      if (T == IsarAnilistMediaList)
        return await _isar.isarAnilistMediaLists.delete(id);
      if (T == IsarAnilistStudio)
        return await _isar.isarAnilistStudios.delete(id);
      if (T == IsarAnilistReview)
        return await _isar.isarAnilistReviews.delete(id);
      if (T == IsarAnilistRecommendation)
        return await _isar.isarAnilistRecommendations.delete(id);
      if (T == IsarAnilistNotification)
        return await _isar.isarAnilistNotifications.delete(id);

      return false;
    });
    debugPrint(
      '[DatabaseService] delete() for type $T, ID: $id status: $success',
    );
    return success;
  }

  /// Clear the entire database completely
  Future<void> clearDatabase() async {
    debugPrint(
      '[DatabaseService] WARNING: clearDatabase() called! Wiping entire Isar DB.',
    );
    await _isar.writeTxn(() => _isar.clear());
    debugPrint('[DatabaseService] Database cleared successfully.');
  }

  // ==========================================
  // RELATIONAL CUSTOM QUERIES
  // ==========================================

  // // 1. Get an individual MangaPanel by its business string UUID
  // Future<MangaPanel?> getPanelById(String panelId) async {
  //   debugPrint('[MangaQuery] getPanelById() searching for Panel ID: $panelId');
  //   final panel = await _isar.mangaPanels.where().panelIdEqualTo(panelId).findFirst();
  //   debugPrint('[MangaQuery] getPanelById() found match: ${panel != null}');
  //   return panel;
  // }

  // // 2. Get all Panels belonging to a ChapterPage sorted by panel sequence position
  // Future<List<MangaPanel>> getPanelsForPage(String pageId) async {
  //   debugPrint('[MangaQuery] getPanelsForPage() fetching panels for Page ID: $pageId');
  //   final panels = await _isar.mangaPanels.where().pageIdEqualTo(pageId).findAll();
  //   debugPrint('[MangaQuery] getPanelsForPage() retrieved ${panels.length} panels for Page ID: $pageId');
  //   return panels;
  // }

  // // 3. Bulk Save Panels for ChapterPage with explicit backlink creation
  // Future<void> savePanelsForPage(ChapterPage page, List<MangaPanel> panels) async {
  //   debugPrint('[MangaQuery] savePanelsForPage() saving ${panels.length} panels for Page ID: ${page.pageId}');
  //   await _isar.writeTxn(() async {
  //     await _isar.chapterPages.put(page);

  //     for (final panel in panels) {
  //       panel.pageLink.value = page;
  //     }

  //     await _isar.mangaPanels.putAll(panels);

  //     for (final panel in panels) {
  //       await panel.pageLink.save();
  //     }
  //   });
  //   debugPrint('[MangaQuery] savePanelsForPage() completed successfully.');
  // }

  // // 4. Get the Next Panel in row sequence matching current page parameters
  // Future<MangaPanel?> getNextPanel(String pageId, int currentPanelNumber) async {
  //   debugPrint('[MangaQuery] getNextPanel() looking for panel after index $currentPanelNumber on Page ID: $pageId');
  //   return await _isar.mangaPanels
  //       .where()
  //       .pageIdEqualTo(pageId)
  //       .filter()
  //       .panelNumberEqualTo(currentPanelNumber + 1)
  //       .findFirst();
  // }

  // // 5. Get the Last (Previous) Panel in sequence row matching current page parameters
  // Future<MangaPanel?> getPreviousPanel(String pageId, int currentPanelNumber) async {
  //   if (currentPanelNumber <= 0) {
  //     debugPrint('[MangaQuery] getPreviousPanel() aborted, current panel number <= 0.');
  //     return null;
  //   }
  //   debugPrint('[MangaQuery] getPreviousPanel() looking for panel before index $currentPanelNumber on Page ID: $pageId');
  //   return await _isar.mangaPanels
  //       .where()
  //       .pageIdEqualTo(pageId)
  //       .filter()
  //       .panelNumberEqualTo(currentPanelNumber - 1)
  //       .findFirst();
  // }

  // // 6. Get the sequential panel tracking number/index for a specific Panel row
  // Future<int> getPanelIndex(String panelId) async {
  //   debugPrint('[MangaQuery] getPanelIndex() calculating index for Panel ID: $panelId');
  //   final panel = await getPanelById(panelId);
  //   debugPrint('[MangaQuery] getPanelIndex() resolved panel number: ${panel?.panelNumber}');
  //   return panel?.panelNumber ?? 0;
  // }

  // // 7. Get panel by utilizing precise sequence position parameters directly
  // Future<MangaPanel?> getPanelBySequenceIndex(String pageId, int panelIndex) async {
  //   debugPrint('[MangaQuery] getPanelBySequenceIndex() looking up sequence $panelIndex on Page ID: $pageId');
  //   return await _isar.mangaPanels
  //       .where()
  //       .pageIdEqualTo(pageId)
  //       .filter()
  //       .panelNumberEqualTo(panelIndex)
  //       .findFirst();
  // }

  /// Find all episodes belonging to a specific season (Fast Indexed Query)
  Future<List<Episode>> getEpisodesBySeason(String seasonId) async {
    debugPrint(
      '[VideoQuery] getEpisodesBySeason() called for Season ID: $seasonId',
    );
    final episodes = await _isar.episodes
        .where()
        .seasonIdEqualTo(seasonId)
        .findAll();
    debugPrint(
      '[VideoQuery] getEpisodesBySeason() found ${episodes.length} episodes.',
    );
    return episodes;
  }

  Future<void> saveSeriesWithSeasons(
    Series series,
    List<Season> seasons,
  ) async {
    debugPrint(
      '[VideoQuery] saveSeriesWithSeasons() saving Series ID: ${series.seriesId} with ${seasons.length} seasons.',
    );
    final linkedSeasons = seasons.map((season) {
      return season..seriesId = series.seriesId;
    }).toList();

    await _isar.writeTxn(() async {
      await _isar.series.put(series);
      await _isar.seasons.putAll(linkedSeasons);
    });
    debugPrint(
      '[VideoQuery] saveSeriesWithSeasons() cascading write finalized.',
    );
  }

  Future<Person?> getPersonByTmdbId(String tmdbId) async {
    debugPrint(
      '[VideoQuery] getPersonByTmdbId() searching Person TMDB ID: $tmdbId',
    );
    return await _isar.persons.where().tmdbPersonIdEqualTo(tmdbId).findFirst();
  }

  /// Fetch all Seasons belonging to a specific Series
  Future<List<Season>> getSeasonsForSeries(String seriesId) async {
    debugPrint(
      '[VideoQuery] getSeasonsForSeries() fetching seasons for Series ID: $seriesId',
    );
    final seasons = await _isar.seasons
        .where()
        .seriesIdEqualTo(seriesId)
        .findAll();
    debugPrint(
      '[VideoQuery] getSeasonsForSeries() found ${seasons.length} seasons.',
    );
    return seasons;
  }

  Future<void> saveSeasonWithEpisodes(
    Season season,
    List<Episode> episodes,
  ) async {
    debugPrint(
      '[VideoQuery] saveSeasonWithEpisodes() called for Season ID: ${season.seasonId}',
    );
    final linkedEpisodes = episodes.map((episode) {
      return episode
        ..seasonId = season.seasonId
        ..seriesId = season.seriesId;
    }).toList();

    await _isar.writeTxn(() async {
      await _isar.seasons.put(season);
      await _isar.episodes.putAll(linkedEpisodes);
    });
    debugPrint(
      '[VideoQuery] saveSeasonWithEpisodes() completed committing season and episodes.',
    );
  }

  /// Fetch all Episodes belonging to a specific Season, sorted by their order
  Future<List<Episode>> getEpisodesForSeason(String seasonId) async {
    debugPrint(
      '[VideoQuery] getEpisodesForSeason() fetching sorted episodes for Season ID: $seasonId',
    );
    return await _isar.episodes
        .where()
        .seasonIdEqualTo(seasonId)
        .sortByEpisodeIndex()
        .findAll();
  }

  Future<Map<Season, List<Episode>>> getFullSeriesTree(String seriesId) async {
    debugPrint(
      '[VideoQuery] getFullSeriesTree() assembling tree for Series ID: $seriesId',
    );
    final seasons = await getSeasonsForSeries(seriesId);
    final Map<Season, List<Episode>> seriesTree = {};

    for (final season in seasons) {
      if (season.seasonId != null) {
        final episodes = await getEpisodesForSeason(season.seasonId!);
        seriesTree[season] = episodes;
      }
    }
    debugPrint('[VideoQuery] getFullSeriesTree() tree successfully assembled.');
    return seriesTree;
  }

  /// Reactive Stream: Listen to changes in your files list in Realtime!
  Stream<List<PlayableFile>> watchPlayableFiles() {
    debugPrint('[Stream] watchPlayableFiles() stream opened.');
    return _isar.playableFiles.where().watch();
  }

  /// Full-text search for Manga series by Title or Author (Case-Insensitive)
  Future<List<MangaSeries>> searchManga(String query) async {
    if (query.isEmpty) {
      debugPrint(
        '[MangaQuery] searchManga query is empty. Returning empty list.',
      );
      return [];
    }
    debugPrint('[MangaQuery] searchManga searching for term: $query');
    return await _isar.mangaSeries
        .where()
        .titleBetween(
          query.toUpperCase(),
          query.toLowerCase(),
          includeLower: true,
          includeUpper: true,
        )
        .or()
        .authorBetween(
          query.toUpperCase(),
          query.toLowerCase(),
          includeLower: true,
          includeUpper: true,
        )
        .findAll();
  }

  // 1. Get MangaSeries by series ID
  Future<MangaSeries?> getMangaSeriesById(String seriesId) async {
    debugPrint(
      '[MangaQuery] getMangaSeriesById() looking up Manga Series ID: $seriesId',
    );
    return await _isar.mangaSeries
        .where()
        .seriesIdEqualTo(seriesId)
        .findFirst();
  }

  // 2. Get Pages for a Chapter (sorted by natural page order)
  Future<List<ChapterPage>> getPagesForChapter(String chapterId) async {
    debugPrint(
      '[MangaQuery] getPagesForChapter() fetching sorted pages for Chapter ID: $chapterId',
    );
    return await _isar.chapterPages
        .where()
        .chapterIdEqualTo(chapterId)
        .sortByPageNumber()
        .findAll();
  }

  // 3. Get Chapter for a Page
  Future<MangaChapter?> getChapterForPage(ChapterPage page) async {
    if (page.chapterLink.isAttached) {
      debugPrint(
        '[MangaQuery] getChapterForPage() chapter link attached, loading...',
      );
      await page.chapterLink.load();
      if (page.chapterLink.value != null) return page.chapterLink.value;
    }
    debugPrint(
      '[MangaQuery] getChapterForPage() falling back to query by Chapter ID: ${page.chapterId}',
    );
    return await _isar.mangaChapters
        .where()
        .chapterIdEqualTo(page.chapterId)
        .findFirst();
  }

  // 4. Get Page by ChapterPage ID
  Future<ChapterPage?> getPageById(String pageId) async {
    debugPrint('[MangaQuery] getPageById() fetching Page ID: $pageId');
    return await _isar.chapterPages.where().pageIdEqualTo(pageId).findFirst();
  }

  // 5. Get Chapter by Chapter ID
  Future<MangaChapter?> getChapterById(String chapterId) async {
    debugPrint('[MangaQuery] getChapterById() fetching Chapter ID: $chapterId');
    return await _isar.mangaChapters
        .where()
        .chapterIdEqualTo(chapterId)
        .findFirst();
  }

  // 6. Get Page by sequence Index within a specific Chapter
  Future<ChapterPage?> getPageByIndex(String chapterId, int pageIndex) async {
    debugPrint(
      '[MangaQuery] getPageByIndex() fetching index $pageIndex for Chapter ID: $chapterId',
    );
    return await _isar.chapterPages
        .where()
        .chapterIdEqualTo(chapterId)
        .filter()
        .pageNumberEqualTo(pageIndex)
        .findFirst();
  }

  // 7. Bulk Save Pages for Chapter (with safe linking structure)
  Future<void> savePagesForChapter(
    MangaChapter chapter,
    List<ChapterPage> pages,
  ) async {
    debugPrint(
      '[MangaQuery] savePagesForChapter() saving ${pages.length} pages for Chapter ID: ${chapter.chapterId}',
    );
    await _isar.writeTxn(() async {
      await _isar.mangaChapters.put(chapter);

      for (final page in pages) {
        page.chapterLink.value = chapter;
      }

      await _isar.chapterPages.putAll(pages);

      for (final page in pages) {
        await page.chapterLink.save();
      }
    });
    debugPrint('[MangaQuery] savePagesForChapter() operation completed.');
  }

  // 8. Next Page in Chapter
  Future<ChapterPage?> getNextPageInChapter(
    String chapterId,
    int currentPageNumber,
  ) async {
    debugPrint(
      '[MangaQuery] getNextPageInChapter() fetching page after index $currentPageNumber for Chapter ID: $chapterId',
    );
    return await _isar.chapterPages
        .where()
        .chapterIdEqualTo(chapterId)
        .filter()
        .pageNumberEqualTo(currentPageNumber + 1)
        .findFirst();
  }

  // 9. Last (Previous) Page in Chapter
  Future<ChapterPage?> getPreviousPageInChapter(
    String chapterId,
    int currentPageNumber,
  ) async {
    if (currentPageNumber <= 0) return null;
    debugPrint(
      '[MangaQuery] getPreviousPageInChapter() fetching page before index $currentPageNumber for Chapter ID: $chapterId',
    );
    return await _isar.chapterPages
        .where()
        .chapterIdEqualTo(chapterId)
        .filter()
        .pageNumberEqualTo(currentPageNumber - 1)
        .findFirst();
  }

  // 10. Next Chapter in Manga Series
  Future<MangaChapter?> getNextChapter(
    String seriesId,
    double currentChapterNumber,
  ) async {
    debugPrint(
      '[MangaQuery] getNextChapter() fetching next chapter after $currentChapterNumber for Series ID: $seriesId',
    );
    return await _isar.mangaChapters
        .where()
        .seriesIdEqualTo(seriesId)
        .filter()
        .chapterNumberGreaterThan(currentChapterNumber)
        .sortByChapterNumber()
        .findFirst();
  }

  // 11. Last (Previous) Chapter in Manga Series
  Future<MangaChapter?> getPreviousChapter(
    String seriesId,
    double currentChapterNumber,
  ) async {
    debugPrint(
      '[MangaQuery] getPreviousChapter() fetching previous chapter before $currentChapterNumber for Series ID: $seriesId',
    );
    return await _isar.mangaChapters
        .where()
        .seriesIdEqualTo(seriesId)
        .filter()
        .chapterNumberLessThan(currentChapterNumber)
        .sortByChapterNumberDesc()
        .findFirst();
  }

  /// Cascading Save: Saves a Manga Series along with its Chapters
  Future<void> saveMangaWithChapters(
    MangaSeries series,
    List<MangaChapter> chapters,
  ) async {
    debugPrint(
      '[MangaQuery] saveMangaWithChapters() cascading save initiated for Series ID: ${series.seriesId}',
    );
    await _isar.writeTxn(() async {
      await _isar.mangaSeries.put(series);

      for (final chapter in chapters) {
        chapter.seriesLink.value = series;
      }

      await _isar.mangaChapters.putAll(chapters);

      for (final chapter in chapters) {
        await chapter.seriesLink.save();
      }
    });
    debugPrint(
      '[MangaQuery] saveMangaWithChapters() cascading save completed.',
    );
  }

  /// Fetch all chapters for a specific Manga series safely via links
  Future<List<MangaChapter>> getChaptersForSeries(String seriesId) async {
    debugPrint(
      '[MangaQuery] getChaptersForSeries() getting chapters using Isar links for Series ID: $seriesId',
    );
    final series = await getMangaSeriesById(seriesId);
    if (series == null) {
      debugPrint(
        '[MangaQuery] getChaptersForSeries() series not found, returning empty.',
      );
      return [];
    }

    return await series.chapters.filter().sortByChapterNumber().findAll();
  }

  /// Cascading Save: Saves a Chapter along with all its structural Pages
  Future<void> saveChapterWithPages(
    MangaChapter chapter,
    List<ChapterPage> pages,
  ) async {
    debugPrint(
      '[MangaQuery] saveChapterWithPages() saving chapter/pages transaction for Chapter ID: ${chapter.chapterId}',
    );
    await _isar.writeTxn(() async {
      await _isar.mangaChapters.put(chapter);

      for (final page in pages) {
        page.chapterLink.value = chapter;
      }

      await _isar.chapterPages.putAll(pages);

      for (final page in pages) {
        await page.chapterLink.save();
      }
    });
    debugPrint('[MangaQuery] saveChapterWithPages() transaction completed.');
  }

  /// Updates user progress (last read timestamp, coordinates, or reading layout indexes)
  Future<void> updateMangaProgress(
    String seriesId,
    IsarUserProgress updatedProgress,
  ) async {
    debugPrint(
      '[MangaQuery] updateMangaProgress() updating reading dashboard status for Series ID: $seriesId',
    );
    final series = await getMangaSeriesById(seriesId);
    if (series != null) {
      series.progress = updatedProgress;
      await _isar.writeTxn(() async {
        await _isar.mangaSeries.put(series);
      });
      debugPrint(
        '[MangaQuery] updateMangaProgress() progress committed successfully.',
      );
    } else {
      debugPrint(
        '[MangaQuery] updateMangaProgress() failed, Series ID $seriesId not found.',
      );
    }
  }

  Future<List<MangaSeries>> getMangaLibraryWithChapters() async {
    debugPrint(
      '[MangaQuery] getMangaLibraryWithChapters() loading entire library trees.',
    );
    final seriesList = await _isar.mangaSeries.where().findAll();

    for (final series in seriesList) {
      if (series.chapters.isAttached) {
        await series.chapters.load();
      } else {
        await getChaptersForSeries(series.seriesId);
      }
    }
    debugPrint(
      '[MangaQuery] getMangaLibraryWithChapters() loaded ${seriesList.length} series.',
    );
    return seriesList;
  }

  /// Reactive Stream: Real-time hook to listen to updates across all Manga Series
  Stream<List<MangaSeries>> watchMangaLibrary() {
    debugPrint('[Stream] watchMangaLibrary() stream subscribed.');
    return _isar.mangaSeries.where().watch();
  }

  Future<Movie?> getMovieByTmdbId(String tmdbId) async {
    debugPrint(
      '[VideoQuery] getMovieByTmdbId() fetching Movie TMDB ID: $tmdbId',
    );
    return await _isar.movies.where().tmdbIdEqualTo(tmdbId).findFirst();
  }

  /// Look up a Series from the local cache using its TMDB string ID
  Future<Series?> getSeriesByTmdbId(String tmdbId) async {
    debugPrint(
      '[VideoQuery] getSeriesByTmdbId() fetching Series TMDB ID: $tmdbId',
    );
    return await _isar.series.where().tmdbIdEqualTo(tmdbId).findFirst();
  }
  // ==========================================
  // TEXT & SMART FALLBACK SEARCH HELPERS
  // ==========================================

  // ==========================================
  // TEXT & SMART FALLBACK SEARCH HELPERS
  // ==========================================

  /// Search Series by a title string (Case-Insensitive lookup)
  Future<List<Series>> searchSeriesByTitle(String query) async {
    if (query.trim().isEmpty) return [];
    debugPrint('[VideoQuery] searchSeriesByTitle: $query');
    return await _isar.series
        .filter()
        .titleContains(query, caseSensitive: false)
        .findAll();
  }

  /// Search Movies by a title string (Case-Insensitive lookup)
  Future<List<Movie>> searchMoviesByTitle(String query) async {
    if (query.trim().isEmpty) return [];
    debugPrint('[VideoQuery] searchMoviesByTitle: $query');
    return await _isar.movies
        .filter()
        .titleContains(query, caseSensitive: false)
        .findAll();
  }

  /// Search Manga by Title string (Case-Insensitive lookup)
  Future<List<MangaSeries>> searchMangaByTitle(String query) async {
    if (query.trim().isEmpty) return [];
    debugPrint('[MangaQuery] searchMangaByTitle: $query');
    return await _isar.mangaSeries
        .filter()
        .titleContains(query, caseSensitive: false)
        .findAll();
  }

  /// The Super Helper: Dynamic fallback search across multiple media types
  /// Returns a Map categorized by entity lists.
  Future<Map<String, List<dynamic>>> superSmartSearch(String input) async {
    final String cleanInput = input.trim();
    if (cleanInput.isEmpty) return {'series': [], 'movies': [], 'manga': []};

    debugPrint(
      '[SuperQuery] Starting aggressive fallback search for: "$cleanInput"',
    );

    final List<Series> seriesResults = [];
    final List<Movie> movieResults = [];
    final List<MangaSeries> mangaResults = [];

    // Try parsing an integer ID out of the string for direct Isar ID matching
    final int? possibleId = int.tryParse(cleanInput);

    // 1. --- SEARCH SERIES ---
    if (possibleId != null) {
      final item = await _isar.series.get(possibleId);
      if (item != null) seriesResults.add(item);
    }

    // Fallback text searches on title, tmdbId, or other fields
    final matchedSeries = await _isar.series
        .filter()
        .titleContains(cleanInput, caseSensitive: false)
        .or()
        .tmdbIdEqualTo(cleanInput)
        .findAll();

    for (var item in matchedSeries) {
      if (!seriesResults.any((e) => e.id == item.id)) seriesResults.add(item);
    }

    // 2. --- SEARCH MOVIES ---
    if (possibleId != null) {
      final item = await _isar.movies.get(possibleId);
      if (item != null) movieResults.add(item);
    }

    final matchedMovies = await _isar.movies
        .filter()
        .titleContains(cleanInput, caseSensitive: false)
        .or()
        .tmdbIdEqualTo(cleanInput)
        .findAll();

    for (var item in matchedMovies) {
      if (!movieResults.any((e) => e.id == item.id)) movieResults.add(item);
    }

    // 3. --- SEARCH MANGA ---
    if (possibleId != null) {
      final item = await _isar.mangaSeries.get(possibleId);
      if (item != null) mangaResults.add(item);
    }

    final matchedManga = await _isar.mangaSeries
        .filter()
        .titleContains(cleanInput, caseSensitive: false)
        .or()
        .authorContains(cleanInput, caseSensitive: false)
        .or()
        .seriesIdEqualTo(cleanInput)
        .findAll();

    for (var item in matchedManga) {
      if (!mangaResults.any((e) => e.id == item.id)) mangaResults.add(item);
    }

    debugPrint(
      '[SuperQuery] Execution completed. Found ${seriesResults.length} series, ${movieResults.length} movies, ${mangaResults.length} manga items.',
    );

    return {
      'series': seriesResults,
      'movies': movieResults,
      'manga': mangaResults,
    };
  }

  Stream<List<LibraryConfig>> watchLibraries() {
    return _isar.libraryConfigs.where().watch(fireImmediately: true);
  }

  /// Create or update a media library
  Future<void> saveLibrary(LibraryConfig config) async {
    await _isar.writeTxn(() async {
      await _isar.libraryConfigs.put(config);
    });
    notifyListeners(); // Updates Riverpod listeners
  }

  /// Remove a media library config completely
  Future<void> deleteLibrary(Id id) async {
    await _isar.writeTxn(() async {
      await _isar.libraryConfigs.delete(id);

      // Emby behavior option: Clean up or untag items that were linked to this library config
      // Example:
      // final orphanedMovies = await _isar.movies.filter().libraryConfigIdEqualTo(id).findAll();
      // ... process untagging or deleting orphaned media file metadata here
    });
    notifyListeners();
  }

  Future<void> writeScanResultToIsar(
    Isar isar,
    Map<String, dynamic> payload,
  ) async {
    await isar.writeTxn(() async {
      // 1. Process Movie Nodes
      if (payload['movies'] != null) {
        for (var m in payload['movies']) {
          final moviePath = m['path'] as String;

          // Check for existing records to prevent duplicates
          var movieNode = await isar.localMovies
              .filter()
              .pathEqualTo(moviePath)
              .findFirst();
          if (movieNode == null) {
            movieNode = LocalMovie()
              ..path = moviePath
              ..parentPath = m['parent_path'] ?? ""
              ..name = m['name'] ?? "";
            await isar.localMovies.put(movieNode);
          }

          if (m['movie_items'] != null) {
            for (var item in m['movie_items']) {
              final itemPath = item['path'] as String;
              var subItem = await isar.localMovieItems
                  .filter()
                  .pathEqualTo(itemPath)
                  .findFirst();
              if (subItem == null) {
                subItem = LocalMovieItem()
                  ..path = itemPath
                  ..name = item['name'] ?? ""
                  ..size = item['size'] ?? 0
                  ..modTime = item['mod_time'] ?? 0;
                await isar.localMovieItems.put(subItem);
                movieNode.movieItems.add(subItem);
              }
            }
            await movieNode.movieItems.save();
          }
        }
      }

      // 2. Process TV Series Nodes
      if (payload['tv'] != null) {
        for (var s in payload['tv']) {
          final seriesPath = s['path'] as String;
          var seriesNode = await isar.localTvSeries
              .filter()
              .pathEqualTo(seriesPath)
              .findFirst();
          if (seriesNode == null) {
            seriesNode = LocalTvSeries()
              ..path = seriesPath
              ..parentPath = s['parent_path'] ?? ""
              ..name = s['name'] ?? "";
            await isar.localTvSeries.put(seriesNode);
          }

          if (s['seasons'] != null) {
            for (var seasonData in s['seasons']) {
              final currentSeasonNum = seasonData['season_number'] as int;

              final seasonNode = LocalTvSeason()
                ..seasonNumber = currentSeasonNum;
              await isar.localTvSeasons.put(seasonNode);
              seriesNode.seasons.add(seasonNode);

              if (seasonData['episodes'] != null) {
                for (var ep in seasonData['episodes']) {
                  final epPath = ep['path'] as String;
                  var epNode = await isar.localTvEpisodes
                      .filter()
                      .pathEqualTo(epPath)
                      .findFirst();
                  if (epNode == null) {
                    epNode = LocalTvEpisode()
                      ..path = epPath
                      ..name = ep['name'] ?? ""
                      ..seasonNumber = ep['season_number'] ?? 1
                      ..episodeNumber = ep['episode_number'] ?? 1
                      ..size = ep['size'] ?? 0;
                    await isar.localTvEpisodes.put(epNode);
                    seasonNode.episodes.add(epNode);
                  }
                }
                await seasonNode.episodes.save();
              }
            }
            await seriesNode.seasons.save();
          }
        }
      }
    });
  }

  Future<IsarAnilistMedia?> getAnilistMediaByAnilistId(int anilistId) async {
    return await _isar.isarAnilistMedias
        .where()
        .anilistIdEqualTo(anilistId)
        .findFirst();
  }

  Future<List<IsarAnilistMedia>> getAnilistMediaByType(
    AnilistMediaType type,
  ) async {
    return await _isar.isarAnilistMedias
        .where()
        .contentTypeEqualTo(type)
        .findAll();
  }

  Future<List<IsarAnilistMedia>> searchAnilistMedia(String query) async {
    if (query.isEmpty) return [];
    return await _isar.isarAnilistMedias
        .filter()
        .titleRomajiContains(query, caseSensitive: false)
        .or()
        .genresElementContains(query, caseSensitive: false)
        .findAll();
  }

  Stream<List<IsarAnilistMedia>> watchAnilistMediaByType(
    AnilistMediaType type,
  ) {
    return _isar.isarAnilistMedias
        .where()
        .contentTypeEqualTo(type)
        .watch(fireImmediately: true);
  }

  // --- User & Media List ---

  Future<IsarAnilistUser?> getAnilistUserById(int anilistId) async {
    return await _isar.isarAnilistUsers
        .where()
        .anilistIdEqualTo(anilistId)
        .findFirst();
  }

  Future<IsarAnilistMediaList?> getUserMediaListEntry({
    required int userId,
    required int mediaId,
  }) async {
    return await _isar.isarAnilistMediaLists
        .where()
        .userIdEqualTo(userId)
        .filter()
        .mediaIdEqualTo(mediaId)
        .findFirst();
  }

  Future<List<IsarAnilistMediaList>> getUserMediaLists({
    required int userId,
    AnilistMediaListStatus? status,
  }) async {
    var query = _isar.isarAnilistMediaLists.where().userIdEqualTo(userId);

    if (status != null) {
      return await query.filter().statusEqualTo(status).findAll();
    }
    return await query.findAll();
  }

  Future<List<IsarAnilistMedia>> getUserMediaListWithMedia({
    required int userId,
    AnilistMediaListStatus? status,
  }) async {
    final lists = await getUserMediaLists(userId: userId, status: status);
    final mediaIds = lists.map((e) => e.mediaId).toList();

    return await _isar.isarAnilistMedias
        .where()
        .anyOf(mediaIds, (q, id) => q.anilistIdEqualTo(id))
        .findAll();
  }

  // --- Relationships ---

  Future<void> loadMediaCharacters(IsarAnilistMedia media) async {
    if (media.characters.isAttached) {
      await media.characters.load();
    }
  }

  Future<void> loadMediaStaff(IsarAnilistMedia media) async {
    if (media.staff.isAttached) {
      await media.staff.load();
    }
  }

  Future<List<IsarAnilistCharacter>> getCharactersForMedia(
    int anilistId,
  ) async {
    final media = await getAnilistMediaByAnilistId(anilistId);
    if (media == null) return [];
    await loadMediaCharacters(media);
    return media.characters.toList();
  }

  // --- Bulk Save Helpers ---

  /// Saves a media object with its tags and relationships
  Future<void> saveAnilistMedia(IsarAnilistMedia media) async {
    await _isar.writeTxn(() async {
      await _isar.isarAnilistMedias.put(media);

      // Save tags
      if (media.tags.isNotEmpty) {
        await _isar.isarAnilistTags.putAll(media.tags);
      }
    });
  }

  /// Bulk save media + tags efficiently
  Future<void> saveAnilistMediaList(List<IsarAnilistMedia> medias) async {
    final tags = medias.expand((m) => m.tags).toList();

    await _isar.writeTxn(() async {
      await _isar.isarAnilistMedias.putAll(medias);
      if (tags.isNotEmpty) {
        await _isar.isarAnilistTags.putAll(tags);
      }
    });
  }

  /// Save user + their media list entries
  Future<void> saveUserWithMediaList(
    IsarAnilistUser user,
    List<IsarAnilistMediaList> listEntries,
  ) async {
    await _isar.writeTxn(() async {
      await _isar.isarAnilistUsers.put(user);
      await _isar.isarAnilistMediaLists.putAll(listEntries);
    });
  }

  // --- Smart Sync Helpers ---

  /// Upsert media from Anilist API response
  Future<IsarAnilistMedia> upsertAnilistMediaFromApi(
    dynamic anilistMedia, // Your AnilistMedia from package
  ) async {
    final existing = await getAnilistMediaByAnilistId(anilistMedia.id);

    final isarMedia = IsarAnilistMedia()
      ..anilistId = anilistMedia.id
      ..idMal = anilistMedia.idMal
      ..titleRomaji = anilistMedia.title?.romaji ?? ''
      ..title = (IsarAnilistTitle()
        ..romaji = anilistMedia.title?.romaji
        ..english = anilistMedia.title?.english
        ..native = anilistMedia.title?.native)
      ..coverImage = (IsarAnilistCoverImage()
        ..large = anilistMedia.coverImage?.large
        ..extraLarge = anilistMedia.coverImage?.extraLarge
        ..medium = anilistMedia.coverImage?.medium
        ..color = anilistMedia.coverImage?.color)
      ..type = anilistMedia.type == AnilistMediaType.ANIME
          ? AnilistMediaType.ANIME
          : AnilistMediaType.MANGA
      ..contentType = anilistMedia.type == AnilistMediaType.ANIME
          ? AnilistMediaType.ANIME
          : AnilistMediaType.MANGA
      ..format = anilistMedia.format
      ..status = anilistMedia.status
      ..description = anilistMedia.description
      ..genres = (anilistMedia.genres?.toList() ?? []).cast<String>()
      ..averageScore = anilistMedia.averageScore
      ..meanScore = anilistMedia.meanScore
      ..popularity = anilistMedia.popularity
      ..favourites = anilistMedia.favourites
      ..updatedAt = anilistMedia.updatedAt
      ..lastSyncedAt = DateTime.now();

    // Handle tags
    if (anilistMedia.tags != null) {
      isarMedia.tags = anilistMedia.tags!
          .map(
            (t) => IsarAnilistTag()
              ..anilistId = t.id ?? 0
              ..name = t.name
              ..description = t.description
              ..rank = t.rank
              ..isAdult = t.isAdult,
          )
          .toList();
    }

    await saveAnilistMedia(isarMedia);
    return isarMedia;
  }

  // --- Watchers ---

  Stream<List<IsarAnilistMediaList>> watchUserMediaList(int userId) {
    return _isar.isarAnilistMediaLists
        .where()
        .userIdEqualTo(userId)
        .watch(fireImmediately: true);
  }

  Stream<List<IsarAnilistUser>> watchAnilistUsers() {
    return _isar.isarAnilistUsers.where().watch(fireImmediately: true);
  }

  // --- Utility ---

  Future<void> clearAnilistData() async {
    await _isar.writeTxn(() async {
      await _isar.isarAnilistMedias.clear();
      await _isar.isarAnilistMediaLists.clear();
      await _isar.isarAnilistUsers.clear();
      await _isar.isarAnilistCharacters.clear();
      await _isar.isarAnilistStaffs.clear();
    });
  }

  Future<int> getAnilistMediaCount() async {
    return await _isar.isarAnilistMedias.count();
  }

  static IsarAnilistMedia fromAnilistMedia(IsarAnilistMedia apiMedia) {
    final isarMedia = IsarAnilistMedia()
      ..anilistId = apiMedia.id
      ..idMal = apiMedia.idMal
      ..titleRomaji = apiMedia.title?.romaji ?? ''
      ..title = _mapTitle(apiMedia.title)
      ..coverImage = apiMedia.coverImage
      ..bannerImage = apiMedia.bannerImage
      ..description = apiMedia.description
      ..type = _mapMediaType(apiMedia.type)
      ..contentType = _mapMediaType(apiMedia.type)
      ..format = (apiMedia.format)
      ..status = (apiMedia.status)
      ..source = (apiMedia.source)
      ..season = apiMedia.season
      ..seasonYear = apiMedia.seasonYear
      ..episodes = apiMedia.episodes
      ..duration = apiMedia.duration
      ..chapters = apiMedia.chapters
      ..volumes = apiMedia.volumes
      ..countryOfOrigin = apiMedia.countryOfOrigin
      ..isLicensed = apiMedia.isLicensed
      ..isAdult =
          null // API sometimes doesn't expose this directly
      ..averageScore = apiMedia.averageScore
      ..meanScore = apiMedia.meanScore
      ..popularity = apiMedia.popularity
      ..favourites = apiMedia.favourites
      ..trending = apiMedia.trending
      ..genres = apiMedia.genres?.toList() ?? []
      ..synonyms = apiMedia.synonyms?.toList() ?? []
      ..updatedAt = apiMedia.updatedAt
      ..lastSyncedAt = DateTime.now();

    // Map Tags
    if (apiMedia.tags.isNotEmpty) {
      isarMedia.tags = apiMedia.tags!
          .map(
            (t) => IsarAnilistTag()
              ..anilistId = t.id
              ..name = t.name
              ..description = t.description
              ..category = t.category
              ..rank = t.rank
              ..isGeneralSpoiler = t.isGeneralSpoiler
              ..isMediaSpoiler = t.isMediaSpoiler
              ..isAdult = t.isAdult,
          )
          .toList();
    }

    return isarMedia;
  }

  static IsarAnilistTitle _mapTitle(IsarAnilistTitle? title) {
    return IsarAnilistTitle()
      ..romaji = title?.romaji
      ..english = title?.english
      ..native = title?.native;
  }

  static IsarAnilistCoverImage _mapCoverImage(IsarAnilistImage? image) {
    return IsarAnilistCoverImage()
      ..extraLarge = image?.extraLarge
      ..large = image?.large
      ..medium = image?.medium
      ..color = image?.color;
  }

  // ==========================================
  // CHARACTER MAPPING
  // ==========================================

  static IsarAnilistCharacter fromAnilistCharacter(
    IsarAnilistCharacter apiChar,
  ) {
    return IsarAnilistCharacter()
      ..anilistId = apiChar.id ?? 0
      ..name = _mapName(apiChar.name)
      ..image = _mapCharacterImage(apiChar.image)
      ..description = apiChar.description
      ..gender = apiChar.gender
      ..age = apiChar.age
      ..bloodType = apiChar.bloodType
      ..favourites = apiChar.favourites
      ..isFavourite = apiChar.isFavourite
      ..siteUrl = apiChar.siteUrl
      ..updatedAt = DateTime.now().millisecondsSinceEpoch;
  }

  static IsarAnilistName _mapName(IsarAnilistName? name) {
    return IsarAnilistName()
      ..first = name?.first
      ..last = name?.last
      ..full = name?.full
      ..native = name?.native
      ..alternative = name?.alternative?.toList() ?? [];
  }

  static IsarAnilistImage _mapCharacterImage(IsarAnilistImage? image) {
    return IsarAnilistImage()
      ..large = image?.large
      ..medium = image?.medium
      ..extraLarge = image?.extraLarge;
  }

  // ==========================================
  // STAFF MAPPING
  // ==========================================

  static IsarAnilistStaff fromAnilistStaff(IsarAnilistStaff apiStaff) {
    return IsarAnilistStaff()
      ..anilistId = apiStaff.id
      ..name = _mapName(apiStaff.name)
      ..image = _mapCharacterImage(apiStaff.image)
      ..description = apiStaff.description
      ..gender = apiStaff.gender
      ..language = apiStaff.language
      ..languageV2 = apiStaff.languageV2
      ..homeTown = apiStaff.homeTown
      ..age = apiStaff.age
      ..favourites = apiStaff.favourites
      ..isFavourite = apiStaff.isFavourite
      ..primaryOccupations = apiStaff.primaryOccupations.toList() ?? []
      ..dateOfBirth = _mapDate(apiStaff.dateOfBirth)
      ..dateOfDeath = _mapDate(apiStaff.dateOfDeath);
  }

  static IsarAnilistDate? _mapDate(IsarAnilistDate? date) {
    if (date == null) return null;
    return IsarAnilistDate()
      ..year = date.year
      ..month = date.month
      ..day = date.day;
  }

  // ==========================================
  // USER MAPPING
  // ==========================================

  static IsarAnilistUser fromAnilistUser(IsarAnilistUser apiUser) {
    return IsarAnilistUser()
      ..anilistId = apiUser.id ?? 0
      ..name = apiUser.name ?? ''
      ..about = apiUser.about
      ..siteUrl = apiUser.siteUrl
      ..donatorTier = apiUser.donatorTier
      ..donatorBadge = apiUser.donatorBadge
      ..avatar = _mapUserAvatar(apiUser.avatar)
      ..unreadNotificationCount = apiUser.unreadNotificationCount
      ..createdAt = apiUser.createdAt
      ..updatedAt = apiUser.updatedAt
      ..options = _mapUserOptions(apiUser.options)
      ..mediaListOptions = _mapMediaListOptions(apiUser.mediaListOptions);
  }

  static IsarAnilistImage _mapUserAvatar(IsarAnilistImage? avatar) {
    return IsarAnilistImage()
      ..large = avatar?.large
      ..medium = avatar?.medium;
  }

  static IsarAnilistUserOptions? _mapUserOptions(
    IsarAnilistUserOptions? options,
  ) {
    if (options == null) return null;
    return IsarAnilistUserOptions()
      ..titleLanguage = options.titleLanguage
      ..displayAdultContent = options.displayAdultContent
      ..airingNotifications = options.airingNotifications
      ..profileColor = options.profileColor;
  }

  static IsarAnilistMediaListOptions? _mapMediaListOptions(
    IsarAnilistMediaListOptions? options,
  ) {
    if (options == null) return null;
    return IsarAnilistMediaListOptions()
      ..scoreFormat = options.scoreFormat
      ..rowOrder = options.rowOrder;
  }

  // ==========================================
  // MEDIA LIST MAPPING
  // ==========================================

  static IsarAnilistMediaList fromAnilistMediaList(
    IsarAnilistMediaList apiList,
    int userId,
  ) {
    return IsarAnilistMediaList()
      ..anilistId = apiList.id
      ..userId = userId
      ..mediaId = apiList.media.value?.id ?? 0
      ..status = _mapMediaListStatus(apiList.status)
      ..score = apiList.score
      ..progress = apiList.progress
      ..progressVolumes = apiList.progressVolumes
      ..repeat = apiList.repeat
      ..startedAt = _mapDate(apiList.startedAt)
      ..completedAt = _mapDate(apiList.completedAt)
      ..private = apiList.private
      ..hiddenFromStatusLists = apiList.hiddenFromStatusLists
      ..notes = apiList.notes
      ..updatedAt = apiList.updatedAt
      ..createdAt = apiList.createdAt;
  }

  // ==========================================
  // OTHER MAPPERS
  // ==========================================

  static IsarAnilistStudio fromAnilistStudio(IsarAnilistStudio apiStudio) {
    return IsarAnilistStudio()
      ..anilistId = apiStudio.id ?? 0
      ..name = apiStudio.name
      ..isAnimationStudio = apiStudio.isAnimationStudio
      ..favourites = apiStudio.favourites
      ..isFavourite = apiStudio.isFavourite
      ..siteUrl = apiStudio.siteUrl;
  }

  static IsarAnilistReview fromAnilistReview(IsarAnilistReview apiReview) {
    return IsarAnilistReview()
      ..anilistId = apiReview.id ?? 0
      ..userId = apiReview.userId
      ..mediaId = apiReview.mediaId
      ..summary = apiReview.summary
      ..body = apiReview.body
      ..score = apiReview.score
      ..rating = apiReview.rating
      ..ratingAmount = apiReview.ratingAmount
      ..private = apiReview.private
      ..createdAt = apiReview.createdAt
      ..updatedAt = apiReview.updatedAt;
  }

  static IsarAnilistRecommendation fromAnilistRecommendation(
    IsarAnilistRecommendation apiRec,
  ) {
    return IsarAnilistRecommendation()
      ..anilistId = apiRec.id ?? 0
      ..mediaId = apiRec.mediaId
      ..mediaRecommendationId = apiRec.mediaRecommendationId
      ..rating = apiRec.rating
      ..userId = apiRec.userId;
  }

  // ==========================================
  // ENUM HELPERS
  // ==========================================

  static AnilistMediaType _mapMediaType(AnilistMediaType? type) {
    if (type == null) return AnilistMediaType.ANIME;
    return type == AnilistMediaType.ANIME
        ? AnilistMediaType.ANIME
        : AnilistMediaType.MANGA;
  }

  static AnilistMediaFormat? _mapMediaFormat(
    AnilistMediaFormat? format,
  ) => format;
  static AnilistMediaStatus? _mapMediaStatus(
    AnilistMediaStatus? status,
  ) => status;
  static AnilistMediaSource? _mapMediaSource(
    AnilistMediaSource? source,
  ) => source;

  static AnilistMediaListStatus _mapMediaListStatus(
    AnilistMediaListStatus? status,
  ) {
    if (status == null) return AnilistMediaListStatus.PLANNING;
    switch (status) {
      case AnilistMediaListStatus.CURRENT:
        return AnilistMediaListStatus.CURRENT;
      case AnilistMediaListStatus.PLANNING:
        return AnilistMediaListStatus.PLANNING;
      case AnilistMediaListStatus.COMPLETED:
        return AnilistMediaListStatus.COMPLETED;
      case AnilistMediaListStatus.DROPPED:
        return AnilistMediaListStatus.DROPPED;
      case AnilistMediaListStatus.PAUSED:
        return AnilistMediaListStatus.PAUSED;
      case AnilistMediaListStatus.REPEATING:
        return AnilistMediaListStatus.REPEATING;
    }
  }


  Future<IsarAnilistMedia> saveAnilistMediaFromApi(IsarAnilistMedia media) async {
  final isarMedia = fromAnilistMedia(media);
  await put(isarMedia);
  return isarMedia;
}

Future<void> saveAnilistMediasFromApi(List<IsarAnilistMedia> medias) async {
  final isarMedias = medias.map(fromAnilistMedia).toList();
  await putAll(isarMedias);
}

// --- Character & Staff Helpers ---

Future<void> saveCharactersForMedia(
  int anilistMediaId,
  List<IsarAnilistCharacter> apiCharacters,
) async {
  final characters = apiCharacters
      .map(fromAnilistCharacter)
      .toList();

  await _isar.writeTxn(() async {
    await _isar.isarAnilistCharacters.putAll(characters);
  });
}

Future<void> saveStaffForMedia(
  int anilistMediaId,
  List<IsarAnilistStaff> apiStaff,
) async {
  final staff = apiStaff.map(fromAnilistStaff).toList();

  await _isar.writeTxn(() async {
    await _isar.isarAnilistStaffs.putAll(staff);
  });
}

Future<List<IsarAnilistCharacter>> getCharactersByMediaId(int anilistId) async {
  return await _isar.isarAnilistCharacters
      .filter()
      .media((q) => q.anilistIdEqualTo(anilistId))
      .findAll();
}

Future<List<IsarAnilistStaff>> getStaffByMediaId(int anilistId) async {
  return await _isar.isarAnilistStaffs
      .filter()
      .media((q) => q.anilistIdEqualTo(anilistId))
      .findAll();
}

// --- Reviews ---

Future<void> saveReviewFromApi(IsarAnilistReview apiReview) async {
  final review = fromAnilistReview(apiReview);
  await put(review);
}

Future<List<IsarAnilistReview>> getReviewsForMedia(int mediaId) async {
  return await _isar.isarAnilistReviews
      .where()
      .mediaIdEqualTo(mediaId)
      .findAll();
}

// --- Recommendations ---

Future<void> saveRecommendationFromApi(IsarAnilistRecommendation apiRec) async {
  final rec = fromAnilistRecommendation(apiRec);
  await put(rec);
}

Future<List<IsarAnilistRecommendation>> getRecommendationsForMedia(int mediaId) async {
  return await _isar.isarAnilistRecommendations
      .where()
      .mediaIdEqualTo(mediaId)
      .findAll();
}

// --- Full Media + Relations Save ---

Future<IsarAnilistMedia> saveFullMediaWithRelations(IsarAnilistMedia apiMedia) async {
  final isarMedia = await saveAnilistMediaFromApi(apiMedia);

  // Save characters if available
  if (apiMedia.characters.singleOrNull != null) {
    final chars = apiMedia.characters
        .where((e) => e != null)
        .map((e) => e.media)
        .whereType<IsarAnilistCharacter>()
        .toList();
    await saveCharactersForMedia(isarMedia.anilistId, chars);
  }

  // Save staff if available
  if (apiMedia.staff.singleOrNull!=null) {
    final staff = apiMedia.staff
        .where((e) => e != null)
        .map((e) => e.media)
        .whereType<IsarAnilistStaff>()
        .toList();
    await saveStaffForMedia(isarMedia.anilistId, staff);
  }

  return isarMedia;
}

// --- User + MediaList Sync ---

Future<void> saveUserWithListCollection(
  IsarAnilistUser apiUser,
  List<IsarAnilistMediaList> mediaLists,
) async {
  final isarUser = fromAnilistUser(apiUser);
  final isarLists = mediaLists
      .map((list) => fromAnilistMediaList(list, isarUser.anilistId))
      .toList();

  await _isar.writeTxn(() async {
    await _isar.isarAnilistUsers.put(isarUser);
    await _isar.isarAnilistMediaLists.putAll(isarLists);
  });
}

// --- Utility ---

Future<void> clearAllAnilistData() async {
  await _isar.writeTxn(() async {
    await _isar.isarAnilistMedias.clear();
    await _isar.isarAnilistCharacters.clear();
    await _isar.isarAnilistStaffs.clear();
    await _isar.isarAnilistMediaLists.clear();
    await _isar.isarAnilistUsers.clear();
    await _isar.isarAnilistReviews.clear();
    await _isar.isarAnilistRecommendations.clear();
  });
}

Stream<List<IsarAnilistMedia>> watchAnilistLibrary() {
  return _isar.isarAnilistMedias.where().watch(fireImmediately: true);
}

}
