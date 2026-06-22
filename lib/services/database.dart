import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:omiku/models/models.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseService {
  // Singleton pattern so you don't accidentally open multiple instances
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  late Isar _isar;
  late Isar isar;

  /// Call this in your main.dart BEFORE runApp()
  Future<void> init() async {
    debugPrint('[DatabaseService] Initializing Isar database...');
    final dir = await getApplicationDocumentsDirectory();
    debugPrint('[DatabaseService] Application documents directory: ${dir.path}');
    
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
      ],
      directory: dir.path,
      inspector: true, // Enables a web browser UI to look inside your DB during debug mode!
    );
    isar = _isar;
    debugPrint('[DatabaseService] Isar database successfully opened.');
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
    });
    debugPrint('[DatabaseService] put() completed for item type: $T');
  }

  /// Bulk Insert or Update (Crucial for performance with 10,000+ items)
  Future<void> putAll<T>(List<T> items) async {
    debugPrint('[DatabaseService] putAll() called with ${items.length} items of type: $T');
    await _isar.writeTxn(() async {
      if (items is List<PlayableFile>)
        await _isar.playableFiles.putAll(items as List<PlayableFile>);
      if (items is List<Series>)
        await _isar.series.putAll(items as List<Series>);
      if (items is List<Season>)
        await _isar.seasons.putAll(items as List<Season>);
      if (items is List<Episode>)
        await _isar.episodes.putAll(items as List<Episode>);
      if (items is List<Movie>) await _isar.movies.putAll(items as List<Movie>);
      if (items is List<Person>)
        await _isar.persons.putAll(items as List<Person>);
      if (items is List<MangaSeries>)
        await _isar.mangaSeries.putAll(items as List<MangaSeries>);
      if (items is List<MangaChapter>)
        await _isar.mangaChapters.putAll(items as List<MangaChapter>);
      if (items is List<ChapterPage>)
        await _isar.chapterPages.putAll(items as List<ChapterPage>);
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

    debugPrint('[DatabaseService] get() result for type $T (ID: $id) found: ${result != null}');
    return result;
  }

  /// Get everything from a collection
  Future<List<T>> getAll<T>() async {
    debugPrint('[DatabaseService] getAll() requested for collection type: $T');
    List<T>? results;
    if (T == PlayableFile) results = await _isar.playableFiles.where().findAll() as List<T>;
    if (T == Series) results = await _isar.series.where().findAll() as List<T>;
    if (T == Season) results = await _isar.seasons.where().findAll() as List<T>;
    if (T == Episode) results = await _isar.episodes.where().findAll() as List<T>;
    if (T == Movie) results = await _isar.movies.where().findAll() as List<T>;
    if (T == Person) results = await _isar.persons.where().findAll() as List<T>;
    if (T == MangaSeries) results = await _isar.mangaSeries.where().findAll() as List<T>;
    if (T == MangaChapter) results = await _isar.mangaChapters.where().findAll() as List<T>;
    if (T == ChapterPage) results = await _isar.chapterPages.where().findAll() as List<T>;

    results ??= [];
    debugPrint('[DatabaseService] getAll() for type $T returned ${results.length} records.');
    return results;
  }

  /// Delete an item by its Isar ID
  Future<bool> delete<T>(Id id) async {
    debugPrint('[DatabaseService] delete() called for collection type $T with ID: $id');
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
      return false;
    });
    debugPrint('[DatabaseService] delete() for type $T, ID: $id status: $success');
    return success;
  }

  /// Clear the entire database completely
  Future<void> clearDatabase() async {
    debugPrint('[DatabaseService] WARNING: clearDatabase() called! Wiping entire Isar DB.');
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
    debugPrint('[VideoQuery] getEpisodesBySeason() called for Season ID: $seasonId');
    final episodes = await _isar.episodes.where().seasonIdEqualTo(seasonId).findAll();
    debugPrint('[VideoQuery] getEpisodesBySeason() found ${episodes.length} episodes.');
    return episodes;
  }

  Future<void> saveSeriesWithSeasons(Series series, List<Season> seasons) async {
    debugPrint('[VideoQuery] saveSeriesWithSeasons() saving Series ID: ${series.seriesId} with ${seasons.length} seasons.');
    final linkedSeasons = seasons.map((season) {
      return season..seriesId = series.seriesId;
    }).toList();

    await _isar.writeTxn(() async {
      await _isar.series.put(series);
      await _isar.seasons.putAll(linkedSeasons);
    });
    debugPrint('[VideoQuery] saveSeriesWithSeasons() cascading write finalized.');
  }

  Future<Person?> getPersonByTmdbId(String tmdbId) async {
    debugPrint('[VideoQuery] getPersonByTmdbId() searching Person TMDB ID: $tmdbId');
    return await _isar.persons.where().tmdbPersonIdEqualTo(tmdbId).findFirst();
  }

  /// Fetch all Seasons belonging to a specific Series
  Future<List<Season>> getSeasonsForSeries(String seriesId) async {
    debugPrint('[VideoQuery] getSeasonsForSeries() fetching seasons for Series ID: $seriesId');
    final seasons = await _isar.seasons.where().seriesIdEqualTo(seriesId).findAll();
    debugPrint('[VideoQuery] getSeasonsForSeries() found ${seasons.length} seasons.');
    return seasons;
  }

  Future<void> saveSeasonWithEpisodes(Season season, List<Episode> episodes) async {
    debugPrint('[VideoQuery] saveSeasonWithEpisodes() called for Season ID: ${season.seasonId}');
    final linkedEpisodes = episodes.map((episode) {
      return episode
        ..seasonId = season.seasonId
        ..seriesId = season.seriesId;
    }).toList();

    await _isar.writeTxn(() async {
      await _isar.seasons.put(season);
      await _isar.episodes.putAll(linkedEpisodes);
    });
    debugPrint('[VideoQuery] saveSeasonWithEpisodes() completed committing season and episodes.');
  }

  /// Fetch all Episodes belonging to a specific Season, sorted by their order
  Future<List<Episode>> getEpisodesForSeason(String seasonId) async {
    debugPrint('[VideoQuery] getEpisodesForSeason() fetching sorted episodes for Season ID: $seasonId');
    return await _isar.episodes
        .where()
        .seasonIdEqualTo(seasonId)
        .sortByEpisodeIndex()
        .findAll();
  }

  Future<Map<Season, List<Episode>>> getFullSeriesTree(String seriesId) async {
    debugPrint('[VideoQuery] getFullSeriesTree() assembling tree for Series ID: $seriesId');
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
      debugPrint('[MangaQuery] searchManga query is empty. Returning empty list.');
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
    debugPrint('[MangaQuery] getMangaSeriesById() looking up Manga Series ID: $seriesId');
    return await _isar.mangaSeries
        .where()
        .seriesIdEqualTo(seriesId)
        .findFirst();
  }

  // 2. Get Pages for a Chapter (sorted by natural page order)
  Future<List<ChapterPage>> getPagesForChapter(String chapterId) async {
    debugPrint('[MangaQuery] getPagesForChapter() fetching sorted pages for Chapter ID: $chapterId');
    return await _isar.chapterPages
        .where()
        .chapterIdEqualTo(chapterId)
        .sortByPageNumber()
        .findAll();
  }

  // 3. Get Chapter for a Page
  Future<MangaChapter?> getChapterForPage(ChapterPage page) async {
    if (page.chapterLink.isAttached) {
      debugPrint('[MangaQuery] getChapterForPage() chapter link attached, loading...');
      await page.chapterLink.load();
      if (page.chapterLink.value != null) return page.chapterLink.value;
    }
    debugPrint('[MangaQuery] getChapterForPage() falling back to query by Chapter ID: ${page.chapterId}');
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
    debugPrint('[MangaQuery] getPageByIndex() fetching index $pageIndex for Chapter ID: $chapterId');
    return await _isar.chapterPages
        .where()
        .chapterIdEqualTo(chapterId)
        .filter()
        .pageNumberEqualTo(pageIndex)
        .findFirst();
  }

  // 7. Bulk Save Pages for Chapter (with safe linking structure)
  Future<void> savePagesForChapter(MangaChapter chapter, List<ChapterPage> pages) async {
    debugPrint('[MangaQuery] savePagesForChapter() saving ${pages.length} pages for Chapter ID: ${chapter.chapterId}');
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
  Future<ChapterPage?> getNextPageInChapter(String chapterId, int currentPageNumber) async {
    debugPrint('[MangaQuery] getNextPageInChapter() fetching page after index $currentPageNumber for Chapter ID: $chapterId');
    return await _isar.chapterPages
        .where()
        .chapterIdEqualTo(chapterId)
        .filter()
        .pageNumberEqualTo(currentPageNumber + 1)
        .findFirst();
  }

  // 9. Last (Previous) Page in Chapter
  Future<ChapterPage?> getPreviousPageInChapter(String chapterId, int currentPageNumber) async {
    if (currentPageNumber <= 0) return null;
    debugPrint('[MangaQuery] getPreviousPageInChapter() fetching page before index $currentPageNumber for Chapter ID: $chapterId');
    return await _isar.chapterPages
        .where()
        .chapterIdEqualTo(chapterId)
        .filter()
        .pageNumberEqualTo(currentPageNumber - 1)
        .findFirst();
  }

  // 10. Next Chapter in Manga Series
  Future<MangaChapter?> getNextChapter(String seriesId, double currentChapterNumber) async {
    debugPrint('[MangaQuery] getNextChapter() fetching next chapter after $currentChapterNumber for Series ID: $seriesId');
    return await _isar.mangaChapters
        .where()
        .seriesIdEqualTo(seriesId)
        .filter()
        .chapterNumberGreaterThan(currentChapterNumber)
        .sortByChapterNumber()
        .findFirst();
  }

  // 11. Last (Previous) Chapter in Manga Series
  Future<MangaChapter?> getPreviousChapter(String seriesId, double currentChapterNumber) async {
    debugPrint('[MangaQuery] getPreviousChapter() fetching previous chapter before $currentChapterNumber for Series ID: $seriesId');
    return await _isar.mangaChapters
        .where()
        .seriesIdEqualTo(seriesId)
        .filter()
        .chapterNumberLessThan(currentChapterNumber)
        .sortByChapterNumberDesc()
        .findFirst();
  }

  /// Cascading Save: Saves a Manga Series along with its Chapters
  Future<void> saveMangaWithChapters(MangaSeries series, List<MangaChapter> chapters) async {
    debugPrint('[MangaQuery] saveMangaWithChapters() cascading save initiated for Series ID: ${series.seriesId}');
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
    debugPrint('[MangaQuery] saveMangaWithChapters() cascading save completed.');
  }

  /// Fetch all chapters for a specific Manga series safely via links
  Future<List<MangaChapter>> getChaptersForSeries(String seriesId) async {
    debugPrint('[MangaQuery] getChaptersForSeries() getting chapters using Isar links for Series ID: $seriesId');
    final series = await getMangaSeriesById(seriesId);
    if (series == null) {
      debugPrint('[MangaQuery] getChaptersForSeries() series not found, returning empty.');
      return [];
    }

    return await series.chapters.filter().sortByChapterNumber().findAll();
  }

  /// Cascading Save: Saves a Chapter along with all its structural Pages
  Future<void> saveChapterWithPages(MangaChapter chapter, List<ChapterPage> pages) async {
    debugPrint('[MangaQuery] saveChapterWithPages() saving chapter/pages transaction for Chapter ID: ${chapter.chapterId}');
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
  Future<void> updateMangaProgress(String seriesId, IsarUserProgress updatedProgress) async {
    debugPrint('[MangaQuery] updateMangaProgress() updating reading dashboard status for Series ID: $seriesId');
    final series = await getMangaSeriesById(seriesId);
    if (series != null) {
      series.progress = updatedProgress;
      await _isar.writeTxn(() async {
        await _isar.mangaSeries.put(series);
      });
      debugPrint('[MangaQuery] updateMangaProgress() progress committed successfully.');
    } else {
      debugPrint('[MangaQuery] updateMangaProgress() failed, Series ID $seriesId not found.');
    }
  }

  Future<List<MangaSeries>> getMangaLibraryWithChapters() async {
    debugPrint('[MangaQuery] getMangaLibraryWithChapters() loading entire library trees.');
    final seriesList = await _isar.mangaSeries.where().findAll();

    for (final series in seriesList) {
      if (series.chapters.isAttached) {
        await series.chapters.load();
      } else {
        await getChaptersForSeries(series.seriesId);
      }
    }
    debugPrint('[MangaQuery] getMangaLibraryWithChapters() loaded ${seriesList.length} series.');
    return seriesList;
  }

  /// Reactive Stream: Real-time hook to listen to updates across all Manga Series
  Stream<List<MangaSeries>> watchMangaLibrary() {
    debugPrint('[Stream] watchMangaLibrary() stream subscribed.');
    return _isar.mangaSeries.where().watch();
  }

  Future<Movie?> getMovieByTmdbId(String tmdbId) async {
    debugPrint('[VideoQuery] getMovieByTmdbId() fetching Movie TMDB ID: $tmdbId');
    return await _isar.movies.where().tmdbIdEqualTo(tmdbId).findFirst();
  }

  /// Look up a Series from the local cache using its TMDB string ID
  Future<Series?> getSeriesByTmdbId(String tmdbId) async {
    debugPrint('[VideoQuery] getSeriesByTmdbId() fetching Series TMDB ID: $tmdbId');
    return await _isar.series.where().tmdbIdEqualTo(tmdbId).findFirst();
  }
}