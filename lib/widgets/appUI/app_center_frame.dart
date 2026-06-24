import 'dart:async';

import 'package:flutter/material.dart';
import 'package:omiku/main.dart';
import 'package:omiku/models/models.dart';
import 'package:omiku/providers/app_state.dart';
import 'package:omiku/utils/haptic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omiku/widgets/appUI/awesome_search_bar.dart';
import 'package:omiku/widgets/appUI/button_navbar.dart';
import 'package:omiku/widgets/appUI/download/download.dart';
import 'package:omiku/widgets/appUI/left_drawer.dart';
import 'package:omiku/widgets/appUI/right_drawer.dart';
import 'package:omiku/widgets/manga/manga_library.dart';

class CenterContentPanel extends ConsumerStatefulWidget {
  final bool isMobileLayout;
  const CenterContentPanel({super.key, required this.isMobileLayout});

  @override
  ConsumerState<CenterContentPanel> createState() => _CenterContentPanelState();
}

class _CenterContentPanelState extends ConsumerState<CenterContentPanel> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  StreamSubscription? _sub;
  Future<List<MangaSeries>>? _libraryMangaFuture;
  Future<List<Series>>? _librarySeriesFuture;
  Future<List<Movie>>? _libraryMovieFuture;
  // late final AppLinks _appLinks;
  // late final Stream<Uri> _uriStream;
  final List<Widget> _pages = [
    LibraryScreen(/*typec: "movie"*/),
    LibraryScreen(/*typec: "tvseries"*/),
    LibraryScreen(/*typec: "anime"*/),
    LibraryScreen(),
    LibraryScreen(),
    LibraryScreen(),

    /// const WatchlistScreen(),
  ];
  void _navigateToDownloadScreen() {
    tVClick();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DownloadScreen(downloadManager: downloadManager),
      ),
    );
  }

  void _loadLibrary() {
    setState(() {
      _libraryMangaFuture = db.getAll<MangaSeries>();
      _libraryMovieFuture = db.getAll<Movie>();
      _librarySeriesFuture = db.getAll<Series>();
    });
  }

  void _onPageChanged(int index) {
    tVmedium();
    setState(() {
      _currentIndex = index;
    });
  }

  void _onNavBarTap(int index) {
    tVmedium();
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 200),
      curve: Curves.ease,
    );
  }

  @override
  void initState() {
    super.initState();
   dbService = ref.read(settingsServiceProvider);

    _loadLibrary();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Inside your Scaffold (like in CenterContentPanel)
      appBar: AppBar(
        toolbarHeight: 72,
        flexibleSpace: SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: FractionallySizedBox(
                widthFactor: 0.7, // Half width
                child: AwesomeUnifiedSearchField(
                  autofocus: true,
                  // Map to your first example provider methods:
                  searchMovies: (q) => db.searchMoviesByTitle(q),
                  searchTv: (q) => db.searchSeriesByTitle(q),
                  searchAnime: (q) => db.searchMangaByTitle(q),
                  onDownloadsTap: _navigateToDownloadScreen,
                  onAdvancedTap: () {
                    // showModalBottomSheet(
                    //   context: context,
                    //   isScrollControlled: true,
                    //   builder: (context) {
                    //     switch (_currentIndex) {
                    //       case 0:
                    //         return ContentFilterBottomSheet<MovieProvider>(
                    //           provider: movieProvider,
                    //         );
                    //       case 1:
                    //         return ContentFilterBottomSheet<TvSeriesProvider>(
                    //           provider: tvProvider,
                    //         );
                    //       case 2:
                    //         return ContentFilterBottomSheet<AnimeProvider>(
                    //           provider: animeProvider,
                    //         );
                    //       default:
                    //         return ContentFilterBottomSheet<MovieProvider>(
                    //           provider: movieProvider,
                    //         );
                    //    }
                    //  },
                    // );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
      drawer: Drawer(
        child: LeftNavigationPanel(isMobileLayout: true, isCollapsed: false),
      ),
      endDrawer: Drawer(
        child: RightNavigationPanel(isMobileLayout: true, isCollapsed: false),
      ),
      endDrawerEnableOpenDragGesture: true,
      drawerEnableOpenDragGesture: true,

      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const BouncingScrollPhysics(),
        allowImplicitScrolling: true,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavBarTap,
      ),
    );
  }
}
