/// Lightweight on-disk index describing scanned local files.
///
/// This is intentionally simple and decoupled from the in-memory domain
/// models (Movie, TvSeries, etc.) so it can be evolved without
/// touching the UI layer.
class LocalScanIndexEntry {
  final String path; // Full file path
  final String rootDir; // Scan root this file belonged to
  final String contentType; // directory_entry.ContentType name
  final int sizeBytes;
  final DateTime modified;

  // TMDB metadata (optional, fetched on demand)
  final int? tmdbId;
  final String? tmdbTitle;
  final String? tmdbOriginalTitle;
  final String? tmdbPosterPath;
  final String? tmdbBackdropPath;
  final String? tmdbOverview;
  final String? tmdbYear;
  final String? tmdbMediaType; // 'movie' or 'tv'

  // Local offline assets
  final String? localPosterPath;
  final String? localBackdropPath;

  const LocalScanIndexEntry({
    required this.path,
    required this.rootDir,
    required this.contentType,
    required this.sizeBytes,
    required this.modified,
    this.tmdbId,
    this.tmdbTitle,
    this.tmdbOriginalTitle,
    this.tmdbPosterPath,
    this.tmdbBackdropPath,
    this.tmdbOverview,
    this.tmdbYear,
    this.tmdbMediaType,
    this.localPosterPath,
    this.localBackdropPath,
  });

  LocalScanIndexEntry copyWith({
    String? path,
    String? rootDir,
    String? contentType,
    int? sizeBytes,
    DateTime? modified,
    int? tmdbId,
    String? tmdbTitle,
    String? tmdbOriginalTitle,
    String? tmdbPosterPath,
    String? tmdbBackdropPath,
    String? tmdbOverview,
    String? tmdbYear,
    String? tmdbMediaType,
    String? localPosterPath,
    String? localBackdropPath,
  }) {
    return LocalScanIndexEntry(
      path: path ?? this.path,
      rootDir: rootDir ?? this.rootDir,
      contentType: contentType ?? this.contentType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      modified: modified ?? this.modified,
      tmdbId: tmdbId ?? this.tmdbId,
      tmdbTitle: tmdbTitle ?? this.tmdbTitle,
      tmdbOriginalTitle: tmdbOriginalTitle ?? this.tmdbOriginalTitle,
      tmdbPosterPath: tmdbPosterPath ?? this.tmdbPosterPath,
      tmdbBackdropPath: tmdbBackdropPath ?? this.tmdbBackdropPath,
      tmdbOverview: tmdbOverview ?? this.tmdbOverview,
      tmdbYear: tmdbYear ?? this.tmdbYear,
      tmdbMediaType: tmdbMediaType ?? this.tmdbMediaType,
      localPosterPath: localPosterPath ?? this.localPosterPath,
      localBackdropPath: localBackdropPath ?? this.localBackdropPath,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'path': path,
    'rootDir': rootDir,
    'contentType': contentType,
    'sizeBytes': sizeBytes,
    'modified': modified.toIso8601String(),
    if (tmdbId != null) 'tmdbId': tmdbId,
    if (tmdbTitle != null) 'tmdbTitle': tmdbTitle,
    if (tmdbOriginalTitle != null) 'tmdbOriginalTitle': tmdbOriginalTitle,
    if (tmdbPosterPath != null) 'tmdbPosterPath': tmdbPosterPath,
    if (tmdbBackdropPath != null) 'tmdbBackdropPath': tmdbBackdropPath,
    if (tmdbOverview != null) 'tmdbOverview': tmdbOverview,
    if (tmdbYear != null) 'tmdbYear': tmdbYear,
    if (tmdbMediaType != null) 'tmdbMediaType': tmdbMediaType,
    if (localPosterPath != null) 'localPosterPath': localPosterPath,
    if (localBackdropPath != null) 'localBackdropPath': localBackdropPath,
  };

  factory LocalScanIndexEntry.fromJson(Map<String, dynamic> json) {
    return LocalScanIndexEntry(
      path: json['path'] as String,
      rootDir: json['rootDir'] as String,
      contentType: json['contentType'] as String,
      sizeBytes: json['sizeBytes'] as int,
      modified: DateTime.parse(json['modified'] as String),
      tmdbId: json['tmdbId'] as int?,
      tmdbTitle: json['tmdbTitle'] as String?,
      tmdbOriginalTitle: json['tmdbOriginalTitle'] as String?,
      tmdbPosterPath: json['tmdbPosterPath'] as String?,
      tmdbBackdropPath: json['tmdbBackdropPath'] as String?,
      tmdbOverview: json['tmdbOverview'] as String?,
      tmdbYear: json['tmdbYear'] as String?,
      tmdbMediaType: json['tmdbMediaType'] as String?,
      localPosterPath: json['localPosterPath'] as String?,
      localBackdropPath: json['localBackdropPath'] as String?,
    );
  }
}

/// Container for all indexed files stored on disk.
class LocalScanIndex {
  /// Map key is a stable composite of rootDir, contentType and path.
  final Map<String, LocalScanIndexEntry> entries;

  LocalScanIndex({Map<String, LocalScanIndexEntry>? entries})
    : entries = entries ?? <String, LocalScanIndexEntry>{};

  /// Serialize to JSON map suitable for jsonEncode.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'entries': entries.values.map((e) => e.toJson()).toList(),
    };
  }

  /// Deserialize from JSON map created by [toJson].
  factory LocalScanIndex.fromJson(Map<String, dynamic> json) {
    final list = (json['entries'] as List?) ?? const [];
    final map = <String, LocalScanIndexEntry>{};
    for (final item in list) {
      if (item is Map<String, dynamic>) {
        final entry = LocalScanIndexEntry.fromJson(item);
        final key = LocalScanIndex.makeKey(
          entry.rootDir,
          entry.contentType,
          entry.path,
        );
        map[key] = entry;
      }
    }
    return LocalScanIndex(entries: map);
  }

  /// Utility to build the composite key consistently. Public so that
  /// services can generate keys in the same way this model does.
  static String makeKey(String rootDir, String contentType, String path) =>
      '$rootDir|$contentType|$path';

  /// Get a stable key for a given entry.
  String keyFor(LocalScanIndexEntry entry) =>
      makeKey(entry.rootDir, entry.contentType, entry.path);

  /// Helper to access entries for a specific root + content type pair.
  Iterable<LocalScanIndexEntry> entriesFor(String rootDir, String contentType) {
    return entries.values.where(
      (e) => e.rootDir == rootDir && e.contentType == contentType,
    );
  }
}
