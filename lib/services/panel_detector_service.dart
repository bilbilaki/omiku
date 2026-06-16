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
  File? selectedImage;
  //List<MangaPanel> detectedPanels = [];
  bool isLoading = false;
  double originalWidth = 0.0;
  double originalHeight = 0.0;
  bool isLTR = false;
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

  /// Ensure the model is fully loaded before detection
  Future<void> ensureModelLoaded() async {
    await Future.doWhile(() async {
      if (_isModelLoaded) return false; // Done
      if (!_isLoadingModel && _yolo == null) {
        _loadYOLOModel(); // Start loading if not already started
      }
      await Future.delayed(const Duration(milliseconds: 100));
      return !_isModelLoaded; // Continue waiting if not loaded
    });
  }

  // This method will take a ChapterPage and return an updated one with panels
  Future<List<MangaPanel>?> pickAndDetect(File image) async {
    if (_yolo == null || !_isModelLoaded) return null;
    List<MangaPanel>? localPanels = [];

    selectedImage = image;
    isLoading = true;

    try {
      final Uint8List imageBytes = await selectedImage!.readAsBytes();
      final decodedImage = await decodeImageFromList(imageBytes);
      originalWidth = decodedImage.width.toDouble();
      originalHeight = decodedImage.height.toDouble();
      final Map<String, dynamic> response = await _yolo!.predict(
        imageBytes,
        confidenceThreshold: 0.65,
      );

      // --- DIAGNOSTIC LOGGING ---
      // This prints the exact structure of your response to the debug console
      debugPrint("🔍 YOLO RAW RESPONSE KEYS: ${response.keys.toList()}");

      List<dynamic> boxes = response['boxes'] ?? response['results'] ?? [];
      if (boxes.isEmpty && response.values.isNotEmpty) {
        // If 'boxes' is empty, look for any list inside the response map
        final firstList = response.values.firstWhere(
          (v) => v is List,
          orElse: () => null,
        );
        if (firstList != null) boxes = firstList;
      }

      debugPrint("📦 FOUND ${boxes.length} RAW PREDICTIONS TO PARSE.");
      if (boxes.isNotEmpty) {
        debugPrint("📋 FIRST PREDICTION SAMPLE DATA: ${boxes.first}");
      }
      // --------------------------

      int indexCounter = 0;

      for (var prediction in boxes) {
        final Map<String, dynamic> detectMap = Map<String, dynamic>.from(
          prediction,
        );

        // Class index extraction fallback
        // 1. DYNAMIC COORDINATE EXTRACTOR
        // Standard YOLO plugins format coordinates either as centers (x, y, width, height)
        // or as bounding boxes (x1, y1, x2, y2).
        double boxWidth = 0.0;
        double boxHeight = 0.0;
        double centerX = 0.0;
        double centerY = 0.0;

        if (detectMap.containsKey('x') && detectMap.containsKey('width')) {
          // Format A: Center representation
          boxWidth = (detectMap['width'] ?? 0.0).toDouble();
          boxHeight = (detectMap['height'] ?? 0.0).toDouble();
          centerX = (detectMap['x'] ?? 0.0).toDouble() + (boxWidth / 2);
          centerY = (detectMap['y'] ?? 0.0).toDouble() + (boxHeight / 2);
        } else if (detectMap.containsKey('x1') ||
            detectMap.containsKey('box')) {
          // Format B: Min/Max Box points representation [x1, y1, x2, y2]
          final double x1 = (detectMap['x1'] ?? detectMap['box']?[0] ?? 0.0)
              .toDouble();
          final double y1 = (detectMap['y1'] ?? detectMap['box']?[1] ?? 0.0)
              .toDouble();
          final double x2 = (detectMap['x2'] ?? detectMap['box']?[2] ?? 0.0)
              .toDouble();
          final double y2 = (detectMap['y2'] ?? detectMap['box']?[3] ?? 0.0)
              .toDouble();

          boxWidth = (x2 - x1 / 1.5).abs();
          boxHeight = (y2 - y1 / 1.5).abs();
          centerX = x1 + ((x2 - x1).abs() / 2);
          centerY = y1 + ((y2 - y1).abs() / 2);
        }

        // 2. STAGE ACCUMULATION
        localPanels.add(
          MangaPanel(
            id: 'detected_$indexCounter',
            x: centerX,
            y: centerY,
            width: boxWidth,
            height: boxHeight,
            scale: 1.0,
          ),
        );
        indexCounter++;
      }

      // Japanese Manga Flow Heuristic Sort
      // Universal Comic Flow Heuristic Sort
      localPanels.sort((a, b) {
        // Tolerance to determine if panels belong to the same row.
        // 150.0 is your current baseline, but you might want to calculate
        // this dynamically later based on `originalHeight` to support different image resolutions.
        const double rowTolerance = 150.0;

        // Check if the vertical difference is greater than our tolerance.
        // If so, they are definitively on different rows.
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

      return localPanels;
    } catch (e, stacktrace) {
      debugPrint("Error running prediction: $e");
      debugPrint("Stacktrace: $stacktrace");
      return null;
    }
  }
}

// Extracted sorting logic
void _sortPanels(
  List<MangaPanel> panels,
  bool isLTR,
  double originalImageHeight,
) {
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
