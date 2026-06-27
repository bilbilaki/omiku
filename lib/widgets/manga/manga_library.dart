import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:omiku/main.dart';
import 'package:omiku/models/models.dart';
import 'package:omiku/services/manga/extraction_service.dart';
import 'package:omiku/utils/haptic.dart';
import 'package:omiku/widgets/gridview/premium_media_card.dart';
import 'package:omiku/widgets/manga/library_dialog.dart';
import 'package:omiku/widgets/manga/manga_details_screen.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  bool _isProcessingFile = false; // State for file picker loading
  Future<List<MangaSeries>>? _libraryFuture;
    Future<List<Series>>? _librarySeriesFuture;
  Future<List<Movie>>? _libraryMovieFuture;

  final TextEditingController seriesNameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController chapterNameController = TextEditingController();
  final TextEditingController chapterNumController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLibrary();
  }

  void _loadLibrary() {
    setState(() {
      _libraryFuture = db.getAll<MangaSeries>();
            _libraryMovieFuture = db.getAll<Movie>();
      _librarySeriesFuture = db.getAll<Series>();

    });
  }

  void onSeriesProcessed() async {
    Navigator.of(context).pop(); // Dismiss loading dialog

    await showConfirmDialog(context);
  }

  static Future<File> downloadAndSaveImage(String url, int seriesid) async {
    try {
      // 1. Kick off the network request immediately
      final Future<http.Response> responseFuture = http.get(Uri.parse(url));

      // 2. Concurrently get the local document directory while the network runs
      final Directory directory = await getApplicationSupportDirectory();
      final t = Directory(p.join(directory.path, '$seriesid'));
      if (!t.existsSync()) {
        t.createSync();
      }
      // Extract a unique file name from the URL or generate one
      final String fileName = p.basename(Uri.parse(url).path);
      final String localPath = p.join(directory.path, '$seriesid', fileName);

      // 3. Await the response if it's not finished yet
      final http.Response response = await responseFuture;

      if (response.statusCode == 200) {
        // 4. Write bytes directly to disk
        final File file = File(localPath);
        return await file.writeAsBytes(response.bodyBytes);
      } else {
        throw Exception(
          'Failed to download image: Status ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error saving image locally: $e');
    }
  }

  // Update your submission handler signature and inner logic to map both choice variants
  void onSeriesSubmitted(
    bool isNewSeries,
    MangaSeries? existingSeries,
    String? onlineCoverUrl,
  ) async {
    if (isNewSeries) {
      // CHOICE 1: Hydrate the automatically made sandbox entry as a fresh new series
      MangaSeries s = (await db.get<MangaSeries>(onToppedId))!;
      s.title = seriesNameController.text.trim();
      s.description = descriptionController.text.trim();
      if (onlineCoverUrl != null && onlineCoverUrl.isNotEmpty) {
        final hf = await downloadAndSaveImage(onlineCoverUrl, onToppedId);

        s.coverPath = hf.path;
      }

      MangaChapter ch = (await db.get<MangaChapter>(onToppedChId))!;
      ch.title = chapterNameController.text.trim();
      ch.chapterNumber = double.parse(chapterNumController.text);

      List<MangaChapter> lch = await db.getChaptersForSeries(s.seriesId);
      if (!lch.any((element) => element.chapterId == ch.chapterId)) {
        lch.add(ch);
      }

      await db.saveMangaWithChapters(s, lch);
      await db.put<MangaSeries>(s);
    } else {
      // CHOICE 2: Migrate extracted chapter structure over to target parent series
      if (existingSeries != null) {
        MangaChapter ch = (await db.get<MangaChapter>(onToppedChId))!;
        ch.title = chapterNameController.text.trim();
        ch.chapterNumber = double.tryParse(chapterNumController.text) ?? 1.0;
        ch.seriesId =
            existingSeries.seriesId; // Point chapter over to existing container

        await db.put<MangaChapter>(ch);

        List<MangaChapter> existingChapters = await db.getChaptersForSeries(
          existingSeries.seriesId,
        );
        if (!existingChapters.any(
          (element) => element.chapterId == ch.chapterId,
        )) {
          existingChapters.add(ch);
        }

        // Ensure sequential reading preservation order
        existingChapters.sort(
          (a, b) => a.chapterNumber.compareTo(b.chapterNumber),
        );

        await db.saveMangaWithChapters(existingSeries, existingChapters);
        await db.put<MangaSeries>(existingSeries);

        // Clean up the temporary shell series generated by the service to prevent layout ghosts
        try {
          await db.delete<MangaSeries>(onToppedId);
        } catch (e) {
          debugPrint("Temporary Series removal note: $e");
        }
      }
    }

    // Clear controller states cleanly for subsequent selections
    seriesNameController.clear();
    descriptionController.clear();
    chapterNameController.clear();
    chapterNumController.clear();

    if (context.mounted) {
      _loadLibrary();
      Navigator.of(context).pop();
    }
  }

  // Update showConfirmDialog wrapper to forward parameters
  Future<void> showConfirmDialog(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LibraryPage(
          onDone: (isNewSeries, existingSeries, onlineCoverUrl) {
            // 1. Call your submit logic
            onSeriesSubmitted(isNewSeries, existingSeries, onlineCoverUrl);

            // 2. Pop the LibraryPage off the navigation stack to go back
          },
          coverImage: File(onToppedCover),
          seriesNameController: seriesNameController,
          chapterNameController: chapterNameController,
          chapterNumController: chapterNumController,
          descriptionController: descriptionController,
        ),
      ),
    );
  } // Bottom Sheet

  void showOptionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndProcessMangaFile(BuildContext context) async {
    if (_isProcessingFile) return;

    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip', 'cbz', 'pdf', 'epub', 'tar', '7z', 'rar'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _isProcessingFile = true;
      });

      // 1. Show the loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Extracting Manga... This may take a moment."),
            ],
          ),
        ),
      );

      try {
        final File file = File(result.files.single.path!);
        final extractionService = Provider.of<ExtractionService>(
          context,
          listen: false,
        );
        final appStorageDir = (await getApplicationSupportDirectory()).path;

        await extractionService.processArchive(file, appStorageDir, context);

        if (context.mounted) {
          Navigator.of(context).pop(); // Dismiss loading loader
        }

        // Initialize sensible defaults for the controllers before presenting choice layout
        final defaultTitle = file.path.split('/').last.split('.').first;
        seriesNameController.text = defaultTitle;
        chapterNameController.text = defaultTitle;
        chapterNumController.text =
            "1 "; // Guarantees valid numeric fallback base
        descriptionController.text = "";

        if (context.mounted) {
          await showConfirmDialog(context);
        }

        _loadLibrary();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Manga added successfully!')),
          );
        }
      } catch (e) {
        debugPrint('Error processing file: $e');
        if (context.mounted) {
          Navigator.of(context).pop(); // Safety pop for loading dialog
        }
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to add manga: $e')));
        }
      } finally {
        setState(() {
          _isProcessingFile = false;
        });
      }
    }
  }
  void _handleRenameAction(MangaSeries series) {
    final textController = TextEditingController(text: series.title);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        title: const Text("Rename Series", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: textController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: "Series Title",
            labelStyle: TextStyle(color: Colors.white70),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            onPressed: () async {
              final newName = textController.text.trim();
              if (newName.isNotEmpty) {
                series.title = newName;
                await db.put<MangaSeries>(series);
                _loadLibrary();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Renamed successfully to "$newName"')),
                  );
                }
              }
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Rename"),
          ),
        ],
      ),
    );
  }

  void _handleDeleteAction(MangaSeries series) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        title: const Text("Delete Series", style: TextStyle(color: Colors.white)),
        content: Text(
          "Are you sure you want to delete '${series.title}' and all its associated chapters?",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await db.delete<MangaSeries>(series.id);
              _loadLibrary();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Deleted ${series.title}')),
                );
                Navigator.pop(context);
              }
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _handleEditAction(MangaSeries series) {
    seriesNameController.text = series.title;
    descriptionController.text = series.description;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        title: const Text("Edit Information", style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: seriesNameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: "Title"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: "Overview"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              seriesNameController.clear();
              descriptionController.clear();
              Navigator.pop(context);
            },
            child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              series.title = seriesNameController.text.trim();
              series.description = descriptionController.text.trim();
              await db.put<MangaSeries>(series);
              _loadLibrary();
              
              seriesNameController.clear();
              descriptionController.clear();
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _handleRefetchMetadata(MangaSeries series) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text("Refetching indices for '${series.title}'...")),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    // Simulate database lookup/remote API fetching
    Future.delayed(const Duration(seconds: 2), () async {
      _loadLibrary();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Metadata index synced for '${series.title}'!")),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E24),
      body: FutureBuilder<List<MangaSeries>>(
        future: _libraryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load library: ${snapshot.error}',
                style: const TextStyle(color: Colors.white70, fontSize: 18),
              ),
            );
          }

          final List<MangaSeries> library = snapshot.data ?? [];
          return Column(
            children: [
              // Filter Chips Row
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Popular', true),
                      _buildFilterChip('Action', false),
                      _buildFilterChip('Horror', false),
                      _buildFilterChip('Filter', false, icon: Icons.filter_list),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: library.isEmpty
                    ? Center(
                        child: Text(
                          _isProcessingFile ? 'Processing files...' : 'Empty library.\nTap + to add.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70, fontSize: 18),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(14),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: library.length,
                        itemBuilder: (context, index) {
                          final series = library[index];
                          final chapterCount = series.chapters.length;
                          final progress = _calculateSeriesProgress(series);

                          return PremiumMediaCard(
                            id: series.seriesId.toString(),
                            title: series.title,
                            overview: series.description,
                            imagePath: series.coverPath,
                            badgeText: '$chapterCount Ch.',
                            progress: progress,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => MangaDetailScreen(series: series),
                                ),
                              ).then((_) => _loadLibrary());
                            },
                            // Enable custom options on hold
                            enableActionMenu: true,
                            onRename: () => _handleRenameAction(series),
                            onDelete: () => _handleDeleteAction(series),
                            onEdit: () => _handleEditAction(series),
                            onRefetch: () => _handleRefetchMetadata(series),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ChoiceChip(
        label: Text(label),
        avatar: icon != null ? Icon(icon, color: isSelected ? Colors.black : Colors.white70) : null,
        selected: isSelected,
        selectedColor: Colors.greenAccent,
        labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white70),
        backgroundColor: Colors.grey.withOpacity(0.15),
        onSelected: (val) {
          tVmedium();
        },
      ),
    );
  }

  double _calculateSeriesProgress(MangaSeries series) {
    if (series.chapters.isEmpty) return 0.0;
    double cumulativeProgress = 0.0;
    int measurable = 0;
    for (final ch in series.chapters) {
      if (ch.totalPages > 0) {
        measurable++;
      }
    }
    return measurable > 0 ? (cumulativeProgress / measurable).clamp(0.0, 1.0) : 0.0;
  }
}

