import 'dart:io';
import 'package:flutter/material.dart';
import 'package:omiku/models/manga_series.dart';
import 'package:omiku/providers/manga_store.dart';
import 'package:omiku/services/panel_detector_service.dart';
import 'package:omiku/widgets/chapter_reader_screen.dart';
import 'package:provider/provider.dart';

class MangaDetailScreen extends StatefulWidget {
  final MangaSeries series;

  const MangaDetailScreen({super.key, required this.series});

  @override
  State<MangaDetailScreen> createState() => _MangaDetailScreenState();
}

class _MangaDetailScreenState extends State<MangaDetailScreen> {
  // We need to re-fetch the series from MangaStore to ensure it's the latest state
  // especially if panels are detected and updated.
  MangaSeries? _currentSeries;

  @override
  void initState() {
    super.initState();
    // Initialize with the passed series, will update via Consumer/Selector
    _currentSeries = widget.series;
  }

  // Method to check and generate panels for an entire chapter if needed
  Future<void> _handleChapterTap(BuildContext context, MangaChapter chapter) async {
   // final mangaStore = Provider.of<MangaStore>(context, listen: false);


    // if (panelsMissing) {
    //   // Show progress indicator
    //   showDialog(
    //     context: context,
    //     barrierDismissible: false,
    //     builder: (dialogContext) => AlertDialog(
    //       content: Column(
    //         mainAxisSize: MainAxisSize.min,
    //         children: [
    //           const CircularProgressIndicator(),
    //           const SizedBox(height: 16),
    //           Text('Detecting panels for Chapter ${chapter.chapterNumber} (page 1/${chapter.pagesData.length})...'),
    //         ],
    //       ),
    //     ),
    //   );

    //   try {
    //     List<ChapterPage> updatedPages = [];
    //     for (int i = 0; i < chapter.pagesData.length; i++) {
    //       final page = chapter.pagesData[i];
    //       // Update dialog message for current page
    //       if (mounted) {
    //         (Navigator.of(context).overlay?.context ?? context).findRenderObject()?.markNeedsLayout();
    //         // This is a hacky way to update dialog content. Better is to use a StatefuLBuilder or a custom dialog widget.
    //         // For now, let's just log and rely on the overall progress indicator.
    //         debugPrint('Processing panels for page ${i + 1}/${chapter.pagesData.length}');
    //       }

    //       final updatedPage = await panelDetectionService.detectPanelsForPage(page, isLTR: false); // Assuming RTL for manga
    //       updatedPages.add(updatedPage);
    //       // Immediately update the store for each page. This ensures progress is saved
    //       // even if the app crashes, and allows `Consumer` to react if needed.
    //       mangaStore.updateChapterPagePanels(
    //                     widget.series.id,

    //         chapter.id,
    //         page.pageNumber.toString(),
    //         updatedPage.panelsData,
    //         notify: false, // Don't notify for each individual page update during this batch
    //       );
    //     }

    //     // After all pages in the chapter are processed, notify listeners once
    //     // to update the UI with the final state of the series/chapter.
    //     mangaStore.notifyListeners();

    //     Navigator.of(context).pop(); // Dismiss progress indicator
    //     debugPrint('All panels detected for Chapter ${chapter.chapterNumber}.');
    //   } catch (e) {
    //     debugPrint('Error detecting panels: $e');
    //     Navigator.of(context).pop(); // Dismiss progress indicator
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       SnackBar(content: Text('Failed to detect panels for chapter: $e')),
    //     );
    //     return; // Do not navigate if panel detection failed
    //   }
    // }

    // Navigate to the ChapterReaderScreen once panels are ready (either detected or already existed)
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChapterReaderScreen(chapter: chapter),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use Selector to listen only to changes in this specific MangaSeries
    return Selector<MangaStore, MangaSeries?>(
      selector: (context, mangaStore) => mangaStore.library.firstWhere(
        (s) => s.id == widget.series.id,
        orElse: () => MangaSeries(id: "id", title: "title", coverPath: "coverPath"),
      ),
      builder: (context, series, child) {
        // If the series is null (e.g., deleted), show an error or pop
        if (series == null) {
          debugPrint('MangaDetailScreen: Series with ID ${widget.series.id} not found in store.');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pop(); // Pop if series no longer exists
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Manga series not found.')),
            );
          });
          return Scaffold(
            backgroundColor: Color(0xFF1E1E24),
            appBar: AppBar(title: Text('Error')),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        _currentSeries = series; // Keep _currentSeries updated

        return Scaffold(
          backgroundColor: const Color(0xFF1E1E24), // Dark background
          appBar: AppBar(
            backgroundColor: const Color(0xFF1E1E24),
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(
              _currentSeries!.title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: const Color(0xFF1E1E24),
                expandedHeight: 250.0,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Hero(
                    tag: 'series_cover_${_currentSeries!.id}',
                    child: _currentSeries!.coverPath.isNotEmpty && File(_currentSeries!.coverPath).existsSync()
                        ? Image.file(
                            File(_currentSeries!.coverPath),
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: Colors.grey[700],
                            alignment: Alignment.center,
                            child: const Icon(Icons.image_not_supported, color: Colors.white54, size: 80),
                          ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentSeries!.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Author: ${_currentSeries!.author}',
                        style: const TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _currentSeries!.description.isNotEmpty
                            ? _currentSeries!.description
                            : 'No description available for this series.',
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Chapters',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(color: Colors.white30),
                    ],
                  ),
                ),
              ),
              // Lazy loading list of chapters
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final chapter = _currentSeries!.chapters[index];
                    return ListTile(
                      tileColor: index.isEven ? Colors.grey[850] : Colors.grey[900],
                      title: Text(
                        'Chapter ${chapter.chapterNumber} - ${chapter.title}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        '${chapter.pagesData.length} pages | Panels detected: ${chapter.pagesData.every((p) => p.panelsData!.isNotEmpty) ? 'Yes' : 'No'}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      trailing: Icon(
                             Icons.check_circle_outline,
                        color: 
                             Colors.green
                      ),
                      onTap: () => _handleChapterTap(context, chapter),
                    );
                  },
                  childCount: _currentSeries!.chapters.length,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}