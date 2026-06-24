import 'dart:io';
import 'package:flutter/material.dart';
import 'package:omiku/main.dart';
import 'package:omiku/models/models.dart';
import 'package:omiku/widgets/manga/chapter_reader_screen.dart';
import 'package:omiku/widgets/gridview/universal_image_loader.dart';

class MangaDetailScreen extends StatefulWidget {
  final MangaSeries series;

  const MangaDetailScreen({super.key, required this.series});

  @override
  State<MangaDetailScreen> createState() => _MangaDetailScreenState();
}

class _MangaDetailScreenState extends State<MangaDetailScreen> {
  MangaSeries? _currentSeries;
  List<MangaChapter> _chapters = [];
  bool _isLoadingChapters = true;

  @override
  void initState() {
    super.initState();
    _currentSeries = widget.series;
    _loadChapters();
  }

  Future<void> _loadChapters() async {
    try {
      final chapters = await db.getChaptersForSeries(widget.series.seriesId);
      if (mounted) {
        setState(() {
          _chapters = chapters;
          _isLoadingChapters = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading chapters: $e");
      if (mounted) {
        setState(() {
          _isLoadingChapters = false;
        });
      }
    }
  }

  Future<void> _handleChapterTap(BuildContext context, MangaChapter chapter) async {
    // Navigate safely to the reader screen as chapters and pages are structures
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChapterReaderScreen(chapter: chapter),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _currentSeries = widget.series;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E24),
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
                child: _currentSeries!.coverPath.isNotEmpty
                    ? UniversalImageLoader(imagePath: _currentSeries!.coverPath)                    : Container(
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
          if (_isLoadingChapters)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(color: Colors.blueAccent),
                ),
              ),
            )
          else if (_chapters.isEmpty)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text(
                    'No chapters found for this series.',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final chapter = _chapters[index];
                  return ListTile(
                    tileColor: index.isEven ? Colors.grey[850] : Colors.grey[900],
                    title: Text(
                      'Chapter ${chapter.chapterNumber} - ${chapter.title}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      '${chapter.pages.length} pages',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    trailing: const Icon(
                      Icons.book,
                      color: Colors.green,
                    ),
                    onTap: () => _handleChapterTap(context, chapter),
                  );
                },
                childCount: _chapters.length,
              ),
            ),
        ],
      ),
    );
  }
}