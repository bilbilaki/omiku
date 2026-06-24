import 'dart:io';
import 'package:flutter/material.dart';
import 'package:omiku/main.dart'; // Access your database global 'db' instance
import 'package:omiku/models/models.dart';
import 'package:omiku/widgets/manga/manga_reader.dart';

class ChapterReaderScreen extends StatefulWidget {
  final MangaChapter chapter;
  final bool isLTR;

  const ChapterReaderScreen({
    super.key,
    required this.chapter,
    this.isLTR = false,
  });

  @override
  State<ChapterReaderScreen> createState() => _ChapterReaderScreenState();
}

class _ChapterReaderScreenState extends State<ChapterReaderScreen> {
  late PageController _pageController;
  int _currentPageIndex = 0;
  List<ChapterPage> _loadedPages = [];
  bool _isLoading = true;
  bool isPageback = false;
  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPageIndex);
    _loadPagesFromDatabase();
  }

  Future<void> _loadPagesFromDatabase() async {
    try {
      // Bypasses the unmanaged/lazy link issue by fetching pages directly by ID
      final pages = await db.getPagesForChapter(widget.chapter.chapterId);
      if (mounted) {
        setState(() {
          _loadedPages = pages;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading chapter pages: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToNextPage() {
    if (_currentPageIndex < _loadedPages.length - 1) {
      isPageback = false;
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }

  void _goToPreviousPage() {
    if (_currentPageIndex > 0) {
      isPageback = true;
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF1E1E24),
        body: Center(
          child: CircularProgressIndicator(color: Colors.blueAccent),
        ),
      );
    }

    if (_loadedPages.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF1E1E24),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E1E24),
          title: Text(
            widget.chapter.title,
            style: const TextStyle(color: Colors.white),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(
          child: Text(
            'No pages found for this chapter.',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        physics: const NeverScrollableScrollPhysics(),
        controller: _pageController,
        itemCount: _loadedPages.length,
        onPageChanged: (index) {
          setState(() {
            _currentPageIndex = index;
          });
        },
        // REMOVED 'async' here
        itemBuilder: (context, index) {
          // Pull safely from our loaded array list
          ChapterPage currentPage = _loadedPages[index];

          final panels = currentPage.panels;
          return MangaReaderScreen(
            detectedPanels: panels,
            mangaImage: File(currentPage.pageFilePath),
            onNextPage: _goToNextPage,
            onPervPage: _goToPreviousPage,
            isPageBack: isPageback,
          );
        },
      ),
    );
  }
}
