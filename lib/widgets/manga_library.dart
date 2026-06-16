import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:omiku/models/manga_series.dart';
import 'package:omiku/providers/manga_store.dart';
import 'package:omiku/services/extraction_service.dart';
import 'package:omiku/widgets/manga_details_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  bool _isProcessingFile = false; // State for file picker loading

  Future<void> _pickAndProcessMangaFile(BuildContext context) async {
    if (_isProcessingFile) return;

    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip', 'cbz', 'pdf', 'epub','tar','7z','rar'], // Common archive types
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _isProcessingFile = true;
      });

      // Show a loading indicator dialog
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
        final extractionService = Provider.of<ExtractionService>(context, listen: false);
        final appStorageDir = (await getApplicationSupportDirectory()).path; // Requires path_provider

        await extractionService.processArchive(file, appStorageDir,context);

        Navigator.of(context).pop(); // Dismiss loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Manga added successfully!')),
        );
      } catch (e) {
        debugPrint('Error processing file: $e');
        Navigator.of(context).pop(); // Dismiss loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add manga: $e')),
        );
      } finally {
        setState(() {
          _isProcessingFile = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E24), // Dark background
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E24),
        title: const Text('MangaHub', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              // TODO: Implement search functionality
            },
          ),
        ],
      ),
      body: Consumer<MangaStore>(
        builder: (context, mangaStore, child) {
          final List<MangaSeries> library = mangaStore.library;
          return Column(
            children: [
              // Filter Chips (mimicking the screenshot)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Popular', true),
                      _buildFilterChip('Action', false),
                      _buildFilterChip('Horror', false),
                      _buildFilterChip('Comedy', false),
                      _buildFilterChip('Romance', false),
                      _buildFilterChip('Filter', false, icon: Icons.filter_list),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: library.isEmpty
                    ? Center(
                        child: Text(
                          _isProcessingFile ? 'Adding manga...' : 'No manga series found.\nTap "+" to add one!',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70, fontSize: 18),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(8.0),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, // Two items per row
                          crossAxisSpacing: 16.0,
                          mainAxisSpacing: 16.0,
                          childAspectRatio: 0.7, // Adjust as needed for cover ratio
                        ),
                        itemCount: library.length,
                        itemBuilder: (context, index) {
                          final series = library[index];
                          return _MangaSeriesCard(series: series);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isProcessingFile ? null : () => _pickAndProcessMangaFile(context),
        label: _isProcessingFile
            ? const Row(
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(width: 8),
                  Text('Adding...'),
                ],
              )
            : const Text('Add Manga Series'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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
        backgroundColor: Colors.grey.withOpacity(0.3),
        onSelected: (selected) {
          // TODO: Implement filter logic
          debugPrint('Filter "$label" selected: $selected');
        },
      ),
    );
  }
}

class _MangaSeriesCard extends StatelessWidget {
  final MangaSeries series;

  const _MangaSeriesCard({required this.series});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MangaDetailScreen(series: series),
          ),
        );
      },
      child: Card(
        color: Colors.grey[850], // Dark card background
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 5,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Hero(
                tag: 'series_cover_${series.id}', // Unique tag for Hero animation
                child: series.coverPath.isNotEmpty && File(series.coverPath).existsSync()
                    ? Image.file(
                        File(series.coverPath),
                        fit: BoxFit.cover,
                        width: double.infinity,
                      )
                    : Container(
                        color: Colors.grey[700],
                        alignment: Alignment.center,
                        child: const Icon(Icons.image_not_supported, color: Colors.white54, size: 50),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                series.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                '${series.chapters.length} Chapters',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

