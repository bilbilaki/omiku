import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:omiku/models/manga_series.dart';
import 'package:omiku/models/manga_panel.dart';

class MangaStore extends ChangeNotifier {
  // Access the pre-opened Hive box
  final Box _box = Hive.box('manga_store_box');

  List<MangaSeries> _library = [];
  bool _darkMode = false;

  // Getters
  List<MangaSeries> get library => _library;
  bool get darkMode => _darkMode;

  MangaStore() {
    _loadStateFromDisk();
  }

  /// 1. Load data from disk on startup
  void _loadStateFromDisk() {
    _darkMode = _box.get('darkMode', defaultValue: false);

    final String? cachedLibraryJson = _box.get('library');
    if (cachedLibraryJson != null) {
      try {
        final List<dynamic> decodedList = jsonDecode(cachedLibraryJson);
        _library = decodedList
            .map((item) => MangaSeries.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint("Error parsing cached library data: $e");
        _library = [];
      }
    }
    notifyListeners();
  }

  /// 2. Core Mutation Actions

  void toggleDarkMode() {
    _darkMode = !_darkMode;
    _box.put('darkMode', _darkMode);
    notifyListeners();
  }

  void addMangaSeries(MangaSeries series) {
    _library.add(series);
    _saveLibraryToDisk();
    notifyListeners();
  }

  /// [Suggested Addition] Cleanly remove a series from memory & disk
  void deleteMangaSeries(String seriesId) {
    _library.removeWhere((m) => m.id == seriesId);
    _saveLibraryToDisk();
    notifyListeners();
  }

  void addChapterToSeries(String seriesId, MangaChapter chapter) {
    final index = _library.indexWhere((m) => m.id == seriesId);
    if (index != -1) {
      _library[index] = _library[index].addChapter(chapter);
      _saveLibraryToDisk();
      notifyListeners();
    } else {
      debugPrint("Series with ID $seriesId not found for adding chapter.");
    }
  }

  // FIXED: Changed `p.pageNumber.toString() == pageId` to `p.pageId == pageId`
  void updateChapterPagePanels(
    String seriesId,
    String chapterId,
    String pageId,
    List<MangaPanel> newPanelsData, {
    bool notify = true,
  }) {
    final int seriesIndex = _library.indexWhere((m) => m.id == seriesId);
    if (seriesIndex != -1) {
      MangaSeries series = _library[seriesIndex];
      final int chapterIndex = series.chapters.indexWhere((c) => c.id == chapterId);
      
      if (chapterIndex != -1) {
        MangaChapter chapter = series.chapters[chapterIndex];
        final int pageIndex = chapter.pagesData.indexWhere((p) => p.pageId == pageId);
        
        if (pageIndex != -1) {
          ChapterPage oldPage = chapter.pagesData[pageIndex];
          ChapterPage updatedPage = oldPage.copyWith(panelsData: newPanelsData);

          MangaChapter updatedChapter = chapter.updatePage(updatedPage);
          MangaSeries updatedSeries = series.updateChapter(updatedChapter);

          _library[seriesIndex] = updatedSeries;
          if (notify) {
            _saveLibraryToDisk();
            notifyListeners();
          }
          debugPrint("Updated panels for page $pageId in chapter $chapterId, series $seriesId. Panels: ${newPanelsData.length}");
          return;
        }
      }
    }
    debugPrint("Failed to update panels: Series, chapter, or page not found.");
  }

  // FIXED: Removed premature return break traps
  MangaChapter? getChapterByID(String chapId) {
    for (MangaSeries ms in _library) {
      for (MangaChapter mc in ms.chapters) {
        if (mc.id == chapId) {
          return mc;
        }
      }
    }
    return null;
  }

  void applyChangedSeries(MangaSeries ms) {
    final int seriesIndex = _library.indexWhere((m) => m.id == ms.id);
    if (seriesIndex != -1) {
      _library[seriesIndex] = ms;
      _saveLibraryToDisk();
      notifyListeners(); // Added missing update notification
    }
  }

  MangaSeries? getSeriesByID(String seriesId) {
    final int seriesIndex = _library.indexWhere((m) => m.id == seriesId);
    if (seriesIndex != -1) {
      return _library[seriesIndex];
    }
    return null;
  }

  // FIXED: Replaced non-functional loop-variable re-assignment with model mutators
  void applyChangedChapter(String msId, MangaChapter mc) {
    final int seriesIndex = _library.indexWhere((m) => m.id == msId);
    if (seriesIndex != -1) {
      MangaSeries updatedSeries = _library[seriesIndex].updateChapter(mc);
      _library[seriesIndex] = updatedSeries;
      _saveLibraryToDisk();
      notifyListeners();
    }
  }

  // FIXED: Removed premature loop breaks
  MangaChapter? getChapterBySeriesIDAndChapNum(String seriesId, double chapnum) {
    final int seriesIndex = _library.indexWhere((m) => m.id == seriesId);
    if (seriesIndex != -1) {
      for (MangaChapter mc in _library[seriesIndex].chapters) {
        if (mc.chapterNumber == chapnum) {
          return mc;
        }
      }
    }
    return null;
  }

  // FIXED: Overcame variable mutation limits by locating parent indices via global scan
  void applyChangedChapterByJustMangaChapter(MangaChapter mc) {
    for (int i = 0; i < _library.length; i++) {
      final int chapterIndex = _library[i].chapters.indexWhere((c) => c.id == mc.id);
      if (chapterIndex != -1) {
        _library[i] = _library[i].updateChapter(mc);
        _saveLibraryToDisk();
        notifyListeners();
        return;
      }
    }
  }
  
  void updateReadingProgress(String seriesId, String chapterId, int page) {
    final index = _library.indexWhere((m) => m.id == seriesId);
    if (index != -1) {
      _library[index] = _library[index].copyWith(
        progress: _library[index].progress.copyWith(
          lastReadChapterId: chapterId,
          lastReadPage: page,
          lastReadAt: DateTime.now(),
        ),
      );
      _saveLibraryToDisk();
      notifyListeners();
    }
  }

  /// [Suggested Addition] Easy toggle for user bookmark state
  void toggleBookmark(String seriesId) {
    final index = _library.indexWhere((m) => m.id == seriesId);
    if (index != -1) {
      final currentProgress = _library[index].progress;
      _library[index] = _library[index].copyWith(
        progress: currentProgress.copyWith(isBookmarked: !currentProgress.isBookmarked),
      );
      _saveLibraryToDisk();
      notifyListeners();
    }
  }

  /// [Suggested Addition] Easy toggle for user dynamic appreciation rating
  void toggleLiked(String seriesId) {
    final index = _library.indexWhere((m) => m.id == seriesId);
    if (index != -1) {
      final currentProgress = _library[index].progress;
      _library[index] = _library[index].copyWith(
        progress: currentProgress.copyWith(isLiked: !currentProgress.isLiked),
      );
      _saveLibraryToDisk();
      notifyListeners();
    }
  }
/// Completely removes a chapter from a given series
  void removeChapterFromSeries(String seriesId, String chapterId) {
    final index = _library.indexWhere((m) => m.id == seriesId);
    if (index != -1) {
      _library[index] = _library[index].removeChapter(chapterId);
      _saveLibraryToDisk();
      notifyListeners();
    }
  }

  /// Changes a chapter's display number and re-sorts the list
  void updateChapterNumber(String seriesId, String chapterId, double newChapterNum) {
    final seriesIndex = _library.indexWhere((m) => m.id == seriesId);
    if (seriesIndex != -1) {
      MangaSeries series = _library[seriesIndex];
      final chapterIndex = series.chapters.indexWhere((c) => c.id == chapterId);
      
      if (chapterIndex != -1) {
        MangaChapter updatedChapter = series.chapters[chapterIndex].copyWith(
          chapterNumber: newChapterNum,
        );
        MangaSeries updatedSeries = series.updateChapter(updatedChapter).reorderChapters();
        _library[seriesIndex] = updatedSeries;
        _saveLibraryToDisk();
        notifyListeners();
      }
    }
  }

  /// Reorders the pages inside a specific chapter
  void reorderChapterPages(String seriesId, String chapterId, List<ChapterPage> reorderedPages) {
    final seriesIndex = _library.indexWhere((m) => m.id == seriesId);
    if (seriesIndex != -1) {
      MangaSeries series = _library[seriesIndex];
      final chapterIndex = series.chapters.indexWhere((c) => c.id == chapterId);
      
      if (chapterIndex != -1) {
        MangaChapter updatedChapter = series.chapters[chapterIndex].copyWith(
          pagesData: reorderedPages,
        );
        _library[seriesIndex] = series.updateChapter(updatedChapter);
        _saveLibraryToDisk();
        notifyListeners();
      }
    }
  }

  /// Changes or fixes the thumbnail cover for a series
  void updateSeriesCover(String seriesId, String newCoverPath) {
    final index = _library.indexWhere((m) => m.id == seriesId);
    if (index != -1) {
      _library[index] = _library[index].copyWith(coverPath: newCoverPath);
      _saveLibraryToDisk();
      notifyListeners();
    }
  }
  /// [Suggested Addition] Fetch next logical sequential page across chapter boundaries
  ChapterPage? getNextPage(String seriesId, String chapterId, String currentPageId) {
    final series = getSeriesByID(seriesId);
    if (series == null) return null;

    final chapterIndex = series.chapters.indexWhere((c) => c.id == chapterId);
    if (chapterIndex == -1) return null;

    final chapter = series.chapters[chapterIndex];
    final nextPage = chapter.getNextChapterPage(currentPageId);
    
    if (nextPage != null) {
      return nextPage;
    } else {
      // End of chapter reached! Try moving to page 1 of the following chapter
      if (chapterIndex < series.chapters.length - 1) {
        final nextChapter = series.chapters[chapterIndex + 1];
        if (nextChapter.pagesData.isNotEmpty) {
          return nextChapter.pagesData.first;
        }
      }
    }
    return null;
  }

  void _saveLibraryToDisk() {
    final List<Map<String, dynamic>> jsonList = _library
        .map((series) => series.toJson())
        .toList();

    final String serializedString = jsonEncode(jsonList);
    debugPrint("SAVING TO DISK: $serializedString");
    _box.put('library', serializedString);
  }
}