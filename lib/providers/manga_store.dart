import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:omiku/models/manga_series.dart';
import 'package:omiku/models/manga_panel.dart'; // Ensure MangaPanel is imported

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
    // Load Dark Mode Preference
    _darkMode = _box.get('darkMode', defaultValue: false);

    // Load Manga Library List
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
    
    notifyListeners(); // Refresh UI after loading data
  }

  /// 2. Mutation actions that persist automatically

  void toggleDarkMode() {
    _darkMode = !_darkMode;
    _box.put('darkMode', _darkMode); // Sync to disk
    notifyListeners();
  }

  void addMangaSeries(MangaSeries series) {
    _library.add(series);
    _saveLibraryToDisk();
    notifyListeners();
  }

  void addChapterToSeries(String seriesId, MangaChapter chapter) {
    final index = _library.indexWhere((m) => m.id == seriesId);
    if (index != -1) {
      // MangaSeries.addChapter returns a new MangaSeries instance
      _library[index] = _library[index].addChapter(chapter); 
      _saveLibraryToDisk();
      notifyListeners();
    } else {
      debugPrint("Series with ID $seriesId not found for adding chapter.");
    }
  }

  // New method to update panels for a specific page
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
        final int pageIndex = chapter.pagesData.indexWhere((p) => p.pageNumber.toString() == pageId);
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

void _saveLibraryToDisk() {
  final List<Map<String, dynamic>> jsonList = 
      _library.map((series) => series.toJson()).toList();
  
  final String serializedString = jsonEncode(jsonList);
  
  // DEBUG LOG: Inspect if panels are actually present here right before saving
  debugPrint("SAVING TO DISK: $serializedString"); 
  
  _box.put('library', serializedString);
}}