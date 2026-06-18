import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:omiku/providers/manga_store.dart';
import 'package:omiku/services/panel_detector_service.dart';
import 'package:omiku/widgets/manga_library.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
// import 'package:omiku/models/panel_debug_painter.dart'; // REMOVED: Not needed in final reader
// import 'package:omiku/widgets/manga_reader.dart'; // Replaced by our new screens and modified reader
import 'package:provider/provider.dart';
import 'package:telegram_ios_ui_kit/telegram_ios_ui_kit.dart';
import 'package:flutter/services.dart';
// import 'package:ultralytics_yolo/ultralytics_yolo.dart'; // Handled by PanelDetectionService
// import 'package:image_picker/image_picker.dart'; // Handled by LibraryScreen

// NEW SERVICE IMPORTS
import 'package:omiku/services/extraction_service.dart';
import 'package:uuid/uuid.dart';

// NEW SCREEN IMPORTS
// import 'package:omiku/screens/manga_detail_screen.dart'; // Not directly in main.dart
// import 'package:omiku/screens/chapter_reader_screen.dart'; // Not directly in main.dart
// import 'package:uuid/uuid.dart'; // Only needed in YOLODemo for dummy IDs
Uuid uuid = Uuid();
String appSupportDir = '';
String appCacheDir = '';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Open a storage box specifically for app configurations/state
  await Hive.openBox('manga_store_box');
  final telegramTheme = TelegramThemeData.dark();

  // Create PanelDetectionService instance once
  final panelDetectionService = PanelDetectionService();
  final appSupport = await getApplicationSupportDirectory();
  appSupportDir = appSupport.path;
  final appCache = await getApplicationCacheDirectory();
  appCacheDir = appCache.path;
  final d = await rootBundle.load("assets/models/gglm-base.bin");
  final m = p.join(appSupportDir, "gglm-base.bin");
  final f = File(m);
  if (!f.existsSync()) {
    f.createSync();
    f.writeAsBytesSync(d.buffer.asUint8List());
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => MangaStore()),
        // Provide the PanelDetectionService. It manages its own YOLO loading.
        Provider<PanelDetectionService>(
          create: (context) => panelDetectionService,
        ),
        // Provide the ExtractionService, injecting MangaStore and PanelDetectionService
        Provider<ExtractionService>(
          create: (context) => ExtractionService(context.read<MangaStore>()),
        ),
      ],
      child: TelegramTheme(
        data: telegramTheme,
        child: MaterialApp(
          theme: telegramTheme.toThemeData(),
          debugShowCheckedModeBanner: false,
          home: LibraryScreen(), // Start with the LibraryScreen
        ),
      ),
    ),
  );
}

// REMOVED: YOLODemo and SplashScreen as they are no longer the main entry points
// If you still need YOLODemo for testing single image detection, you can navigate to it
// from the LibraryScreen or create a dedicated debug route.
