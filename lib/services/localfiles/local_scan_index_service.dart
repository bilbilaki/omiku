import 'dart:convert';
import 'dart:io';

import '../../models/local_library/directory_entry.dart';
import '../../models/local_library/local_scan_index.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Service responsible for persisting a lightweight JSON index of
/// scanned local media files.
///
/// The goal is to cheaply detect changes between scans and keep a
/// simple on-disk database that other parts of the app can read
/// without needing to rescan the file system.
class LocalScanIndexService {
  static const _fileName = 'local_scan_index.json';

  /// Keeps an in-memory copy of the index for the current app session so we
  /// avoid repeatedly deserializing the JSON file and can short-circuit TMDB
  /// lookups once metadata has been fetched.
  static LocalScanIndex? _sessionIndex;
  static Map<String, LocalScanIndexEntry> _sessionEntries =
      <String, LocalScanIndexEntry>{};
  static bool _sessionDirty = false;

  const LocalScanIndexService();

  Future<File> _getIndexFile() async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, _fileName));
  }

  /// Load the current index from disk (or memory if already hydrated).
  /// Returns an empty index if the file does not exist or cannot be parsed.
  Future<LocalScanIndex> load({bool forceRefresh = false}) async {
    if (!forceRefresh && _sessionIndex != null) {
      return _sessionIndex!;
    }

    try {
      final file = await _getIndexFile();
      if (!await file.exists()) {
        return _hydrateSession(LocalScanIndex());
      }
      final text = await file.readAsString();
      if (text.trim().isEmpty) {
        return _hydrateSession(LocalScanIndex());
      }
      final json = jsonDecode(text) as Map<String, dynamic>;
      return _hydrateSession(LocalScanIndex.fromJson(json));
    } catch (_) {
      // Corrupt or unreadable index; start fresh.
      return _hydrateSession(LocalScanIndex());
    }
  }

  /// Persist the provided index to disk, overwriting any previous
  /// contents.
  Future<void> save(LocalScanIndex index) async {
    try {
      final file = await _getIndexFile();
      await file.create(recursive: true);
      final json = index.toJson();
      await file.writeAsString(jsonEncode(json));
      _sessionDirty = false;
      _hydrateSession(index);
    } catch (_) {
      // Best-effort cache; ignore IO errors.
    }
  }

  /// Update the index for a specific scan [rootDir] & [contentType]
  /// given the list of [candidates] discovered on disk.
  ///
  /// This will:
  /// - add or update entries whose size/modified timestamps changed
  /// - remove entries that no longer exist under this root/contentType
  /// - only write the JSON file if something actually changed
  Future<LocalScanIndex> updateForScan(
    String rootDir,
    ContentType contentType,
    List<String> candidates,
  ) async {
    final index = await load();
    final entries = index.entries;
    final contentTypeName = contentType.name;
    var changed = false;

    // Track which paths are still present for this root/type so we
    // can prune stale entries afterwards.
    final currentPaths = <String>{};

    for (final path in candidates) {
      final file = File(path);
      if (!file.existsSync()) {
        continue;
      }
      final stat = await file.stat();
      currentPaths.add(path);

      final key = LocalScanIndex.makeKey(rootDir, contentTypeName, path);
      final existing = entries[key];

      if (existing != null &&
          existing.sizeBytes == stat.size &&
          existing.modified.isAtSameMomentAs(stat.modified)) {
        // Unchanged; keep existing entry.
        continue;
      }

      entries[key] = LocalScanIndexEntry(
        path: path,
        rootDir: rootDir,
        contentType: contentTypeName,
        sizeBytes: stat.size,
        modified: stat.modified,
      );
      changed = true;
    }

    // Remove entries for files that disappeared for this
    // rootDir/contentType pair.
    final keysToRemove = <String>[];
    entries.forEach((key, entry) {
      if (entry.rootDir == rootDir &&
          entry.contentType == contentTypeName &&
          !currentPaths.contains(entry.path)) {
        keysToRemove.add(key);
      }
    });

    if (keysToRemove.isNotEmpty) {
      changed = true;
      for (final k in keysToRemove) {
        entries.remove(k);
      }
    }

    if (changed) {
      await save(index);
    } else {
      _hydrateSession(index);
    }

    return index;
  }

  /// Clear all in-memory caches forcing the next [load] to hit disk.
  Future<void> clearSessionCache() async {
    _sessionIndex = null;
    _sessionEntries = <String, LocalScanIndexEntry>{};
    _sessionDirty = false;
  }

  /// Flush any pending in-memory mutations to disk.
  Future<void> flushSessionCache() async {
    if (_sessionDirty && _sessionIndex != null) {
      await save(_sessionIndex!);
    }
  }

  /// Return the cached entry for a specific file if available. When
  /// [loadFromDiskIfMissing] is true the index will be hydrated from disk the
  /// first time the entry is requested this session.
  Future<LocalScanIndexEntry?> getCachedEntry({
    required String rootDir,
    required ContentType contentType,
    required String path,
    bool loadFromDiskIfMissing = true,
  }) async {
    final key = LocalScanIndex.makeKey(rootDir, contentType.name, path);
    final cached = _sessionEntries[key];
    if (cached != null) {
      return cached;
    }

    if (!loadFromDiskIfMissing) {
      return null;
    }

    final index = await load();
    final entry = index.entries[key];
    if (entry != null) {
      _sessionEntries[key] = entry;
    }
    return entry;
  }

  /// Quick helper to determine if a file already has TMDB metadata cached for
  /// the current session (or persisted on disk).
  Future<bool> hasCachedTmdbMetadata({
    required String rootDir,
    required ContentType contentType,
    required String path,
  }) async {
    final entry = await getCachedEntry(
      rootDir: rootDir,
      contentType: contentType,
      path: path,
    );
    return entry?.tmdbId != null;
  }

  /// Update the TMDB metadata for a particular entry. By default this only
  /// mutates the in-memory representation so multiple updates can be batched
  /// before calling [flushSessionCache]. Set [persistImmediately] to true if
  /// the change should be written to disk right away.
  Future<LocalScanIndexEntry?> upsertTmdbMetadata({
    required String rootDir,
    required ContentType contentType,
    required String path,
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
    bool persistImmediately = false,
  }) async {
    final index = await load();
    final key = LocalScanIndex.makeKey(rootDir, contentType.name, path);
    final existing = index.entries[key];
    if (existing == null) {
      return null;
    }

    final updated = existing.copyWith(
      tmdbId: tmdbId,
      tmdbTitle: tmdbTitle,
      tmdbOriginalTitle: tmdbOriginalTitle,
      tmdbPosterPath: tmdbPosterPath,
      tmdbBackdropPath: tmdbBackdropPath,
      tmdbOverview: tmdbOverview,
      tmdbYear: tmdbYear,
      tmdbMediaType: tmdbMediaType,
      localPosterPath: localPosterPath,
      localBackdropPath: localBackdropPath,
    );

    if (_metadataEquals(existing, updated)) {
      _sessionEntries[key] = existing;
      return existing;
    }

    index.entries[key] = updated;
    _sessionEntries[key] = updated;
    _sessionDirty = !persistImmediately;

    if (persistImmediately) {
      await save(index);
    }

    return updated;
  }

  Future<void> updateLocalAssets(
    String path, {
    String? localPosterPath,
    String? localBackdropPath,
  }) async {
    final index = await load();
    // We need to find the entry by path. Since the key includes rootDir and contentType,
    // and we only have path here, we might need to iterate or pass more info.
    // However, path should be unique enough if we assume full path.
    // But the map key is composite.

    // Let's iterate to find the key.
    String? key;
    for (final k in index.entries.keys) {
      if (index.entries[k]?.path == path) {
        key = k;
        break;
      }
    }

    if (key == null) return;

    final existingEntry = index.entries[key];
    if (existingEntry == null) return;

    final updatedEntry = existingEntry.copyWith(
      localPosterPath: localPosterPath,
      localBackdropPath: localBackdropPath,
    );

    index.entries[key] = updatedEntry;
    _sessionEntries[key] = updatedEntry;
    await save(index);
  }

  /// Internal helper to sync [_sessionIndex] & [_sessionEntries].
  LocalScanIndex _hydrateSession(LocalScanIndex index) {
    _sessionIndex = index;
    _sessionEntries = index.entries;
    return index;
  }

  bool _metadataEquals(LocalScanIndexEntry a, LocalScanIndexEntry b) {
    return a.tmdbId == b.tmdbId &&
        a.tmdbTitle == b.tmdbTitle &&
        a.tmdbOriginalTitle == b.tmdbOriginalTitle &&
        a.tmdbPosterPath == b.tmdbPosterPath &&
        a.tmdbBackdropPath == b.tmdbBackdropPath &&
        a.tmdbOverview == b.tmdbOverview &&
        a.tmdbYear == b.tmdbYear &&
        a.tmdbMediaType == b.tmdbMediaType &&
        a.localPosterPath == b.localPosterPath &&
        a.localBackdropPath == b.localBackdropPath;
  }
}
