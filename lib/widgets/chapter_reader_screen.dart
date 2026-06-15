import 'dart:io';

import 'package:flutter/material.dart';
import 'package:omiku/models/manga_series.dart';
import 'package:omiku/widgets/manga_reader.dart'; // Import the adapted MangaReaderScreen

class ChapterReaderScreen extends StatefulWidget {
  final MangaChapter chapter;
  final bool isLTR; // Reading direction for the chapter

  const ChapterReaderScreen({
    super.key,
    required this.chapter,
    this.isLTR = false, // Default to RTL (manga)
  });

  @override
  State<ChapterReaderScreen> createState() => _ChapterReaderScreenState();
}

class _ChapterReaderScreenState extends State<ChapterReaderScreen> {
  late PageController _pageController;
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPageIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToNextPage() {
    if (_currentPageIndex < widget.chapter.pagesData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else {
      // End of chapter reached
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End of Chapter!')),
      );
      Navigator.of(context).pop(); // Go back to detail screen
    }
  }

  void _goToPreviousPage() {
    if (_currentPageIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else {
      // Beginning of chapter reached
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Beginning of Chapter!')),
      );
      // Optionally, pop to previous screen or do nothing
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.chapter.pagesData.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF1E1E24),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E1E24),
          title: Text(widget.chapter.title, style: const TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(
          child: Text('No pages found for this chapter.', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E24),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E24),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Chapter ${widget.chapter.chapterNumber} (Page ${_currentPageIndex + 1}/${widget.chapter.pagesData.length})',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.chapter.pagesData.length,
        onPageChanged: (index) {
          setState(() {
            _currentPageIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final currentPage = widget.chapter.pagesData[index];
          // MangaReaderScreen is now responsible for displaying a single page
          // with its panels. It will call _goToNextPage/_goToPreviousPage
          // when the user runs out of panels on the current page.
          return MangaReaderScreen(
            detectedPanels: currentPage.panelsData,
            mangaImage: File(currentPage.pageFilePath),
            onNextPage: _goToNextPage,
            onPervPage: _goToPreviousPage,
          );
        },
      ),
    );
  }
}