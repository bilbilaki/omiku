import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:omiku/models/manga_panel.dart';
import 'package:omiku/models/panel_debug_painter.dart';
import 'package:omiku/providers/manga_store.dart';
import 'package:omiku/widgets/manga_reader.dart';
import 'package:provider/provider.dart';
import 'package:telegram_ios_ui_kit/telegram_ios_ui_kit.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Open a storage box specifically for app configurations/state
  await Hive.openBox('manga_store_box');
  final telegramTheme = TelegramThemeData.dark();

  runApp(
    ChangeNotifierProvider(
      create: (context) => MangaStore(),
      child: TelegramTheme(
        data: telegramTheme,
        child: MaterialApp(
          theme: telegramTheme.toThemeData(),
          debugShowCheckedModeBanner: false,
              home: SplashScreen(),
        ),
      ),
    ),
  );
}

class YOLODemo extends StatefulWidget {
  const YOLODemo({super.key});

  @override
  YOLODemoState createState() => YOLODemoState();
}

class YOLODemoState extends State<YOLODemo> {
  YOLO? yolo;
  File? selectedImage;
  List<MangaPanel> detectedPanels = [];
  bool isLoading = false;
  bool _isModelLoaded = false;
  double originalWidth = 0.0;
  double originalHeight = 0.0;
  bool isLTR = false;
  @override
  void initState() {
    super.initState();
    loadYOLO();
  }

  Future<void> loadYOLO() async {
    setState(() => isLoading = true);

    try {
      yolo = YOLO(
        modelPath: 'assets/models/manga_panel_detector_int8.tflite',
        task: YOLOTask.detect,
      );

      await yolo!.loadModel();
      setState(() {
        _isModelLoaded = true;
      });
    } catch (e) {
      debugPrint("Error loading YOLO model: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> pickAndDetect() async {
    if (yolo == null || !_isModelLoaded) return;

    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        selectedImage = File(image.path);
        isLoading = true;
        detectedPanels.clear();
      });

      try {
        final Uint8List imageBytes = await selectedImage!.readAsBytes();
        final decodedImage = await decodeImageFromList(imageBytes);
        originalWidth = decodedImage.width.toDouble();
        originalHeight = decodedImage.height.toDouble();
        final Map<String, dynamic> response = await yolo!.predict(
          imageBytes,
          confidenceThreshold: 0.70,
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

        List<MangaPanel> localPanels = [];
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

        setState(() {
          detectedPanels = localPanels;
        });
      } catch (e, stacktrace) {
        debugPrint("Error running prediction: $e");
        debugPrint("Stacktrace: $stacktrace");
      } finally {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('YOLO Quick Demo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Place this inside your Column child tree inside main.dart UI layout
            if (detectedPanels.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MangaReaderScreen(
                          detectedPanels: detectedPanels,
                          mangaImage: selectedImage!,
                        ),
                      ),
                    );
                  },
                  child: const Text('Open in Guided Manga Reader 📖'),
                ),
              ),
            if (selectedImage != null)
              Container(
                height: 300,
                margin: EdgeInsets.all(12),
                child: Stack(
                  children: [
                    Image.file(selectedImage!),

                    Positioned.fill(
                      child: CustomPaint(
                        painter: PanelDebugPainter(
                          detectedPanels,
                          originalWidth,
                          originalHeight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            SizedBox(height: 10),

            if (isLoading)
              CircularProgressIndicator()
            else
              Text(
                _isModelLoaded
                    ? 'Detected ${detectedPanels.length} Panels'
                    : 'Model Loading...',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),

            SizedBox(height: 10),

            ElevatedButton.icon(
              onPressed: (_isModelLoaded && !isLoading) ? pickAndDetect : null,
              icon: Icon(Icons.photo_library),
              label: Text('Pick Image & Detect'),
            ),

            SizedBox(height: 10),
            SwitchListTile(
              title: Text(
                isLTR ? 'Western Format (LTR)' : 'Manga Format (RTL)',
              ),
              subtitle: const Text('Toggles reading direction sorting'),
              value: isLTR,
              onChanged: (bool value) {
                setState(() {
                  isLTR = value;
                  // You don't need to re-run YOLO, just re-sort the existing panels!
                  if (detectedPanels.isNotEmpty) {
                    // Temporarily store, clear, and re-add to trigger the sorting logic
                    // Alternatively, extract the sort logic into its own reusable function.
                  }
                });
              },
            ),
            SizedBox(height: 10),

            Expanded(
              child: ListView.builder(
                itemCount: detectedPanels.length,
                itemBuilder: (context, index) {
                  final panel = detectedPanels[index];
                  return ListTile(
                    leading: CircleAvatar(child: Text('${index + 1}')),
                    title: Text('Panel ID: ${panel.id}'),
                    subtitle: Text(
                      'Center: (${panel.x.toStringAsFixed(1)}, ${panel.y.toStringAsFixed(1)}) | Size: ${panel.width.toStringAsFixed(0)}x${panel.height.toStringAsFixed(0)}',
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
