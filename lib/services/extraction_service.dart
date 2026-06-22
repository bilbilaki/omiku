import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart' hide MetaData;
import 'package:omiku/extractor/ffibindings.dart';
import 'package:omiku/main.dart';
import 'package:omiku/models/models.dart';
import 'package:omiku/services/panel_detector_service.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

// import 'package:uuid/uuid.dart'; // Already imported above
int onToppedId = 0;
int onToppedChId = 0;
String onToppedCover = '';

class ExtractionService {
  final GoExtractor _extractor = GoExtractor();
  ExtractionService();

  /// Handles processing a file archive, passing sandbox paths to Go,
  /// and building a fully mapped MangaSeries model out of the results.
  Future<void> processArchive(
    File archiveFile,
    String appStorageDir,
    BuildContext context,
  ) async {
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
          await _mapSubfoldersToChapters(seriesId, nestedPdfs, context),
        ); // Pass seriesId
      }
      if (await nestedEpubs.exists()) {
        extractedChapters.addAll(
          await _mapSubfoldersToChapters(seriesId, nestedEpubs, context),
        ); // Pass seriesId
      }

      // If no subfolders exist, it was a standalone book (.cbz/.pdf/.epub)
      if (extractedChapters.isEmpty) {
        final String chapterId = const Uuid().v4();
        List<ChapterPage> pages = await _getChapterPages(
          seriesId,
          chapterId,
          targetDirectory.path,
        ); // Get pages
        MangaChapter mc = MangaChapter();
        mc.chapterId = chapterId;
        mc.seriesId = seriesId;
        mc.title = p.basenameWithoutExtension(archiveFile.path);
        mc.chapterNumber = 1.0;
        mc.pathToChapterData = expectedFinalPath;
        mc.totalPages = pages.length;

        mc.pages.addAll(pages);
        await db.put<MangaChapter>(mc);
        await db.saveChapterWithPages(mc, pages);
        onToppedChId = mc.id;

        extractedChapters.add(mc);
      }

      // 4. Register new book profile into your Hive Provider storage state
      if (extractedChapters.isNotEmpty) {
        IsarUserProgress pp = IsarUserProgress();
        pp.isBookmarked = false;
        pp.isLiked = false;
        pp.lastReadAt = DateTime(0);
        pp.lastReadChapterId = '';
        pp.lastReadPage = 0;
        MetaData? md = MetaData();
        md.title = p.basenameWithoutExtension(archiveFile.path);
        md.backgrounds = [];
        md.covers = [];
        md.credits = null;
        md.genres = [];
        md.malAlterTiles = null;
        md.malMainPic = null;
        md.malRecommand = null;
        md.malSeriesDetail = null;
        md.malStudio = null;
        md.mangaCoverImage = null;
        md.mangaData = null;
        md.mangaMedia = null;
        md.mangaTitles = null;
        md.movieDetail = null;
        md.tags = [];
        MangaSeries ms = MangaSeries();
        ms.metadata = md;
        ms.seriesId = seriesId;
        ms.title = p.basenameWithoutExtension(archiveFile.path);
        ms.coverPath = _findFirstAvailablePage(
          extractedChapters.first.pathToChapterData,
        );

        ms.author = 'unknown';
        ms.description = 'still no discription exist';
        ms.progress = pp;
        ms.chapters.addAll(extractedChapters);
        await db.saveMangaWithChapters(ms, extractedChapters);

        await db.put<MangaSeries>(ms);
        final newSeries = ms;
        onToppedCover = ms.coverPath;
        onToppedId = ms.id;

        debugPrint("Successfully added ${newSeries.title} to storage!");
      }
    } catch (e) {
      debugPrint("Error handling extraction routine: $e");
      rethrow;
    }
  }

  Future<void> extractSeries(
    File archiveFile,
    String appStorageDir,
    BuildContext context,
  ) async {
    // 1. Enforce App-Sandbox output target location
    // This gives your native code explicit permission to write locally
    final String extractionRoot = p.join(appStorageDir, 'ExtractedMedia');
    // Create a unique series ID and directory name
    final String seriesId = const Uuid().v4();
    final String expectedFinalPath = p.join(extractionRoot, seriesId);
    debugPrint("Triggering Go Extraction to sandbox path: $expectedFinalPath");

    try {
      // 2. Fire Go extractor stream listener
      final Stream<String> logStream = _extractor.autoExtractSeries(
        archiveFile.path,
        extractionRoot,
        seriesId,
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
      final df = Directory(expectedFinalPath).listSync();
      for (final ft in df) {
        if (ft is Directory) {
          if (p.basename(ft.path).startsWith("ch-")) {
            extractedChapters.addAll(
              await _mapSubfoldersToChapters(seriesId, ft, context),
            );
          }
        }
      }
      // final nestedPdfs = Directory(p.join(expectedFinalPath, 'extracted-pdfs'));
      // final nestedEpubs = Directory(
      //   p.join(expectedFinalPath, 'extracted-epubs'),
      // );

      // if (await nestedPdfs.exists()) {
      //   extractedChapters.addAll(
      //     await _mapSubfoldersToChapters(seriesId, nestedPdfs, context),
      //   ); // Pass seriesId
      // }
      // if (await nestedEpubs.exists()) {
      //   extractedChapters.addAll(
      //     await _mapSubfoldersToChapters(seriesId, nestedEpubs, context),
      //   ); // Pass seriesId
      // }

      // If no subfolders exist, it was a standalone book (.cbz/.pdf/.epub)
      if (extractedChapters.isEmpty) {
        final String chapterId = const Uuid().v4();
        List<ChapterPage> pages = await _getChapterPages(
          seriesId,
          chapterId,
          targetDirectory.path,
        ); // Get pages
        MangaChapter mc = MangaChapter();
        mc.chapterId = chapterId;
        mc.seriesId = seriesId;
        mc.title = p.basenameWithoutExtension(archiveFile.path);
        mc.chapterNumber = 1.0;
        mc.pathToChapterData = expectedFinalPath;
        mc.totalPages = pages.length;

        mc.pages.addAll(pages);
        await db.put<MangaChapter>(mc);
        await db.saveChapterWithPages(mc, pages);
        onToppedChId = mc.id;

        extractedChapters.add(mc);
      }

      // 4. Register new book profile into your Hive Provider storage state
      if (extractedChapters.isNotEmpty) {
        IsarUserProgress pp = IsarUserProgress();
        pp.isBookmarked = false;
        pp.isLiked = false;
        pp.lastReadAt = DateTime(0);
        pp.lastReadChapterId = '';
        pp.lastReadPage = 0;
  MetaData? md = MetaData();
        md.title = p.basenameWithoutExtension(archiveFile.path);
        md.backgrounds = [];
        md.covers = [];
        md.credits = null;
        md.genres = [];
        md.malAlterTiles = null;
        md.malMainPic = null;
        md.malRecommand = null;
        md.malSeriesDetail = null;
        md.malStudio = null;
        md.mangaCoverImage = null;
        md.mangaData = null;
        md.mangaMedia = null;
        md.mangaTitles = null;
        md.movieDetail = null;
        md.tags = [];
                MangaSeries ms = MangaSeries();
        ms.metadata = md;
        ms.seriesId = seriesId;
        ms.title = p.basenameWithoutExtension(archiveFile.path);
        ms.coverPath = _findFirstAvailablePage(
          extractedChapters.first.pathToChapterData,
        );

        ms.author = 'unknown';
        ms.description = 'still no discription exist';
        ms.progress = pp;
        ms.chapters.addAll(extractedChapters);
        await db.saveMangaWithChapters(ms, extractedChapters);

        await db.put<MangaSeries>(ms);
        final newSeries = ms;
        onToppedCover = ms.coverPath;
        onToppedId = ms.id;

        debugPrint("Successfully added ${newSeries.title} to storage!");
      }
    } catch (e) {
      debugPrint("Error handling extraction routine: $e");
      rethrow;
    }
  }

  Future<void> extractSinglePathToPath(
    File archiveFile,
    String appStorageDir,
    int chapternum,
    BuildContext context,
  ) async {
    // 1. Enforce App-Sandbox output target location
    // This gives your native code explicit permission to write locally
    final exti = p.extension(archiveFile.path);
    final String extractionRoot = p.join(appStorageDir, 'ExtractedMedia');
    // Create a unique series ID and directory name
    final String seriesId = const Uuid().v4();
    final String expectedFinalPath = p.join(
      extractionRoot,
      seriesId,
      "ch-$chapternum",
    );
    debugPrint("Triggering Go Extraction to sandbox path: $expectedFinalPath");

    try {
      Stream<String> logStream;
      // 2. Fire Go extractor stream listener
      if (exti.toLowerCase() == ".pdf") {
        logStream = _extractor.extractPdf(archiveFile.path, extractionRoot);
      } else if (exti.toLowerCase() == ".cbz") {
        logStream = _extractor.extractCbz(archiveFile.path, extractionRoot);
      } else if (exti.toLowerCase() == ".epub") {
        logStream = _extractor.extractEpub(archiveFile.path, extractionRoot);
      } else if (exti.toLowerCase() == ".tar") {
        logStream = _extractor.extractTar(archiveFile.path, extractionRoot);
      } else if (exti.toLowerCase() == ".rar" ||
          exti.toLowerCase() == ".7z" ||
          exti.toLowerCase() == ".zip") {
        logStream = _extractor.extractArchiveS(
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
            debugPrint(
              "Go extraction signaled finish. Exiting log stream loop.",
            );
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
        // final df = Directory(expectedFinalPath).listSync();
        // for (final ft in df) {
        //   if (ft is Directory) {
        //     if (p.basename(ft.path).startsWith("ch-")){
        //   extractedChapters.addAll(
        //     await _mapSubfoldersToChapters(seriesId, ft, context),
        //   );
        //     }
        //   }
        // }
        // // final nestedPdfs = Directory(p.join(expectedFinalPath, 'extracted-pdfs'));
        // final nestedEpubs = Directory(
        //   p.join(expectedFinalPath, 'extracted-epubs'),
        // );

        // if (await nestedPdfs.exists()) {
        //   extractedChapters.addAll(
        //     await _mapSubfoldersToChapters(seriesId, nestedPdfs, context),
        //   ); // Pass seriesId
        // }
        // if (await nestedEpubs.exists()) {
        //   extractedChapters.addAll(
        //     await _mapSubfoldersToChapters(seriesId, nestedEpubs, context),
        //   ); // Pass seriesId
        // }

        // If no subfolders exist, it was a standalone book (.cbz/.pdf/.epub)
        // if (extractedChapters.isEmpty) {
        final String chapterId = const Uuid().v4();
        List<ChapterPage> pages = await _getChapterPages(
          seriesId,
          chapterId,
          targetDirectory.path,
        ); // Get pages
        MangaChapter mc = MangaChapter();
        mc.chapterId = chapterId;
        mc.seriesId = seriesId;
        mc.title = p.basenameWithoutExtension(archiveFile.path);
        mc.chapterNumber = chapternum.toDouble();
        mc.pathToChapterData = expectedFinalPath;
        mc.totalPages = pages.length;

        mc.pages.addAll(pages);
        await db.put<MangaChapter>(mc);
        await db.saveChapterWithPages(mc, pages);
        onToppedChId = mc.id;

        extractedChapters.add(mc);
        //}

        // 4. Register new book profile into your Hive Provider storage state
        if (extractedChapters.isNotEmpty) {
          IsarUserProgress pp = IsarUserProgress();
          pp.isBookmarked = false;
          pp.isLiked = false;
          pp.lastReadAt = DateTime(0);
          pp.lastReadChapterId = '';
          pp.lastReadPage = 0;
  MetaData? md = MetaData();
        md.title = p.basenameWithoutExtension(archiveFile.path);
        md.backgrounds = [];
        md.covers = [];
        md.credits = null;
        md.genres = [];
        md.malAlterTiles = null;
        md.malMainPic = null;
        md.malRecommand = null;
        md.malSeriesDetail = null;
        md.malStudio = null;
        md.mangaCoverImage = null;
        md.mangaData = null;
        md.mangaMedia = null;
        md.mangaTitles = null;
        md.movieDetail = null;
        md.tags = [];          MangaSeries ms = MangaSeries();
          ms.metadata = md;
          ms.seriesId = seriesId;
          ms.title = p.basenameWithoutExtension(archiveFile.path);
          ms.coverPath = _findFirstAvailablePage(
            extractedChapters.first.pathToChapterData,
          );

          ms.author = 'unknown';
          ms.description = 'still no discription exist';
          ms.progress = pp;
          ms.chapters.addAll(extractedChapters);
          await db.saveMangaWithChapters(ms, extractedChapters);

          await db.put<MangaSeries>(ms);
          final newSeries = ms;
          onToppedCover = ms.coverPath;
          onToppedId = ms.id;

          debugPrint("Successfully added ${newSeries.title} to storage!");
        }
      }
    } catch (e) {
      debugPrint("Error handling extraction routine: $e");
      rethrow;
    }
  }

  /// Generates a list of ChapterPage objects for a given chapter directory.
  Future<List<ChapterPage>> _getChapterPages(
    String seriesId,
    String chapterId,
    String chapterDirPath,
  ) async {
    final List<ChapterPage> pages = [];
    final Directory dir = Directory(chapterDirPath);

    if (!await dir.exists()) {
      debugPrint("⚠️ Chapter directory does not exist: $chapterDirPath");
      return pages;
    }

    final panelDetectionService = PanelDetectionService();
    // Ensure the YOLO model is fully loaded before running detection loops
    await panelDetectionService.ensureModelLoaded();

    // 1. Fetch and filter image files
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

    // 2. Sort naturally by extracting digit sequences
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
      return nameA.compareTo(nameB);
    });

    // 3. Process pages sequentially through YOLO
    const uuid = Uuid();
    for (int i = 0; i < imageFiles.length; i++) {
      final String chapterPageId = uuid.v4();

      // Runs on-device machine learning inference
      List<MangaPanel>? panels = await panelDetectionService.pickAndDetect(
        imageFiles[i],
      );

      // Map panels to URI-encoded JSON strings to safely match your models.dart getter
      if (panels != null && panels != []) {
        final List<String> serializedPanels = panels!.map((pan) {
          return Uri.encodeComponent(jsonEncode(pan.toJson()));
        }).toList();

        // Build the non-persisted database record
        final ChapterPage chapterPage = ChapterPage()
          ..pageId = chapterPageId
          ..chapterId = chapterId
          ..pageNumber = i + 1
          ..pageFilePath = imageFiles[i].path
          ..panelRawJson = serializedPanels;

        pages.add(chapterPage);
      }
    }

    return pages;
  }

  /// Scans structural inner outputs generated by your Go code loop
  Future<List<MangaChapter>> _mapSubfoldersToChapters(
    String seriesId,
    Directory parentDir,
    BuildContext context,
  ) async {
    List<MangaChapter> chapters = [];
    final List<FileSystemEntity> entities = await parentDir.list().toList();

    double chapterIndex = 1.0;
    for (var entity in entities) {
      if (entity is Directory && entity.path.endsWith('-extracted') ||
          entity is Directory && entity.path.startsWith('ch-')) {
        String chapterId = const Uuid().v4(); // Generate chapter ID here
        List<ChapterPage> pages = await _getChapterPages(
          seriesId,
          chapterId,
          entity.path,
        ); // Get pag
        MangaChapter ch = MangaChapter();
        ch.chapterNumber = chapterIndex++;
        ch.pathToChapterData = entity.path;
        ch.totalPages = pages.length;

        ch.chapterId = chapterId;
        ch.pages.addAll(pages);
        await db.saveChapterWithPages(ch, pages);
        await db.put<MangaChapter>(ch);

        chapters.add(ch);
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
