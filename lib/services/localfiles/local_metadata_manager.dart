import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import '../../models/local_library/local_scan_index.dart';
import 'local_scan_index_service.dart';
import '../contentApi/movie_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class LocalMetadataManager {
  final LocalScanIndexService _indexService;
  final MovieService _movieService;

  LocalMetadataManager(this._indexService, this._movieService);

  Future<void> downloadMetadata(LocalScanIndexEntry entry) async {
    if (entry.tmdbId == null) return;

    final appDir = await getApplicationSupportDirectory();
    final metadataDir = Directory(
      p.join(appDir.path, 'metadata', entry.tmdbId.toString()),
    );
    if (!await metadataDir.exists()) {
      await metadataDir.create(recursive: true);
    }

    String? localPosterPath;
    String? localBackdropPath;

    // Download Poster
    if (entry.tmdbPosterPath != null) {
      final posterUrl =
          'https://image.tmdb.org/t/p/w500${entry.tmdbPosterPath}';
      final posterFile = File(p.join(metadataDir.path, 'poster.jpg'));
      if (!await posterFile.exists()) {
        try {
          final response = await http.get(Uri.parse(posterUrl));
          if (response.statusCode == 200) {
            await posterFile.writeAsBytes(response.bodyBytes);
            localPosterPath = posterFile.path;
          }
        } catch (e) {
          print('Error downloading poster: $e');
        }
      } else {
        localPosterPath = posterFile.path;
      }
    }

    // Download Backdrop
    if (entry.tmdbBackdropPath != null) {
      final backdropUrl =
          'https://image.tmdb.org/t/p/w780${entry.tmdbBackdropPath}';
      final backdropFile = File(p.join(metadataDir.path, 'backdrop.jpg'));
      if (!await backdropFile.exists()) {
        try {
          final response = await http.get(Uri.parse(backdropUrl));
          if (response.statusCode == 200) {
            await backdropFile.writeAsBytes(response.bodyBytes);
            localBackdropPath = backdropFile.path;
          }
        } catch (e) {
          print('Error downloading backdrop: $e');
        }
      } else {
        localBackdropPath = backdropFile.path;
      }
    }

    // Download Details
    final detailsFile = File(p.join(metadataDir.path, 'details.json'));
    if (!await detailsFile.exists()) {
      try {
        Map<String, dynamic>? details;
        if (entry.tmdbMediaType == 'movie') {
          details = await _movieService.getRawMovieDetails(
            movieId: entry.tmdbId!,
          );
        } else if (entry.tmdbMediaType == 'tv') {
          details = await _movieService.getRawTvShowDetails(
            tvShowId: entry.tmdbId!,
          );
        }

        if (details != null) {
          await detailsFile.writeAsString(jsonEncode(details));
        }
      } catch (e) {
        print('Error downloading details: $e');
      }
    }

    // Update index
    await _indexService.updateLocalAssets(
      entry.path,
      localPosterPath: localPosterPath,
      localBackdropPath: localBackdropPath,
    );
  }
}
