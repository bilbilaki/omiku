import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as pr;
import 'package:media_kit/media_kit.dart';
import 'package:omiku/providers/app_state.dart';
import 'package:omiku/services/database.dart';
import 'package:omiku/services/manga/panel_detector_service.dart';
import 'package:omiku/splash.dart';
import 'package:omiku/widgets/appUI/app_center_frame.dart';
import 'package:omiku/widgets/appUI/download/download.dart';
import 'package:omiku/widgets/manga/manga_library.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:telegram_ios_ui_kit/telegram_ios_ui_kit.dart';
import 'package:go_router/go_router.dart';
import 'package:omiku/services/manga/extraction_service.dart';
import 'package:uuid/uuid.dart';
import 'package:cross_platform_video_thumbnails/cross_platform_video_thumbnails.dart';

part 'router.dart';

final downloadManager = DownloadListManager();

Uuid uuid = Uuid();
String appSupportDir = '';
String appCacheDir = '';
late DatabaseService db;
late DatabaseService dbService;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await CrossPlatformVideoThumbnails.initialize();

  await DatabaseService().init();
  db = DatabaseService();
  final telegramTheme = TelegramThemeData.dark();

  // Create PanelDetectionService instance once
  final panelDetectionService = PanelDetectionService();
  final appSupport = await getApplicationSupportDirectory();
  appSupportDir = appSupport.path;
  final appCache = await getApplicationCacheDirectory();
  appCacheDir = appCache.path;
  runApp(
    MultiProvider(
      providers: [
        // Provide the PanelDetectionService. It manages its own YOLO loading.
        Provider<PanelDetectionService>(
          create: (context) => panelDetectionService,
        ),
        Provider<ExtractionService>(create: (context) => ExtractionService()),
      ],
      child: pr.ProviderScope(
        overrides: [
          settingsServiceProvider.overrideWith((ref) => settingsService),
        ],
        child: TelegramTheme(
          data: telegramTheme,
          child: MaterialApp.router(
            routerConfig: _router,
            theme: telegramTheme.toThemeData(),
            debugShowCheckedModeBanner: false,
            //   home: LibraryScreen(), // Start with the LibraryScreen
          ),
        ),
      ),
    ),
  );
}
