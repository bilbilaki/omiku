import 'package:flutter/material.dart';
import 'package:omiku/models/manga_panel.dart';
import 'package:uuid/uuid.dart';

// --- ChapterPage modifications (pageId in constructor, toJson, fromJson, copyWith) ---
class ChapterPage {
  final String seriesId;
  final String chapterId;
  final String pageId;
  final int pageNumber;
  final String pageFilePath;
   List<MangaPanel> panelsData; // This holds the detected panels

  ChapterPage({
    required this.chapterId,
    required this.pageNumber,
    required this.panelsData,
    required this.seriesId,
    required this.pageFilePath,
    String? pageId, // Allow pageId to be passed for deserialization
  }) : pageId = pageId ?? Uuid().v4(); // Use provided ID or generate a new one

  // Added copyWith method for ChapterPage
  ChapterPage copyWith({
    String? seriesId,
    String? chapterId,
    String? pageId,
    int? pageNumber,
    String? pageFilePath,
    List<MangaPanel>? panelsData,
  }) {
    return ChapterPage(
      seriesId: seriesId ?? this.seriesId,
      chapterId: chapterId ?? this.chapterId,
      pageId: pageId ?? this.pageId,
      pageNumber: pageNumber ?? this.pageNumber,
      pageFilePath: pageFilePath ?? this.pageFilePath,
      panelsData: panelsData ?? this.panelsData,
    );
  }

  // Added toJson method for ChapterPage
  Map<String, dynamic> toJson() {
    return {
      'seriesId': seriesId,
      'chapterId': chapterId,
      'pageId': pageId,
      'pageNumber': pageNumber,
      'pageFilePath': pageFilePath,
      'panelsData': panelsData.map((x) => x.toJson()).toList(),
    };
  }

  // Added fromJson factory for ChapterPage
  factory ChapterPage.fromJson(Map<String, dynamic> json) {
    return ChapterPage(
      seriesId: json['seriesId'] as String,
      chapterId: json['chapterId'] as String,
      pageId: json['pageId'] as String, // Retrieve pageId from JSON
      pageNumber: json['pageNumber'] as int,
      pageFilePath: json['pageFilePath'] as String,
      panelsData: (json['panelsData'] as List<dynamic>?)
              ?.map((x) => MangaPanel.fromJson(x as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

// --- MangaChapter modifications (addPage, updatePage, copyWith, toJson, fromJson) ---
class MangaChapter {
  final String id;
  final String title;
  final double chapterNumber; // double handles chapter 1.5, 2.1, etc.
  final String pathToChapterData; // Local directory path or API URL
  final int totalPages;
  final List<ChapterPage> pagesData; // This is the list of ChapterPage objects

  MangaChapter({
    required this.id,
    required this.title,
    required this.chapterNumber,
    required this.pathToChapterData,
    required this.totalPages,
    required this.pagesData,
  });

  ChapterPage? getNextChapterPage(String pageId) {
    final currentIndex = pagesData.indexWhere((chp) => chp.pageId == pageId);
    if (currentIndex != -1 && currentIndex < pagesData.length - 1) {
      return pagesData[currentIndex + 1]; // Assumes list is sorted ascending
    }
    return null;
  }

  // Renamed from `addChapter` to `addPage` and returns MangaChapter
  MangaChapter addPage(ChapterPage newChapterPage) {
    final updatedPages = List<ChapterPage>.from(pagesData)..add(newChapterPage);
    // Optional: Sort pages automatically by page number
    updatedPages.sort((a, b) => a.pageNumber.compareTo(b.pageNumber));
    return copyWith(pagesData: updatedPages, totalPages: updatedPages.length);
  }

  // Added method to update a specific page in the chapter
  MangaChapter updatePage(ChapterPage updatedPage) {
    final List<ChapterPage> newPagesData = List.from(pagesData);
    final int index = newPagesData.indexWhere((page) => page.pageId == updatedPage.pageId);
    if (index != -1) {
      newPagesData[index] = updatedPage;
      // Re-sort to maintain order, although pageNumber should keep them sorted
      newPagesData.sort((a, b) => a.pageNumber.compareTo(b.pageNumber));
    } else {
      debugPrint("Warning: Page with ID ${updatedPage.pageId} not found in chapter ${id} for update.");
    }
    return copyWith(pagesData: newPagesData, totalPages: newPagesData.length);
  }

  MangaChapter copyWith({
    String? id,
    String? title,
    double? chapterNumber,
    String? pathToChapterData,
    int? totalPages,
    List<ChapterPage>? pagesData, // Corrected parameter name
  }) {
    return MangaChapter(
      id: id ?? this.id,
      title: title ?? this.title,
      chapterNumber: chapterNumber ?? this.chapterNumber,
      pathToChapterData: pathToChapterData ?? this.pathToChapterData,
      totalPages: totalPages ?? this.totalPages,
      pagesData: pagesData ?? this.pagesData, // Corrected from `idsPagesData`
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'chapterNumber': chapterNumber,
      'pathToChapterData': pathToChapterData,
      'totalPages': totalPages,
      'pagesData': pagesData.map((p) => p.toJson()).toList(), // Corrected key and serialization
    };
  }

  factory MangaChapter.fromJson(Map<String, dynamic> json) {
    return MangaChapter(
      id: json['id'] as String,
      title: json['title'] as String,
      chapterNumber: (json['chapterNumber'] as num).toDouble(),
      pathToChapterData: json['pathToChapterData'] as String,
      totalPages: json['totalPages'] as int,
      pagesData: (json['pagesData'] as List<dynamic>?) // Corrected key and deserialization
              ?.map((x) => ChapterPage.fromJson(x as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
// --- UserProgress (no changes, but included for completeness) ---
class UserProgress {
  final bool isBookmarked;
  final bool isLiked; // Bool rating system as requested
  final String? lastReadChapterId;
  final int lastReadPage;
  final DateTime? lastReadAt;

  UserProgress({
    this.isBookmarked = false,
    this.isLiked = false,
    this.lastReadChapterId,
    this.lastReadPage = 0,
    this.lastReadAt,
  });

  UserProgress copyWith({
    bool? isBookmarked,
    bool? isLiked,
    String? lastReadChapterId,
    int? lastReadPage,
    DateTime? lastReadAt,
  }) {
    return UserProgress(
      isBookmarked: isBookmarked ?? this.isBookmarked,
      isLiked: isLiked ?? this.isLiked,
      lastReadChapterId: lastReadChapterId ?? this.lastReadChapterId,
      lastReadPage: lastReadPage ?? this.lastReadPage,
      lastReadAt: lastReadAt ?? this.lastReadAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isBookmarked': isBookmarked,
      'isLiked': isLiked,
      'lastReadChapterId': lastReadChapterId,
      'lastReadPage': lastReadPage,
      'lastReadAt': lastReadAt?.toIso8601String(),
    };
  }

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      isBookmarked: json['isBookmarked'] as bool? ?? false,
      isLiked: json['isLiked'] as bool? ?? false,
      lastReadChapterId: json['lastReadChapterId'] as String?,
      lastReadPage: json['lastReadPage'] as int? ?? 0,
      lastReadAt: json['lastReadAt'] != null
          ? DateTime.parse(json['lastReadAt'] as String)
          : null,
    );
  }
}

// --- MangaSeries modifications (addChapter, updateChapter, copyWith, toJson, fromJson) ---
class MangaSeries {
  final String id;
  final String title;
  final String coverPath;
  final String author;
  final String description;
  final List<MangaChapter> chapters;
  final UserProgress progress;

  MangaSeries({
    required this.id,
    required this.title,
    required this.coverPath,
    this.author = 'Unknown',
    this.description = '',
    this.chapters = const [],
    UserProgress? progress,
  }) : progress = progress ?? UserProgress();

  // Helper method to look ahead for the next chapter
  MangaChapter? getNextChapter(String currentChapterId) {
    final currentIndex = chapters.indexWhere((ch) => ch.id == currentChapterId);
    if (currentIndex != -1 && currentIndex < chapters.length - 1) {
      return chapters[currentIndex + 1]; // Assumes list is sorted ascending
    }
    return null;
  }

  // Mutator helper required by user
  MangaSeries addChapter(MangaChapter newChapter) {
    final updatedChapters = List<MangaChapter>.from(chapters)..add(newChapter);
    // Optional: Sort chapters automatically by chapter number
    updatedChapters.sort((a, b) => a.chapterNumber.compareTo(b.chapterNumber));
    return copyWith(chapters: updatedChapters);
  }

  // Added method to update a specific chapter in the series
  MangaSeries updateChapter(MangaChapter updatedChapter) {
    final List<MangaChapter> newChapters = List.from(chapters);
    final int index = newChapters.indexWhere((chapter) => chapter.id == updatedChapter.id);
    if (index != -1) {
      newChapters[index] = updatedChapter;
      // Re-sort to maintain order if chapterNumber changed (though it shouldn't for update)
      newChapters.sort((a, b) => a.chapterNumber.compareTo(b.chapterNumber));
    } else {
      debugPrint("Warning: Chapter with ID ${updatedChapter.id} not found in series ${id} for update.");
    }
    return copyWith(chapters: newChapters);
  }

  MangaSeries copyWith({
    String? id,
    String? title,
    String? coverPath,
    String? author,
    String? description,
    List<MangaChapter>? chapters,
    UserProgress? progress,
  }) {
    return MangaSeries(
      id: id ?? this.id,
      title: title ?? this.title,
      coverPath: coverPath ?? this.coverPath,
      author: author ?? this.author,
      description: description ?? this.description,
      chapters: chapters ?? this.chapters,
      progress: progress ?? this.progress,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'coverPath': coverPath,
      'author': author,
      'description': description,
      'chapters': chapters.map((x) => x.toJson()).toList(),
      'progress': progress.toJson(),
    };
  }

  factory MangaSeries.fromJson(Map<String, dynamic> json) {
    return MangaSeries(
      id: json['id'] as String,
      title: json['title'] as String,
      coverPath: json['coverPath'] as String,
      author: json['author'] as String? ?? 'Unknown',
      description: json['description'] as String? ?? '',
      chapters:
          (json['chapters'] as List<dynamic>?)
              ?.map((x) => MangaChapter.fromJson(x as Map<String, dynamic>))
              .toList() ??
          [],
      progress: json['progress'] != null
          ? UserProgress.fromJson(json['progress'] as Map<String, dynamic>)
          : UserProgress(),
    );
  }
}