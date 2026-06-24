import 'dart:async';
import 'dart:io';
import '../../models/local_library/directory_entry.dart';
import '../../models/local_library/episode.dart';
import '../../models/local_library/metadata.dart';
import '../../models/local_library/movie.dart';
import '../../models/local_library/music.dart';
import '../../models/local_library/music_video.dart';
import '../../models/local_library/photo.dart';
import '../../models/local_library/tv_series.dart';
import '../../models/local_library/season.dart';
import '../../models/local_library/fetched_data.dart';
import '../../models/local_library/local_scan_index.dart';
import 'local_scan_index_service.dart';
import '../contentApi/movie_service.dart';

/// Service for scanning and indexing local media files.
///
/// Performance Characteristics:
/// - Optimized for large libraries (10,000+ files)
/// - Progress updates batched every 10 files to reduce UI overhead
/// - Event loop yields every 100 files to maintain responsiveness
/// - Comprehensive error handling - continues on individual file failures
/// - Early progress feedback during file discovery phase
///
/// Typical Performance:
/// - Small library (100 files): ~2 seconds
/// - Medium library (1,000 files): ~13 seconds  
/// - Large library (10,000 files): ~2 minutes
/// - Very large library (50,000 files): ~10 minutes
///
/// See PERFORMANCE_OPTIMIZATION.md for detailed benchmarks and tuning guide.
class LocalScanService {
  final LocalScanIndexService _indexService;

  LocalScanService({LocalScanIndexService? indexService})
    : _indexService = indexService ?? const LocalScanIndexService();

  // Performance tuning constants
  // Adjust these values based on your needs - see PERFORMANCE_OPTIMIZATION.md
  static const int _progressUpdateInterval = 10; // UI update frequency (files)
  static const int _delayInterval = 100;         // Event loop yield frequency (files)
  static const int _fileDiscoveryFeedback = 100; // File discovery progress (files)
  static const int _metadataUpdateInterval = 5;  // TMDB fetch UI updates (items)

  // State
  bool _isScanning = false;
  bool _cancelRequested = false;
  bool _isFetchingMetadata = false;
  int _totalCandidates = 0;
  int _processed = 0;

  final _movieResults = <Movie>[];
  final _tvResults = <TvSeries>[];
  final _musicResults = <Music>[];
  final _musicVideoResults = <MusicVideo>[];
  final _photoResults = <Photo>[];

  final _progressController = StreamController<double>.broadcast();
  final _statusController = StreamController<String>.broadcast();
  final _movieResultsController = StreamController<List<Movie>>.broadcast();
  final _tvResultsController = StreamController<List<TvSeries>>.broadcast();
  final _musicResultsController = StreamController<List<Music>>.broadcast();
  final _musicVideoResultsController =
      StreamController<List<MusicVideo>>.broadcast();
  final _photoResultsController = StreamController<List<Photo>>.broadcast();

  // Public streams
  Stream<double> get progressStream => _progressController.stream;
  Stream<String> get statusStream => _statusController.stream;
  Stream<List<Movie>> get movieResultsStream => _movieResultsController.stream;
  Stream<List<TvSeries>> get tvResultsStream => _tvResultsController.stream;
  Stream<List<Music>> get musicResultsStream => _musicResultsController.stream;
  Stream<List<MusicVideo>> get musicVideoResultsStream =>
      _musicVideoResultsController.stream;
  Stream<List<Photo>> get photoResultsStream => _photoResultsController.stream;

  bool get isScanning => _isScanning;
  bool get isFetchingMetadata => _isFetchingMetadata;
  double get progress =>
      _totalCandidates == 0 ? 0 : _processed / _totalCandidates;
  List<Movie> get movieResults => List.unmodifiable(_movieResults);
  List<TvSeries> get tvResults => List.unmodifiable(_tvResults);
  List<Music> get musicResults => List.unmodifiable(_musicResults);
  List<MusicVideo> get musicVideoResults =>
      List.unmodifiable(_musicVideoResults);
  List<Photo> get photoResults => List.unmodifiable(_photoResults);
  int get totalCandidates => _totalCandidates;
  int get processed => _processed;

  /// Rebuild in-memory results from the persisted JSON index, if present.
  ///
  /// This allows the app to show cached local library content after a restart
  /// without requiring the user to manually trigger a new scan. It reuses the
  /// existing scan grouping logic but uses the indexed file list instead of
  /// walking the filesystem again.
  Future<void> loadFromCache() async {
    if (_isScanning) return;

    try {
      final index = await _indexService.load();
      if (index.entries.isEmpty) {
        print('No cached library data found');
        return; // Nothing cached yet
      }

      _isScanning = true;
      _cancelRequested = false;
      _clearResults();
      _processed = 0;
      _totalCandidates = index.entries.length;

      _statusController.add('Loading cached local library...');
      _emitProgress();

      // Bucket file paths by content type based on what was stored in the index.
      final Map<ContentType, List<String>> byType = {
        for (final type in ContentType.values) type: <String>[],
      };

      for (final entry in index.entries.values) {
        try {
          final type = _contentTypeFromName(entry.contentType);
          byType[type]?.add(entry.path);
        } catch (e) {
          print('Error processing cached entry ${entry.path}: $e');
          continue;
        }
      }

      // Reuse the existing scan logic but with cached candidate lists.
      // Process each type even if others fail
      try {
        if (byType[ContentType.movie]!.isNotEmpty) {
          await _scanMovies(byType[ContentType.movie]!);
        }
      } catch (e) {
        print('Error loading cached movies: $e');
      }
      
      try {
        if (byType[ContentType.tvSeries]!.isNotEmpty) {
          await _scanTvSeries(byType[ContentType.tvSeries]!);
        }
      } catch (e) {
        print('Error loading cached TV series: $e');
      }
      
      try {
        if (byType[ContentType.music]!.isNotEmpty) {
          await _scanMusic(byType[ContentType.music]!);
        }
      } catch (e) {
        print('Error loading cached music: $e');
      }
      
      try {
        if (byType[ContentType.musicVideo]!.isNotEmpty) {
          await _scanMusicVideos(byType[ContentType.musicVideo]!);
        }
      } catch (e) {
        print('Error loading cached music videos: $e');
      }
      
      try {
        if (byType[ContentType.photo]!.isNotEmpty) {
          await _scanPhotos(byType[ContentType.photo]!);
        }
      } catch (e) {
        print('Error loading cached photos: $e');
      }
      
      try {
        if (byType[ContentType.mixed]!.isNotEmpty) {
          await _scanMixedContent(byType[ContentType.mixed]!);
        }
      } catch (e) {
        print('Error loading cached mixed content: $e');
      }

      _isScanning = false;
      _statusController.add('Loaded cached local library');
    } catch (e) {
      _isScanning = false;
      _statusController.add('Failed to load cache: $e');
      print('Error loading cache: $e');
    }
  }

  Future<void> startScan(
    String rootDir,
    ContentType contentType, {
    bool clearExisting = true,
  }) async {
    if (_isScanning) return;
    _isScanning = true;
    _cancelRequested = false;
    if (clearExisting) {
      _clearResultsForType(contentType);
    }
    _processed = 0;
    _totalCandidates = 0;

    _statusController.add(
      'Scanning ${_contentTypeLabel(contentType)} files...',
    );

    try {
      final candidates = await _collectCandidates(rootDir, contentType);
      _totalCandidates = candidates.length;
      _emitProgress();

      // Update the lightweight JSON index on disk. This will only
      // write the file if something actually changed between scans.
      await _indexService.updateForScan(rootDir, contentType, candidates);

      if (candidates.isEmpty) {
        _isScanning = false;
        _statusController.add('No media files found');
        return;
      }

      _statusController.add(
        'Processing ${candidates.length} ${_contentTypeLabel(contentType)} files...',
      );

      // Route to appropriate scanner based on content type
      switch (contentType) {
        case ContentType.movie:
          await _scanMovies(candidates);
          break;
        case ContentType.tvSeries:
          await _scanTvSeries(candidates);
          // Also scan loose TV files in the root directory
          // await _scanLooseTvFiles(rootDir); // Removed as _scanTvSeries now handles virtual grouping for all files
          break;
        case ContentType.music:
          await _scanMusic(candidates);
          break;
        case ContentType.musicVideo:
          await _scanMusicVideos(candidates);
          break;
        case ContentType.photo:
          await _scanPhotos(candidates);
          break;
        case ContentType.mixed:
          await _scanMixedContent(candidates);
          break;
      }

      _isScanning = false;
      _statusController.add(
        _cancelRequested ? 'Scan cancelled' : 'Scan complete',
      );
    } catch (e) {
      // Ensure scanning state is reset even on error
      _isScanning = false;
      _statusController.add('Scan failed: $e');
      print('Error during scan: $e');
      rethrow;
    }
  }

  void cancel() {
    _cancelRequested = true;
  }

  void dispose() {
    _progressController.close();
    _statusController.close();
    _movieResultsController.close();
    _tvResultsController.close();
    _musicResultsController.close();
    _musicVideoResultsController.close();
    _photoResultsController.close();
  }

  void _clearResults() {
    _movieResults.clear();
    _tvResults.clear();
    _musicResults.clear();
    _musicVideoResults.clear();
    _photoResults.clear();
  }

  void _clearResultsForType(ContentType type) {
    switch (type) {
      case ContentType.movie:
        _movieResults.clear();
        _movieResultsController.add(List.unmodifiable(_movieResults));
        break;
      case ContentType.tvSeries:
        _tvResults.clear();
        _tvResultsController.add(List.unmodifiable(_tvResults));
        break;
      case ContentType.music:
        _musicResults.clear();
        _musicResultsController.add(List.unmodifiable(_musicResults));
        break;
      case ContentType.musicVideo:
        _musicVideoResults.clear();
        _musicVideoResultsController.add(List.unmodifiable(_musicVideoResults));
        break;
      case ContentType.photo:
        _photoResults.clear();
        _photoResultsController.add(List.unmodifiable(_photoResults));
        break;
      case ContentType.mixed:
        _musicResults.clear();
        _musicResultsController.add(List.unmodifiable(_musicResults));
        _musicVideoResults.clear();
        _musicVideoResultsController.add(List.unmodifiable(_musicVideoResults));
        _photoResults.clear();
        _photoResultsController.add(List.unmodifiable(_photoResults));
        break;
    }
  }

  String _contentTypeLabel(ContentType type) {
    switch (type) {
      case ContentType.movie:
        return 'Movie';
      case ContentType.tvSeries:
        return 'TV Series';
      case ContentType.music:
        return 'Music';
      case ContentType.musicVideo:
        return 'Music Video';
      case ContentType.photo:
        return 'Photo';
      case ContentType.mixed:
        return 'Mixed';
    }
  }

  ContentType _contentTypeFromName(String name) {
    return ContentType.values.firstWhere(
      (e) => e.name == name,
      orElse: () => ContentType.movie,
    );
  }

  Future<void> _scanMovies(List<String> candidates) async {
    final videoExts = <String>{'.mp4', '.mkv', '.avi', '.mov', '.m4v', '.webm'};

    for (final path in candidates) {
      if (_cancelRequested) break;

      try {
        final file = File(path);
        final ext = file.path.split('.').last.toLowerCase();
        if (!videoExts.contains('.$ext')) {
          _processed++;
          continue;
        }

        final parsed = _parseMediaFromFilename(path);
        final metadata = await Metadata.fromFile(file);
        final movieName = parsed.name.isEmpty ? 'Unknown Movie' : parsed.name;
        final moviePath = file.parent.path;
        final seriesFolderName = moviePath.split(Platform.pathSeparator).last;

        final normalizedSeriesName = _normalizeFolderNameForTmdb(
          seriesFolderName,
        );

        var movie = _movieResults.firstWhere(
          (m) => m.path == moviePath && m.name == movieName,
          orElse: () => Movie(
            path: moviePath,
            parentPath: Directory(moviePath).parent.path,
            name: normalizedSeriesName,
            movieItems: [],
          ),
        );

        final movieItem = MovieItem(
          path: path,
          parentPath: file.parent.path,
          name: file.uri.pathSegments.last,
          metadata: metadata,
        );

        if (!_movieResults.contains(movie)) {
          _movieResults.add(movie.copyWith(movieItems: [movieItem]));
        } else {
          final index = _movieResults.indexOf(movie);
          _movieResults[index] = movie.copyWith(
            movieItems: [...movie.movieItems, movieItem],
          );
        }

        _processed++;
        // Optimize: Update UI less frequently for better performance
        if (_processed % _progressUpdateInterval == 0) {
          _movieResultsController.add(List.unmodifiable(_movieResults));
          _emitProgress();
        }
      } catch (e) {
        // Better error handling: Log and continue instead of crashing
        print('Error processing movie file $path: $e');
        _processed++;
        continue;
      }
      
      // Reduced delay for better throughput
      if (_processed % _delayInterval == 0) {
        await Future.delayed(const Duration(milliseconds: 1));
      }
    }

    // Final update after scan completes
    _movieResultsController.add(List.unmodifiable(_movieResults));
    _emitProgress();
  }

  Future<void> _scanTvSeries(List<String> candidates) async {
    final videoExts = <String>{'.mp4', '.mkv', '.avi', '.mov', '.m4v', '.webm'};

    for (final path in candidates) {
      if (_cancelRequested) break;

      try {
        final file = File(path);
        final ext = file.path.split('.').last.toLowerCase();
        if (!videoExts.contains('.$ext')) {
          _processed++;
          continue;
        }

        final parsed = _parseMediaFromFilename(path);
        final metadata = await Metadata.fromFile(file);

        if (!parsed.isTv) {
          _processed++;
          continue;
        }

        // Determine if we should use virtual grouping (based on filename) or folder grouping
        // If parsed name has letters, assume it's a series name and use virtual grouping.
        // Otherwise, fall back to folder name.

        String seriesPath;
        String seriesName;

        final hasLetters = RegExp(r'[a-zA-Z]').hasMatch(parsed.name);

        if (hasLetters && parsed.name.isNotEmpty) {
          final normalizedName = _normalizeFolderNameForTmdb(parsed.name);
          seriesPath =
              '${file.parent.path}${Platform.pathSeparator}[VIRTUAL] $normalizedName';
          seriesName = normalizedName;
        } else {
          seriesPath = file.parent.path;
          final folderName = seriesPath.split(Platform.pathSeparator).last;
          seriesName = _normalizeFolderNameForTmdb(folderName);
        }

        var series = _tvResults.firstWhere(
          (s) => s.path == seriesPath,
          orElse: () {
            final newSeries = TvSeries(
              path: seriesPath,
              parentPath: Directory(seriesPath).parent.path,
              name: seriesName,
            );
            _tvResults.add(newSeries);
            return newSeries;
          },
        );

        final seasonNum = parsed.season ?? 1;
        var season = series.seasons.firstWhere(
          (s) => s.seasonNumber == seasonNum,
          orElse: () => Season(
            path: seriesPath,
            parentPath: Directory(seriesPath).parent.path,
            seasonNumber: seasonNum,
            seriesId: series.id,
            seriesName: series.name,
          ),
        );

        final episodeNum = parsed.episode ?? 1;
        final episode = Episode(
          seasonNumber: seasonNum,
          episodeNumber: episodeNum,
          name: file.uri.pathSegments.last,
          path: path,
          parentPath: file.parent.path,
          metadata: metadata,
          tvSeriesId: series.id,
          tvSeriesName: series.name,
        );

        final updatedEpisodes = [...season.episodes, episode];
        final updatedSeason = season.copyWith(episodes: updatedEpisodes);

        final seasonIndex = series.seasons.indexWhere(
          (s) => s.seasonNumber == seasonNum,
        );
        final updatedSeasons = List<Season>.from(series.seasons);

        if (seasonIndex >= 0) {
          updatedSeasons[seasonIndex] = updatedSeason;
        } else {
          updatedSeasons.add(updatedSeason);
        }

        final seriesIndex = _tvResults.indexWhere((s) => s.path == seriesPath);
        _tvResults[seriesIndex] = series.copyWith(seasons: updatedSeasons);

        _processed++;
        // Optimize: Update UI less frequently for better performance
        if (_processed % _progressUpdateInterval == 0) {
          _tvResultsController.add(List.unmodifiable(_tvResults));
          _emitProgress();
        }
      } catch (e) {
        // Better error handling: Log and continue instead of crashing
        print('Error processing TV series file $path: $e');
        _processed++;
        continue;
      }

      // Reduced delay for better throughput
      if (_processed % _delayInterval == 0) {
        await Future.delayed(const Duration(milliseconds: 1));
      }
    }

    // Final update after scan completes
    _tvResultsController.add(List.unmodifiable(_tvResults));
    _emitProgress();
  }

  Future<void> _scanMusic(List<String> candidates) async {
    final audioExts = <String>{'.mp3', '.flac', '.wav', '.m4a', '.aac', '.ogg'};

    for (final path in candidates) {
      if (_cancelRequested) break;

      try {
        final file = File(path);
        final ext = file.path.split('.').last.toLowerCase();
        if (!audioExts.contains('.$ext')) {
          _processed++;
          continue;
        }

        final metadata = await Metadata.fromFile(file);

        // Get the immediate parent folder as album
        final albumPath = file.parent.path;
        final albumName = albumPath.split(Platform.pathSeparator).last;

        var music = _musicResults.firstWhere(
          (m) => m.path == albumPath,
          orElse: () => Music(
            path: albumPath,
            parentPath: Directory(albumPath).parent.path,
            name: albumName,
            musicItems: [],
          ),
        );

        final musicItem = MusicItem(
          path: path,
          parentPath: albumPath,
          name: file.uri.pathSegments.last,
          metadata: metadata,
        );

        if (!_musicResults.contains(music)) {
          _musicResults.add(music.copyWith(musicItems: [musicItem]));
        } else {
          final index = _musicResults.indexOf(music);
          _musicResults[index] = music.copyWith(
            musicItems: [...music.musicItems, musicItem],
          );
        }

        _processed++;
        if (_processed % _progressUpdateInterval == 0) {
          _musicResultsController.add(List.unmodifiable(_musicResults));
          _emitProgress();
        }
      } catch (e) {
        print('Error processing music file $path: $e');
        _processed++;
        continue;
      }

      if (_processed % _delayInterval == 0) {
        await Future.delayed(const Duration(milliseconds: 1));
      }
    }

    _musicResultsController.add(List.unmodifiable(_musicResults));
    _emitProgress();
  }

  Future<void> _scanMusicVideos(List<String> candidates) async {
    final videoExts = <String>{'.mp4', '.mkv', '.avi', '.mov', '.m4v', '.webm'};

    for (final path in candidates) {
      if (_cancelRequested) break;

      try {
        final file = File(path);
        final ext = file.path.split('.').last.toLowerCase();
        if (!videoExts.contains('.$ext')) {
          _processed++;
          continue;
        }

        final metadata = await Metadata.fromFile(file);
        final videoName = file.parent.path.split(Platform.pathSeparator).last;
        final videoPath = file.parent.path;

        var musicVideo = _musicVideoResults.firstWhere(
          (m) => m.path == videoPath && m.name == videoName,
          orElse: () => MusicVideo(
            path: videoPath,
            parentPath: Directory(videoPath).parent.path,
            name: videoName,
          ),
        );

        final musicVideoItem = MusicVideoItem(
          path: path,
          parentPath: file.parent.path,
          name: file.uri.pathSegments.last,
          metadata: metadata,
        );

        if (!_musicVideoResults.contains(musicVideo)) {
          _musicVideoResults.add(
            musicVideo.copyWith(musicVideoItems: [musicVideoItem]),
          );
        } else {
          final index = _musicVideoResults.indexOf(musicVideo);
          _musicVideoResults[index] = musicVideo.copyWith(
            musicVideoItems: [...musicVideo.musicVideoItems, musicVideoItem],
          );
        }

        _processed++;
        if (_processed % _progressUpdateInterval == 0) {
          _musicVideoResultsController.add(List.unmodifiable(_musicVideoResults));
          _emitProgress();
        }
      } catch (e) {
        print('Error processing music video file $path: $e');
        _processed++;
        continue;
      }

      if (_processed % _delayInterval == 0) {
        await Future.delayed(const Duration(milliseconds: 1));
      }
    }

    _musicVideoResultsController.add(List.unmodifiable(_musicVideoResults));
    _emitProgress();
  }

  Future<void> _scanPhotos(List<String> candidates) async {
    final imageExts = <String>{
      '.jpg',
      '.jpeg',
      '.png',
      '.gif',
      '.webp',
      '.bmp',
    };

    for (final path in candidates) {
      if (_cancelRequested) break;

      try {
        final file = File(path);
        final ext = file.path.split('.').last.toLowerCase();
        if (!imageExts.contains('.$ext')) {
          _processed++;
          continue;
        }

        final metadata = await Metadata.fromFile(file);
        final collectionName = file.parent.path
            .split(Platform.pathSeparator)
            .last;
        final collectionPath = file.parent.path;

        var photo = _photoResults.firstWhere(
          (p) => p.path == collectionPath && p.name == collectionName,
          orElse: () => Photo(
            path: collectionPath,
            parentPath: Directory(collectionPath).parent.path,
            name: collectionName,
          ),
        );

        final photoItem = PhotoItem(
          path: path,
          parentPath: file.parent.path,
          name: file.uri.pathSegments.last,
          metadata: metadata,
        );

        if (!_photoResults.contains(photo)) {
          _photoResults.add(photo.copyWith(photoItems: [photoItem]));
        } else {
          final index = _photoResults.indexOf(photo);
          _photoResults[index] = photo.copyWith(
            photoItems: [...photo.photoItems, photoItem],
          );
        }

        _processed++;
        if (_processed % _progressUpdateInterval == 0) {
          _photoResultsController.add(List.unmodifiable(_photoResults));
          _emitProgress();
        }
      } catch (e) {
        print('Error processing photo file $path: $e');
        _processed++;
        continue;
      }

      if (_processed % _delayInterval == 0) {
        await Future.delayed(const Duration(milliseconds: 1));
      }
    }

    _photoResultsController.add(List.unmodifiable(_photoResults));
    _emitProgress();
  }

  Future<void> _scanMixedContent(List<String> candidates) async {
    final videoExts = <String>{'.mp4', '.mkv', '.avi', '.mov', '.m4v', '.webm'};
    final audioExts = <String>{'.mp3', '.flac', '.wav', '.m4a', '.aac', '.ogg'};
    final imageExts = <String>{
      '.jpg',
      '.jpeg',
      '.png',
      '.gif',
      '.webp',
      '.bmp',
    };

    // Create containers for mixed content (one per type)
    final mixedVideos = MusicVideo(
      path: 'mixed-videos',
      parentPath: '',
      name: 'Mixed Videos',
      musicVideoItems: [],
    );

    final mixedAudio = Music(
      path: 'mixed-audio',
      parentPath: '',
      name: 'Mixed Audio',
      musicItems: [],
    );

    final mixedPhotos = Photo(
      path: 'mixed-photos',
      parentPath: '',
      name: 'Mixed Photos',
      photoItems: [],
    );

    for (final path in candidates) {
      if (_cancelRequested) break;

      try {
        final file = File(path);
        final ext = file.path.split('.').last.toLowerCase();
        final metadata = await Metadata.fromFile(file);
        final fileName = file.uri.pathSegments.last;

        if (videoExts.contains('.$ext')) {
          // Add as video item
          final videoItem = MusicVideoItem(
            path: path,
            parentPath: file.parent.path,
            name: fileName,
            metadata: metadata,
          );
          mixedVideos.musicVideoItems.add(videoItem);
        } else if (audioExts.contains('.$ext')) {
          // Add as audio item
          final audioItem = MusicItem(
            path: path,
            parentPath: file.parent.path,
            name: fileName,
            metadata: metadata,
          );
          mixedAudio.musicItems.add(audioItem);
        } else if (imageExts.contains('.$ext')) {
          // Add as photo item
          final photoItem = PhotoItem(
            path: path,
            parentPath: file.parent.path,
            name: fileName,
            metadata: metadata,
          );
          mixedPhotos.photoItems.add(photoItem);
        }

        _processed++;
        if (_processed % _progressUpdateInterval == 0) {
          if (mixedVideos.musicVideoItems.isNotEmpty) {
            _musicVideoResults.clear();
            _musicVideoResults.add(mixedVideos);
            _musicVideoResultsController.add(
              List.unmodifiable(_musicVideoResults),
            );
          }
          if (mixedAudio.musicItems.isNotEmpty) {
            _musicResults.clear();
            _musicResults.add(mixedAudio);
            _musicResultsController.add(List.unmodifiable(_musicResults));
          }
          if (mixedPhotos.photoItems.isNotEmpty) {
            _photoResults.clear();
            _photoResults.add(mixedPhotos);
            _photoResultsController.add(List.unmodifiable(_photoResults));
          }
          _emitProgress();
        }
      } catch (e) {
        print('Error processing mixed content file $path: $e');
        _processed++;
        continue;
      }

      if (_processed % _delayInterval == 0) {
        await Future.delayed(const Duration(milliseconds: 1));
      }
    }

    // Final update
    if (mixedVideos.musicVideoItems.isNotEmpty) {
      _musicVideoResults.clear();
      _musicVideoResults.add(mixedVideos);
      _musicVideoResultsController.add(List.unmodifiable(_musicVideoResults));
    }
    if (mixedAudio.musicItems.isNotEmpty) {
      _musicResults.clear();
      _musicResults.add(mixedAudio);
      _musicResultsController.add(List.unmodifiable(_musicResults));
    }
    if (mixedPhotos.photoItems.isNotEmpty) {
      _photoResults.clear();
      _photoResults.add(mixedPhotos);
      _photoResultsController.add(List.unmodifiable(_photoResults));
    }
    _emitProgress();
  }

  Future<List<String>> _collectCandidates(
    String rootDir,
    ContentType contentType,
  ) async {
    final files = <String>[];
    final dir = Directory(rootDir);
    if (!await dir.exists()) {
      print('Directory does not exist: $rootDir');
      return files;
    }

    // Determine file extensions based on content type
    final exts = <String>{};
    switch (contentType) {
      case ContentType.movie:
      case ContentType.tvSeries:
        exts.addAll({'.mp4', '.mkv', '.avi', '.mov', '.m4v', '.webm'});
        break;
      case ContentType.music:
        exts.addAll({'.mp3', '.flac', '.wav', '.m4a', '.aac', '.ogg'});
        break;
      case ContentType.musicVideo:
        exts.addAll({'.mp4', '.mkv', '.avi', '.mov', '.m4v', '.webm'});
        break;
      case ContentType.photo:
        exts.addAll({'.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'});
        break;
      case ContentType.mixed:
        exts.addAll({
          '.mp4',
          '.mkv',
          '.avi',
          '.mov',
          '.m4v',
          '.webm',
          '.mp3',
          '.flac',
          '.wav',
          '.m4a',
          '.aac',
          '.ogg',
          '.jpg',
          '.jpeg',
          '.png',
          '.gif',
          '.webp',
          '.bmp',
        });
        break;
    }

    try {
      // Use stream processing with batching for better memory efficiency
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (_cancelRequested) break;
        
        try {
          if (entity is File) {
            final ext = entity.path.split('.').last.toLowerCase();
            if (exts.contains('.$ext')) {
              files.add(entity.path);
              
              // Provide early progress feedback for large directories
              if (files.length % _fileDiscoveryFeedback == 0) {
                _statusController.add('Found ${files.length} files...');
              }
            }
          }
        } catch (e) {
          // Continue scanning even if individual entity fails
          print('Error processing entity ${entity.path}: $e');
          continue;
        }
      }
    } catch (e) {
      print('Error scanning directory $rootDir: $e');
      // Return whatever files we found before the error
    }
    
    return files;
  }

  _Parsed _parseMediaFromFilename(String filePath) {
    final fileName = filePath.split(Platform.pathSeparator).last;
    final noExt = fileName.replaceAll(RegExp(r'\.[^.]*$'), '');

    // Common TV patterns: S01E02, 1x02, Season 1 Episode 2, Ep 12
    final sxe = RegExp(r'[sS](\d{1,2})[ ._-]?[eE](\d{1,3})').firstMatch(noExt);
    final x = RegExp(r'(\d{1,2})x(\d{1,3})').firstMatch(noExt);

    // Year pattern
    final y = RegExp(r'(19|20)\d{2}').firstMatch(noExt);
    String? year = y?.group(0);

    bool isTv = false;
    int? season;
    int? episode;

    if (sxe != null) {
      isTv = true;
      season = int.tryParse(sxe.group(1)!);
      episode = int.tryParse(sxe.group(2)!);
    } else if (x != null) {
      isTv = true;
      season = int.tryParse(x.group(1)!);
      episode = int.tryParse(x.group(2)!);
    }

    // Try to extract season and episode using helper functions
    if (isTv && season == null) {
      final seasonStr = _extractSeason(filePath);
      if (seasonStr != null) {
        season = int.tryParse(seasonStr.replaceAll(RegExp(r'[^\d]'), ''));
      }
    }

    if (isTv && episode == null) {
      final episodeStr = _extractEpisodeNumber(filePath);
      if (episodeStr != null) {
        episode = int.tryParse(episodeStr.replaceAll(RegExp(r'[^\d]'), ''));
      }
    }

    // NEW LOGIC START: Check for " - (1)" pattern if not found yet
    if (episode == null) {
      final parenMatch = RegExp(r' - \((\d+)\)').firstMatch(noExt);
      if (parenMatch != null) {
        episode = int.tryParse(parenMatch.group(1)!);
        isTv = true; // Assume TV if it has this pattern
      }
    }
    // NEW LOGIC END

    // Try to extract a clean title by removing common tokens
    var name = noExt
        .replaceAll(RegExp(r'[._]'), ' ')
        .replaceAll(
          RegExp(
            r'\b(1080p|720p|480p|x264|x265|Bluray|WEBRip|WEB-DL|HEVC|H264|H265|AAC|DVDRip)\b',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(RegExp(r'[\[\(].*?[\]\)]'), '')
        .trim();

    // Remove season/episode tokens from name
    name = name
        .replaceAll(RegExp(r'[sS](\d{1,2})[ ._-]?[eE](\d{1,3})'), '')
        .replaceAll(RegExp(r'(\d{1,2})x(\d{1,3})'), '')
        .trim();

    // If year exists, keep it separate and remove from name tail
    if (year != null) {
      name = name.replaceAll(year, '').trim();
    }

    // Collapse multiple spaces
    name = name.replaceAll(RegExp(r'\s+'), ' ').trim();

    // For TV shows, try to extract series name using helper function
    if (isTv && episode != null) {
      final episodeId = 'E${episode.toString().padLeft(2, '0')}';
      final extractedName = _extractSeriesName(filePath, episodeId);
      if (extractedName != null && extractedName.isNotEmpty) {
        name = extractedName;
      }
    }

    // Clean up name again for Season stuff
    name = name.replaceAll(RegExp(r'\bS(\d+)\b', caseSensitive: false), '');
    name = name.replaceAll(
      RegExp(
        r'\b(?:Season\s*\d+|\d+(?:st|nd|rd|th)?\s*Season)\b',
        caseSensitive: false,
      ),
      '',
    );

    name = name
        .replaceAll(RegExp(r'-+$'), '')
        .trim(); // Remove trailing hyphens first

    // NEW LOGIC: Check for "Name N" where N is a number at the end, treating it as season
    if (isTv && season == null) {
      final endNumberMatch = RegExp(r'\s+(\d+)$').firstMatch(name);
      if (endNumberMatch != null) {
        season = int.tryParse(endNumberMatch.group(1)!);
        name = name.substring(0, endNumberMatch.start).trim();
      }
    }

    // NEW LOGIC: Extract season from name if present (e.g. "S5", "2nd Season")
    if (isTv && season == null) {
      // Check for "S5" or "Season 5" or "5th Season" in the original filename (noExt)
      // We use noExt because 'name' has been stripped of brackets

      // "S5" surrounded by spaces or end of string
      final sMatch = RegExp(
        r'\bS(\d+)\b',
        caseSensitive: false,
      ).firstMatch(noExt);
      if (sMatch != null) {
        season = int.tryParse(sMatch.group(1)!);
        // Remove S5 from name
        // name = name.replaceAll(RegExp(r'\bS\d+\b', caseSensitive: false), '').trim(); // Already done above
      }

      // "2nd Season", "Season 2"
      final seasonMatch = RegExp(
        r'\b(?:Season\s*(\d+)|(\d+)(?:st|nd|rd|th)?\s*Season)\b',
        caseSensitive: false,
      ).firstMatch(noExt);
      if (seasonMatch != null) {
        final sNum = seasonMatch.group(1) ?? seasonMatch.group(2);
        if (sNum != null) {
          season = int.tryParse(sNum);
        }
      }
    }

    name = name.replaceAll(RegExp(r'\s+'), ' ').trim();

    return _Parsed(
      name: name,
      isTv: isTv,
      season: season,
      episode: episode,
      year: year,
    );
  }

  // --- Series Helpers (Unchanged) ---
  // ignore: unused_element
  String? _extractQuality(String url) {
    final match = RegExp(
      r'(1080p|720p|540p|480p|Dubbed)',
      caseSensitive: false,
    ).firstMatch(url);
    return match?.group(1);
  }

  String? _extractSeason(String url) {
    final match = RegExp(r'/S(\d+)/', caseSensitive: false).firstMatch(url);
    if (match != null) {
      return 'S${int.parse(match.group(1)!).toString().padLeft(2, '0')}';
    }
    return null;
  }

  String? _extractEpisodeNumber(String url) {
    final filename = url.split('/').last;
    RegExpMatch? match;

    match = RegExp(r'S\d+E(\d+)', caseSensitive: false).firstMatch(filename);
    if (match != null) {
      return 'E${int.parse(match.group(1)!).toString().padLeft(2, '0')}';
    }

    match = RegExp(
      r'Ep(?:isode)?\.?(\d+)',
      caseSensitive: false,
    ).firstMatch(filename);
    if (match != null) {
      return 'E${int.parse(match.group(1)!).toString().padLeft(2, '0')}';
    }

    match = RegExp(r'(?<!\d)(?<!p)[._-](\d{2,3})[._-]').firstMatch(filename);
    if (match != null) {
      return 'E${int.parse(match.group(1)!).toString().padLeft(2, '0')}';
    }

    match = RegExp(r'\.(\d{2,3})\.').firstMatch(filename);
    if (match != null && !_isQualityString(match.group(0)!)) {
      return 'E${int.parse(match.group(1)!).toString().padLeft(2, '0')}';
    }

    return null;
  }

  String? _extractSeriesName(String url, String episodeId) {
    final filename = Uri.decodeComponent(url.split('/').last);
    final stopIndex = filename.indexOf(episodeId.split('E')[0]);
    if (stopIndex != -1) {
      return filename.substring(0, stopIndex).replaceAll('.', ' ').trim();
    }
    return null;
  }

  bool _isQualityString(String text) => RegExp(r'\d+p').hasMatch(text);

  /// Fetch TMDB metadata for all scanned movies and series.
  /// Updates the cache with TMDB IDs, titles, poster paths, etc.
  Future<void> fetchTmdbMetadata() async {
    if (_isFetchingMetadata || _isScanning) return;

    _isFetchingMetadata = true;
    _cancelRequested = false;
    _processed = 0;

    // Count items to fetch
    _totalCandidates = _movieResults.length + _tvResults.length;
    print('🎬 TMDB Fetch Started - Total items: $_totalCandidates');
    if (_totalCandidates == 0) {
      _isFetchingMetadata = false;
      _statusController.add('No content to fetch metadata for');
      print('❌ No content to fetch');
      return;
    }

    _statusController.add('Fetching TMDB metadata...');
    _emitProgress();

    final index = await _indexService.load();
    bool indexChanged = false;
    print('📊 Index loaded with ${index.entries.length} entries');

    // Fetch metadata for movies
    print(
      '🎥 Starting movie metadata fetch (${_movieResults.length} movies)...',
    );
    for (int i = 0; i < _movieResults.length; i++) {
      if (_cancelRequested) break;

      final movie = _movieResults[i];
      print('  [${i + 1}/${_movieResults.length}] Fetching: "${movie.name}"');
      try {
        final updatedMovie = await _matchMovieWithTmdb(movie, null);
        _movieResults[i] = updatedMovie;

        print('    ✅ Found TMDB ID: ${updatedMovie.fetchedData.tmdbId}');
        print('    📽️  Title: ${updatedMovie.fetchedData.title}');
        print('    🖼️  Poster: ${updatedMovie.fetchedData.posterPath}');

        // Update index entries for this movie's files
        if (updatedMovie.fetchedData.tmdbId != null) {
          for (final item in updatedMovie.movieItems) {
            final key = LocalScanIndex.makeKey(
              movie.parentPath,
              'movie',
              item.path,
            );
            final existing = index.entries[key];
            if (existing != null) {
              index.entries[key] = existing.copyWith(
                tmdbId: updatedMovie.fetchedData.tmdbId,
                tmdbTitle: updatedMovie.fetchedData.title,
                tmdbOriginalTitle: updatedMovie.fetchedData.originalTitle,
                tmdbPosterPath: updatedMovie.fetchedData.posterPath,
                tmdbBackdropPath: updatedMovie.fetchedData.backdropPath,
                tmdbOverview: updatedMovie.fetchedData.overview,
                tmdbYear: updatedMovie.fetchedData.year,
              );
              indexChanged = true;
              print('    💾 Index updated for: ${item.name}');
            }
          }
        } else {
          print('    ⚠️  No TMDB match found');
        }
      } catch (e) {
        print('    ❌ Error fetching: $e');
      }

      _processed++;
      // Optimize: Update UI less frequently (every 5 items instead of 3)
      if (_processed % _metadataUpdateInterval == 0) {
        _movieResultsController.add(List.unmodifiable(_movieResults));
        _emitProgress();
      }
      await Future.delayed(const Duration(milliseconds: 500)); // Rate limit
    }

    // Fetch metadata for TV series
    print(
      '📺 Starting TV series metadata fetch (${_tvResults.length} series)...',
    );
    for (int i = 0; i < _tvResults.length; i++) {
      if (_cancelRequested) break;

      final series = _tvResults[i];
      print('  [${i + 1}/${_tvResults.length}] Fetching: "${series.name}"');
      try {
        final updatedSeries = await _matchTvWithTmdb(series, null);
        _tvResults[i] = updatedSeries;

        print('    ✅ Found TMDB ID: ${updatedSeries.fetchedData.tmdbId}');
        print('    📽️  Title: ${updatedSeries.fetchedData.title}');
        print('    🖼️  Poster: ${updatedSeries.fetchedData.posterPath}');

        // Update index entries for this series' episodes
        if (updatedSeries.fetchedData.tmdbId != null) {
          for (final season in updatedSeries.seasons) {
            for (final episode in season.episodes) {
              final key = LocalScanIndex.makeKey(
                series.parentPath,
                'tvSeries',
                episode.path,
              );
              final existing = index.entries[key];
              if (existing != null) {
                index.entries[key] = existing.copyWith(
                  tmdbId: updatedSeries.fetchedData.tmdbId,
                  tmdbTitle: updatedSeries.fetchedData.title,
                  tmdbOriginalTitle: updatedSeries.fetchedData.originalTitle,
                  tmdbPosterPath: updatedSeries.fetchedData.posterPath,
                  tmdbBackdropPath: updatedSeries.fetchedData.backdropPath,
                  tmdbOverview: updatedSeries.fetchedData.overview,
                  tmdbYear: updatedSeries.fetchedData.year,
                );
                indexChanged = true;
                print('    💾 Index updated for: ${episode.name}');
              }
            }
          }
        } else {
          print('    ⚠️  No TMDB match found');
        }
      } catch (e) {
        print('    ❌ Error fetching: $e');
      }

      _processed++;
      // Optimize: Update UI less frequently (every 5 items instead of 3)
      if (_processed % _metadataUpdateInterval == 0) {
        _tvResultsController.add(List.unmodifiable(_tvResults));
        _emitProgress();
      }
      await Future.delayed(const Duration(milliseconds: 500)); // Rate limit
    }

    // Save updated index if any metadata was fetched
    if (indexChanged) {
      print('💿 Saving updated index to cache...');
      try {
        await _indexService.save(index);
        print('✅ Index saved successfully');
      } catch (e) {
        print('❌ Error saving index: $e');
      }
    } else {
      print('ℹ️  No changes to index, skipping save');
    }

    // Final update to ensure all results are visible
    _movieResultsController.add(List.unmodifiable(_movieResults));
    _tvResultsController.add(List.unmodifiable(_tvResults));

    _isFetchingMetadata = false;
    final finalStatus = _cancelRequested
        ? 'Metadata fetch cancelled'
        : 'TMDB metadata fetched';
    print('🏁 TMDB Fetch Completed - $finalStatus');
    _statusController.add(finalStatus);
  }

  /// Normalize folder names for TMDB matching
  /// Examples:
  /// - The.Quintessential.Quintuplets => The-Quintessential-Quintuplets
  /// - The Quintessential Quintuplets => The-Quintessential-Quintuplets
  /// - The Quintessential Quintuplets 2012 => The-Quintessential-Quintuplets
  /// - The Quintessential Quintuplets 720p => The-Quintessential-Quintuplets
  /// - Narnia: Aslan Came Back => Narnia-Aslan-Came-Back
  /// - Spider-Man => Spider-Man (unchanged)
  String _normalizeFolderNameForTmdb(String folderName) {
    var normalized = folderName;

    // Remove single quotes (apostrophes)
    normalized = normalized.replaceAll("'", '');

    // Replace colons with hyphens
    normalized = normalized.replaceAll(':', '-');

    // Replace dots and spaces with hyphens
    normalized = normalized.replaceAll(RegExp(r'[.\s]+'), '-');

    // Remove year patterns (1900-2099)
    normalized = normalized.replaceAll(RegExp(r'-(?:19|20)\d{2}(?=-|$)'), '');

    // Remove quality patterns (720p, 1080p, bluray, webrip, etc.)
    normalized = normalized.replaceAll(
      RegExp(
        r'-(?:480p|720p|1080p|2160p|4k|bluray|webrip|web-dl|dvdrip|hdtv|bdrip|x264|x265|hevc)(?=-|$)',
        caseSensitive: false,
      ),
      '',
    );

    // Remove resolution patterns (1920x1080, etc.)
    normalized = normalized.replaceAll(RegExp(r'-\d{3,4}x\d{3,4}(?=-|$)'), '');

    // Clean up multiple consecutive hyphens
    normalized = normalized.replaceAll(RegExp(r'-+'), '-');

    // Remove leading/trailing hyphens
    normalized = normalized.trim();
    if (normalized.startsWith('-')) {
      normalized = normalized.substring(1);
    }
    if (normalized.endsWith('-')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }

    return normalized;
  }

  final MovieService _movieService = MovieService();
  Future<Movie> _matchMovieWithTmdb(Movie movie, String? year) async {
    final resp = await _movieService.searchMovies(movie.name);
    if (resp.results.isNotEmpty) {
      final best = resp.results.first;

      return movie.copyWith(
        fetchedData: FetchedData(
          tmdbId: int.parse('${best.tmdbId??best.malId??best.anilistId??best.movieId??best.id}'),
          title: best.metaData.title,
          originalTitle: best.moviedetail.originalTitle,
          posterPath: best.moviedetail.posterPath,
          backdropPath: best.moviedetail.backdropPath,
          overview: best.moviedetail.overview,
          year: best.moviedetail.releaseDate,
        ),
      );
    }
    return movie;
  }

  Future<TvSeries> _matchTvWithTmdb(TvSeries series, String? year) async {
    final resp = await _movieService.searchTvShows( series.name);
    if (resp.results.isNotEmpty) {
      final best = resp.results.first;
      return series.copyWith(
        fetchedData: FetchedData(
          tmdbId: best.id as int?,
       title: best.tvDetails?.name,
          originalTitle: best.tvDetails?.originalName,
          posterPath: best.tvDetails?.posterPath,
          backdropPath: best.tvDetails?.backdropPath,
          overview: best.tvDetails?.overview,
          year: best.tvDetails?.firstAirDate,
        ),
      );
    }
    return series;
  }

  void _emitProgress() {
    final p = progress;
    _progressController.add(p.isNaN ? 0.0 : p);
  }
}

class _Parsed {
  final String name;
  final bool isTv;
  final int? season;
  final int? episode;
  final String? year;

  _Parsed({
    required this.name,
    required this.isTv,
    this.season,
    this.episode,
    this.year,
  });
}
