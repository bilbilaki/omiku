import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:omiku/models/manga_panel.dart';
import 'package:omiku/models/manga_series.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';
import 'package:uuid/uuid.dart'; // For panel IDs

class PanelDetectionService {
  YOLO? _yolo;
  bool _isModelLoaded = false;
  bool _isLoadingModel = false;

  PanelDetectionService() {
    _loadYOLOModel();
  }

  Future<void> _loadYOLOModel() async {
    if (_isLoadingModel || _isModelLoaded) return;
    _isLoadingModel = true;

    try {
      debugPrint("Attempting to load YOLO model...");
      _yolo = YOLO(
        modelPath: 'assets/models/manga_panel_detector_int8.tflite',
        task: YOLOTask.detect,
      );
      await _yolo!.loadModel();
      _isModelLoaded = true;
      debugPrint("YOLO model loaded successfully.");
    } catch (e) {
      debugPrint("Error loading YOLO model for PanelDetectionService: $e");
    } finally {
      _isLoadingModel = false;
    }
  }

  // Exposed method to check model status
  bool get isModelReady => _isModelLoaded;

  // This method will take a ChapterPage and return an updated one with panels
  Future<ChapterPage> detectPanelsForPage(ChapterPage chapterPage, {bool isLTR = false}) async {
    if (!_isModelLoaded) {
      debugPrint("YOLO model not loaded. Attempting to load...");
      await _loadYOLOModel();
      if (!_isModelLoaded) {
        debugPrint("YOLO model failed to load. Cannot detect panels for page ${chapterPage.pageFilePath}.");
        return chapterPage.copyWith(panelsData: []); // Return page without panels
      }
    }

    final File imageFile = File(chapterPage.pageFilePath);
    if (!await imageFile.exists()) {
      debugPrint("Image file not found for path: ${chapterPage.pageFilePath}");
      return chapterPage.copyWith(panelsData: []);
    }

    try {
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final decodedImage = await decodeImageFromList(imageBytes);
      final double originalWidth = decodedImage.width.toDouble();
      final double originalHeight = decodedImage.height.toDouble();

      final Map<String, dynamic> response = await _yolo!.predict(
        imageBytes,
        confidenceThreshold: 0.70,
      );

      List<dynamic> boxes = response['boxes'] ?? response['results'] ?? [];
      if (boxes.isEmpty && response.values.isNotEmpty) {
        final firstList = response.values.firstWhere(
          (v) => v is List,
          orElse: () => null,
        );
        if (firstList != null) boxes = firstList;
      }
      debugPrint("Detected ${boxes.length} raw predictions for ${chapterPage.pageFilePath}");

      List<MangaPanel> localPanels = [];

      for (var prediction in boxes) {
        final Map<String, dynamic> detectMap = Map<String, dynamic>.from(
          prediction,
        );

        double boxWidth = 0.0;
        double boxHeight = 0.0;
        double centerX = 0.0;
        double centerY = 0.0;

        if (detectMap.containsKey('x') && detectMap.containsKey('width')) {
          // Format A: Center representation (x, y, width, height where x,y is top-left)
          // The YOLODemo had `+ (boxWidth / 2)` but YOLO's 'x' is usually top-left.
          // MangaPanel expects center. So need to convert.
          boxWidth = (detectMap['width'] ?? 0.0).toDouble();
          boxHeight = (detectMap['height'] ?? 0.0).toDouble();
          centerX = (detectMap['x'] ?? 0.0).toDouble() + (boxWidth / 2); // Convert top-left to center
          centerY = (detectMap['y'] ?? 0.0).toDouble() + (boxHeight / 2); // Convert top-left to center
        } else if (detectMap.containsKey('x1') || detectMap.containsKey('box')) {
          // Format B: Min/Max Box points representation [x1, y1, x2, y2]
          final double x1 = (detectMap['x1'] ?? detectMap['box']?[0] ?? 0.0).toDouble();
          final double y1 = (detectMap['y1'] ?? detectMap['box']?[1] ?? 0.0).toDouble();
          final double x2 = (detectMap['x2'] ?? detectMap['box']?[2] ?? 0.0).toDouble();
          final double y2 = (detectMap['y2'] ?? detectMap['box']?[3] ?? 0.0).toDouble();

          boxWidth = (x2 - x1).abs(); // Corrected calculation
          boxHeight = (y2 - y1).abs(); // Corrected calculation
          centerX = x1 + (boxWidth / 2);
          centerY = y1 + (boxHeight / 2);
        }

        localPanels.add(
          MangaPanel(
            id: const Uuid().v4(), // Generate unique ID for each panel
            x: centerX,
            y: centerY,
            width: boxWidth,
            height: boxHeight,
            scale: 1.0,
          ),
        );
      }

      // Sort panels using the heuristic
      _sortPanels(localPanels, isLTR, originalHeight);

      return chapterPage.copyWith(panelsData: localPanels);

    } catch (e, stacktrace) {
      debugPrint("Error running panel detection for page ${chapterPage.pageFilePath}: $e");
      debugPrint("Stacktrace: $stacktrace");
      return chapterPage.copyWith(panelsData: []); // Return page without panels on error
    }
  }

  // Extracted sorting logic
  void _sortPanels(List<MangaPanel> panels, bool isLTR, double originalImageHeight) {
    panels.sort((a, b) {
      // dynamically calculate row tolerance, e.g., 10% of image height
      // The original code used 150.0, which is a fixed pixel value.
      // Using a percentage of height makes it adaptive to different resolutions.
      const double rowToleranceFactor = 0.10; // 10% of image height
      final double rowTolerance = originalImageHeight * rowToleranceFactor; 

      if ((a.y - b.y).abs() > rowTolerance) {
        return a.y.compareTo(b.y); // Always Top-to-Bottom
      } else {
        // They are within the same row tolerance. Apply reading direction.
        if (isLTR) {
          return a.x.compareTo(b.x); // Western: Left-to-Right
        } else {
          return b.x.compareTo(a.x); // Manga: Right-to-Left
        }
      }
    });
  }
}