import 'dart:async';

import 'package:flutter/material.dart';
import 'package:omiku/models/local_library/directory_entry.dart'as de;
import 'package:omiku/services/localfiles/local_scan_service.dart';
import 'package:omiku/models/local_library/movie.dart';
import 'package:omiku/models/local_library/tv_series.dart';
import 'package:omiku/models/local_library/music.dart';
import 'package:omiku/models/local_library/music_video.dart';
import 'package:omiku/models/local_library/photo.dart';
import 'package:omiku/models/models.dart' as m;

import '../models/local_library/content_type.dart';

class LocalLibraryProvider extends ChangeNotifier {
  final LocalScanService _service;

  LocalLibraryProvider({LocalScanService? service})
    : _service = service ?? LocalScanService() {
    _subs.add(
      _service.progressStream.listen((_) {
        _progress = _service.progress;
        notifyListeners();
      }),
    );
    _subs.add(
      _service.statusStream.listen((s) {
        _status = s;
        notifyListeners();
      }),
    );
    _subs.add(
      _service.movieResultsStream.listen((list) {
        _movieResults = list;
        notifyListeners();
      }),
    );
    _subs.add(
      _service.tvResultsStream.listen((list) {
        _tvResults = list;
        notifyListeners();
      }),
    );
    _subs.add(
      _service.musicResultsStream.listen((list) {
        _musicResults = list;
        notifyListeners();
      }),
    );
    _subs.add(
      _service.musicVideoResultsStream.listen((list) {
        _musicVideoResults = list;
        notifyListeners();
      }),
    );
    _subs.add(
      _service.photoResultsStream.listen((list) {
        _photoResults = list;
        notifyListeners();
      }),
    );

    // Populate from on-disk cache (if any) so that previously scanned
    // content is available immediately after app restart.
    _restoreFromCache();
  }

  final _subs = <StreamSubscription>[];

  double _progress = 0.0;
  String _status = 'Idle';
  List<Movie> _movieResults = const [];
  List<TvSeries> _tvResults = const [];
  List<Music> _musicResults = const [];
  List<MusicVideo> _musicVideoResults = const [];
  List<Photo> _photoResults = const [];

  bool get isScanning => _service.isScanning;
  bool get isFetchingMetadata => _service.isFetchingMetadata;
  double get progress => _progress;
  String get status => _status;
  List<Movie> get movieResults => _movieResults;
  List<TvSeries> get tvResults => _tvResults;
  List<Music> get musicResults => _musicResults;
  List<MusicVideo> get musicVideoResults => _musicVideoResults;
  List<Photo> get photoResults => _photoResults;
  int get totalCandidates => _service.totalCandidates;
  int get processed => _service.processed;

  Future<void> _restoreFromCache() async {
    await _service.loadFromCache();
  }

  Future<void> startScan(
    String rootDir,
    ContentType contentType, {
    bool clearExisting = true,
  }) async {
    _status = 'Starting scan...';
    _progress = 0.0;
    notifyListeners();
    await _service.startScan(
      rootDir,
      contentType as de.ContentType,
      clearExisting: clearExisting,
    );
  }

  void cancel() {
    _service.cancel();
  }

Future<void> scanAllAndFetchMetadata(List<m.LibraryConfig> libConfigs) async {
  _status = 'Scanning all libraries...';
  _progress = 0.0;
  notifyListeners();

  // 1. Correctly map your library configurations using a clean switch expression
  final List<MapEntry<ContentType, List<String>>> entries = [
    for (final l in libConfigs)
      switch (l.contentType) {
        m.LibraryContentType.movie => MapEntry(ContentType.movie, l.folderPaths),
        m.LibraryContentType.tvShow => MapEntry(ContentType.tvSeries, l.folderPaths),
        m.LibraryContentType.manga => MapEntry(ContentType.manga, l.folderPaths),
        m.LibraryContentType.mixed => MapEntry(ContentType.mixedContent, l.folderPaths),
      }
  ];

  // 2. Iterate through and scan the paths safely
  for (final entry in entries) {
    final paths = entry.value;
    if (paths.isEmpty) continue;

    for (var i = 0; i < paths.length; i++) {
      // Set clearExisting to false here so paths don't overwrite each other 
      // during a sequential mass scan.
      await startScan(paths[i], entry.key, clearExisting: false);
    }
  }

  // 3. Kick off your metadata fetcher
  await _service.fetchTmdbMetadata();
  
  _status = 'Scan completed';
  _progress = 1.0;
  notifyListeners();
}
  Future<void> fetchTmdbMetadata() async {
    _status = 'Fetching TMDB metadata...';
    _progress = 0.0;
    notifyListeners();
    await _service.fetchTmdbMetadata();
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _service.dispose();
    super.dispose();
  }
}
