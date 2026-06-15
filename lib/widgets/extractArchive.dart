// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:omiku/providers/manga_store.dart';
// import 'package:omiku/services/extraction_service.dart';
// import 'package:provider/provider.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:path/path.dart' as p;



// class LibraryScreen extends StatefulWidget {
//   const LibraryScreen({super.key});

//   @override
//   State<LibraryScreen> createState() => _LibraryScreenState();
// }

// class _LibraryScreenState extends State<LibraryScreen> {
//   bool _isProcessing = false;

//   Future<void> _pickAndExtractArchive(BuildContext context) async {
//     // 1. Safe Document Directory acquisition on Android
//     final Directory appDocDir = await getApplicationDocumentsDirectory();
    
//     // 2. Select file using safe Android SAF framework via FilePicker
//     final FilePickerResult? result = await FilePicker.pickFiles(
//       type: FileType.custom,
//       allowedExtensions: ['cbz', 'zip', 'pdf', 'epub', '7z', 'rar', 'tar'],
//     );

//     if (result == null || result.files.single.path == null) return;

//     setState(() => _isProcessing = true);

//     try {
//       // Get picked file path
//       final String externalPath = result.files.single.path!;
//       File finalArchiveFile = File(externalPath);

//       // Android Safe Boundary Verification:
//       // If the file resides outside our app sandbox data folder (e.g., content:// uri caches),
//       // we cache it locally first to make sure libextractor.so can read it cleanly.
//       if (!externalPath.startsWith(appDocDir.parent.path)) {
//         final String localCachePath = p.join(appDocDir.path, p.basename(externalPath));
//         finalArchiveFile = await File(externalPath).copy(localCachePath);
//         debugPrint("File cached locally inside safe app storage: $localCachePath");
//       }

//       // 3. Initialize our processing service architecture
//       final mangaStore = Provider.of<MangaStore>(context, listen: false);
//       final extractionService = ExtractionService(mangaStore);

//       // Run background extraction worker sequence
//       await extractionService.processArchive(finalArchiveFile, appDocDir.path);

//       // Clean up the temporary local cache copy if one was made
//       if (finalArchiveFile.path != externalPath && await finalArchiveFile.exists()) {
//         await finalArchiveFile.delete();
//       }

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Archive imported successfully!")),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error: ${e.toString()}")),
//       );
//     } finally {
//       setState(() => _isProcessing = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final store = Provider.of<MangaStore>(context);

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("My Manga Library"),
//         actions: [
//           IconButton(
//             icon: Icon(store.darkMode ? Icons.light_mode : Icons.dark_mode),
//             onPressed: () => store.toggleDarkMode(),
//           )
//         ],
//       ),
//       body: _isProcessing
//           ? const Center(child: CircularProgressIndicator())
//           : store.library.isEmpty
//               ? const Center(child: Text("No comics imported yet."))
//               : ListView.builder(
//                   itemCount: store.library.length,
//                   itemBuilder: (context, index) {
//                     final manga = store.library[index];
//                     return ListTile(
//                       leading: manga.coverPath.isNotEmpty
//                           ? Image.file(File(manga.coverPath), width: 50, fit: BoxFit.cover)
//                           : const Icon(Icons.book),
//                       title: Text(manga.title),
//                       subtitle: Text("${manga.chapters.length} Chapter(s) found"),
//                     );
//                   },
//                 ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _isProcessing ? null : () => _pickAndExtractArchive(context),
//         child: const Icon(Icons.add_to_photos),
//       ),
//     );
//   }
// }