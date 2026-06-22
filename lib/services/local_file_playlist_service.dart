import 'dart:io';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path/path.dart' as p;

class LocalFilePlaylistService {
  /// Video file extensions supported by media_kit
  static const List<String> videoExtensions = [
    'mp4',
    'mkv',
    'avi',
    'mov',
    'flv',
    'wmv',
    'webm',
    'mpg',
    'mpeg',
    'mts',
    '3gp',
    'vob',
  ];
  static const List<String> audioExtensions = [
    'mp3',
    'ogg',
    'flac',
    'wav',
    'aac',
  ];

  /// Scan parent folder for video files and create playlist
  static Future<List<Media>> buildPlaylistFromFolder(
    String filePath,
    String targetList,
  ) async {
    try {
      final parentPath = p.dirname(filePath);
      final currentFileName = p.basename(filePath);

      final parentDir = Directory(parentPath);

      if (!await parentDir.exists()) {
        debugPrint('Parent directory does not exist: $parentPath');
        return [];
      }

      // Step 1: Scan for video files
      debugPrint('Scanning folder: $parentPath');
      final files = await parentDir.list().toList();

      // Step 2: Filter video files and sort by default A-Z 0-9
      final videoFiles =
          files.whereType<File>().where((file) {
              final ext = p
                  .extension(file.path)
                  .toLowerCase()
                  .replaceFirst('.', '');
              return videoExtensions.contains(ext);
            }).toList()
            ..sort((a, b) => p.basename(a.path).compareTo(p.basename(b.path)));
      final audioFiles =
          files.whereType<File>().where((file) {
              final ext = p
                  .extension(file.path)
                  .toLowerCase()
                  .replaceFirst('.', '');
              return audioExtensions.contains(ext);
            }).toList()
            ..sort((a, b) => p.basename(a.path).compareTo(p.basename(b.path)));

      debugPrint(
        'Found ${videoFiles.length} video files in $parentPath (sorted A-Z 0-9)',
      );
      videoFiles.forEach((f) => debugPrint('  - ${p.basename(f.path)}'));

      // Step 3: Find current file index in sorted list
      int currentFileIndex = -1;
      if (targetList == "video") {
        for (int i = 0; i < videoFiles.length; i++) {
          if (p.basename(videoFiles[i].path) == currentFileName) {
            currentFileIndex = i;
            debugPrint('Current file index in sorted list: $currentFileIndex');
            break;
          }
        }
      } else {
for (int i = 0; i < audioFiles.length; i++) {
          if (p.basename(videoFiles[i].path) == currentFileName) {
            currentFileIndex = i;
            debugPrint('Current file index in sorted list: $currentFileIndex');
            break;
          }
        }


      }
      if (currentFileIndex == -1) {
        debugPrint(
          'Current file not found in scanned files, using original order',
        );
        currentFileIndex = 0;
      }

      // Step 4: Reorganize playlist: start from current file, move earlier files to end
      final reorganizedFiles = <File>[];

      // Add files from current index onwards
      reorganizedFiles.addAll(targetList=="video"? videoFiles.sublist(currentFileIndex):audioFiles.sublist(currentFileIndex));

      // Add files before current index to the end
      if (currentFileIndex > 0) {
        reorganizedFiles.addAll(targetList=="video"?videoFiles.sublist(0, currentFileIndex):audioFiles.sublist(0,currentFileIndex));
        debugPrint(
          'Moved ${currentFileIndex} files before current to end of playlist',
        );
      }

      debugPrint('Reorganized playlist order:');
      reorganizedFiles.forEach((f) => debugPrint('  - ${p.basename(f.path)}'));

      // Convert to Media objects
      final mediaList = reorganizedFiles
          .map((file) => Media(Uri.decodeComponent(file.path)))
          .toList();

      return mediaList;
    } catch (e) {
      debugPrint('Error building playlist from folder: $e');
      return [];
    }
  }

  /// Find the index of current file in the reorganized playlist
  /// Since playlist starts from current file, this should always return 0
  static int findCurrentFileIndex(
    List<Media> playlist,
    String currentFilePath,
  ) {
    try {
      // After reorganization, current file should always be at index 0
      // But we verify it just in case
      final currentFileName = p.basename(currentFilePath);

      for (int i = 0; i < playlist.length; i++) {
        final mediaPath = playlist[i].uri.toString();
        final mediaFileName = p.basename(mediaPath);

        if (mediaFileName == currentFileName) {
          debugPrint('Found current file at index $i in reorganized playlist');
          return i;
        }
      }

      // Should not reach here if reorganization worked correctly
      debugPrint(
        'Warning: Current file not found in playlist, defaulting to index 0',
      );
      return 0;
    } catch (e) {
      debugPrint('Error finding current file index: $e');
      return 0;
    }
  }

  /// Load playlist into player (replaces current playback)
  static Future<void> loadPlaylistToPlayer(
    Player player,
    List<Media> playlist,
    int startIndex,
  ) async {
    try {
      if (playlist.isEmpty) {
        debugPrint('Playlist is empty, cannot load');
        return;
      }

      // Ensure startIndex is valid
      final validIndex = startIndex.clamp(0, playlist.length - 1);

      player.open(Playlist(playlist), play: false);

      debugPrint(
        'Loaded playlist with ${playlist.length} items, starting at index $validIndex',
      );
    } catch (e) {
      debugPrint('Error loading playlist to player: $e');
    }
  }

  /// Build and load local file playlist in background
  /// Returns true if playlist was successfully loaded, false otherwise
  static Future<bool> buildAndLoadLocalPlaylist({
    required Player player,
    required String currentFilePath,
    required bool isLocalSource,
    required String targetList
  }) async {
    if (!isLocalSource) {
      debugPrint('Not a local source, skipping playlist generation');
      return false;
    }

    try {
      debugPrint('Building playlist for local file: $currentFilePath');

      // Build playlist from folder
      final playlist = await buildPlaylistFromFolder(currentFilePath,targetList);

      if (playlist.isEmpty) {
        debugPrint('No video files found in folder');
        return false;
      }

      // Find current file index
      final currentIndex = findCurrentFileIndex(playlist, currentFilePath);

      // Load playlist into player
      await loadPlaylistToPlayer(player, playlist, currentIndex);

      return true;
    } catch (e) {
      debugPrint('Error in buildAndLoadLocalPlaylist: $e');
      return false;
    }
  }
}
