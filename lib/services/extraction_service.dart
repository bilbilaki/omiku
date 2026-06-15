import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:omiku/extractor/ffibindings.dart';
import 'package:omiku/models/manga_series.dart';
import 'package:omiku/providers/manga_store.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
// import 'package:uuid/uuid.dart'; // Already imported above

class ExtractionService {
  final GoExtractor _extractor = GoExtractor();
  final MangaStore _mangaStore;

  ExtractionService(this._mangaStore);

  /// Handles processing a file archive, passing sandbox paths to Go,
  /// and building a fully mapped MangaSeries model out of the results.
  Future<void> processArchive(File archiveFile, String appStorageDir) async {
    // 1. Enforce App-Sandbox output target location
    // This gives your native code explicit permission to write locally
    final String extractionRoot = p.join(appStorageDir, 'ExtractedMedia');

    // Create a unique series ID and directory name
    final String seriesId = const Uuid().v4();
    final String seriesFolderName = "${p.basename(archiveFile.path)}-extracted";
    final String expectedFinalPath = p.join(extractionRoot, seriesFolderName);

    debugPrint("Triggering Go Extraction to sandbox path: $expectedFinalPath");

    try {
      // 2. Fire Go extractor stream listener
      final Stream<String> logStream = _extractor.extractArchive(
        archiveFile.path,
        extractionRoot,
      );

      await for (final log in logStream) {
        debugPrint("[Go Native Log]: $log");

        // Handle explicit exceptions bubble up from the Go runtime
        if (log.startsWith("ERROR") || log.contains("failed")) {
          throw Exception("Native Extraction Failed: $log");
        }
        if (log.contains("finish")) {
    debugPrint("Go extraction signaled finish. Exiting log stream loop.");
    break; 
  }
      }

      // 3. Post-Extraction: Scan the output directory structure to build models
      final targetDirectory = Directory(expectedFinalPath);
      if (!await targetDirectory.exists()) {
        throw Exception(
          "Extraction completed but target folder does not exist.",
        );
      }

      // Check if it's a direct format (.cbz, single pdf/epub) or a container bundle
      List<MangaChapter> extractedChapters = [];

      final nestedPdfs = Directory(p.join(expectedFinalPath, 'extracted-pdfs'));
      final nestedEpubs = Directory(
        p.join(expectedFinalPath, 'extracted-epubs'),
      );

      if (await nestedPdfs.exists()) {
        extractedChapters.addAll(
          await _mapSubfoldersToChapters(seriesId, nestedPdfs),
        ); // Pass seriesId
      }
      if (await nestedEpubs.exists()) {
        extractedChapters.addAll(
          await _mapSubfoldersToChapters(seriesId, nestedEpubs),
        ); // Pass seriesId
      }

      // If no subfolders exist, it was a standalone book (.cbz/.pdf/.epub)
      if (extractedChapters.isEmpty) {
        final String chapterId = const Uuid().v4();
        final List<ChapterPage> pages = await _getChapterPages(
          seriesId,
          chapterId,
          targetDirectory.path,
        ); // Get pages
        extractedChapters.add(
          MangaChapter(
            id: chapterId, // Use generated chapterId
            title: p.basenameWithoutExtension(archiveFile.path),
            chapterNumber: 1.0,
            pathToChapterData: expectedFinalPath,
            totalPages:
                pages.length, // Set totalPages based on actual pages found
            pagesData: pages, // Pass the generated pages
          ),
        );
      }

      // 4. Register new book profile into your Hive Provider storage state
      if (extractedChapters.isNotEmpty) {
        final newSeries = MangaSeries(
          id: seriesId,
          title: p.basenameWithoutExtension(archiveFile.path),
          coverPath: _findFirstAvailablePage(
            extractedChapters.first.pathToChapterData,
          ),
          chapters: extractedChapters,
        );

        _mangaStore.addMangaSeries(newSeries);
        debugPrint("Successfully added ${newSeries.title} to storage!");
      }
    } catch (e) {
      debugPrint("Error handling extraction routine: $e");
      rethrow;
    }
  }

  /// New helper function: Generates a list of ChapterPage objects for a given chapter directory.
  Future<List<ChapterPage>> _getChapterPages(
    String seriesId,
    String chapterId,
    String chapterDirPath,
  ) async {
    final List<ChapterPage> pages = [];
    final Directory dir = Directory(chapterDirPath);
    if (!await dir.exists()) {
      return pages; // Return empty list if directory doesn't exist
    }

    // Get all image files in the directory
    final List<File> imageFiles = await dir
        .list(recursive: false)
        .where((entity) {
          final ext = p.extension(entity.path).toLowerCase();
          return entity is File &&
              (ext == '.png' ||
                  ext == '.jpg' ||
                  ext == '.jpeg' ||
                  ext == '.webp');
        })
        .cast<File>()
        .toList();
final RegExp numRegExp = RegExp(r'(\d+)');
   imageFiles.sort((a, b) {
  final String nameA = p.basenameWithoutExtension(a.path);
  final String nameB = p.basenameWithoutExtension(b.path);

  final matchA = numRegExp.firstMatch(nameA);
  final matchB = numRegExp.firstMatch(nameB);
      if (matchA != null && matchB != null) {
        final int numA = int.tryParse(matchA.group(1)!) ?? 0;
        final int numB = int.tryParse(matchB.group(1)!) ?? 0;
        if (numA != numB) return numA.compareTo(numB);
      }
      return nameA.compareTo(nameB); // Fallback to string comparison
    });

    for (int i = 0; i < imageFiles.length; i++) {
      pages.add(
        ChapterPage(
          seriesId: seriesId,
          chapterId: chapterId,
          pageNumber: i + 1, // Page numbers are 1-based
          pageFilePath: imageFiles[i].path,
          panelsData:
              [], // Panel data is empty for now, as no detection logic is provided
        ),
      );
    }
    return pages;
  }

  /// Scans structural inner outputs generated by your Go code loop
  Future<List<MangaChapter>> _mapSubfoldersToChapters(
    String seriesId,
    Directory parentDir,
  ) async {
    List<MangaChapter> chapters = [];
    final List<FileSystemEntity> entities = await parentDir.list().toList();

    double chapterIndex = 1.0;
    for (var entity in entities) {
      if (entity is Directory && entity.path.endsWith('-extracted')) {
        final String chapterId = const Uuid().v4(); // Generate chapter ID here
        final List<ChapterPage> pages = await _getChapterPages(
          seriesId,
          chapterId,
          entity.path,
        ); // Get pages
        chapters.add(
          MangaChapter(
            id: chapterId, // Use generated chapterId
            title: p.basename(entity.path).replaceAll('-extracted', ''),
            chapterNumber: chapterIndex++,
            pathToChapterData: entity.path,
            totalPages:
                pages.length, // Set totalPages based on actual pages found
            pagesData: pages, // Pass the generated pages
          ),
        );
      }
    }
    // Maintain sequential chapter listing order
    chapters.sort((a, b) => a.chapterNumber.compareTo(b.chapterNumber));
    return chapters;
  }

  /// Counts matching file system items to populate page total fields safely
  // This method is no longer strictly needed for totalPages if _getChapterPages is used,
  // but can be kept for other purposes or as a sanity check.
  // For consistency, totalPages is now derived from pages.length.
  Future<int> _countImagesInFolder(Directory dir) async {
    int count = 0;
    await for (final file in dir.list(recursive: false)) {
      final ext = p.extension(file.path).toLowerCase();
      if (ext == '.png' || ext == '.jpg' || ext == '.jpeg' || ext == '.webp') {
        count++;
      }
    }
    return count;
  }

  /// Extracts the very first visual slide to use as the Library cover art path
  String _findFirstAvailablePage(String folderPath) {
    try {
      final dir = Directory(folderPath);
      final files = dir.listSync().whereType<File>().toList();
      files.sort((a, b) => a.path.compareTo(b.path));
      return files.first.path;
    } catch (_) {
      return ''; // Fallback fallback if folder is unreadable
    }
  }
}
