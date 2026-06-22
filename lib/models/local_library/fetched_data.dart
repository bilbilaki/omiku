import 'package:omiku/models/local_library/content_type.dart';

class FetchedData {
  final int? tmdbId;
  final String? title;
  final String? originalTitle;
  final String? posterPath;
  final String? backdropPath;
  final String? overview;
  final String? year;
  final ContentType? resolvedType;
  final int? season;
  final int? episode;

  const FetchedData({
    this.tmdbId,
    this.title,
    this.originalTitle,
    this.posterPath,
    this.backdropPath,
    this.overview,
    this.year,
    this.resolvedType,
    this.season,
    this.episode,
  });

  FetchedData copyWith({
    int? tmdbId,
    String? title,
    String? originalTitle,
    String? posterPath,
    String? backdropPath,
    String? overview,
    String? year,
    ContentType? resolvedType,
    int? season,
    int? episode,
  }) => FetchedData(
        tmdbId: tmdbId ?? this.tmdbId,
        title: title ?? this.title,
        originalTitle: originalTitle ?? this.originalTitle,
        posterPath: posterPath ?? this.posterPath,
        backdropPath: backdropPath ?? this.backdropPath,
        overview: overview ?? this.overview,
        year: year ?? this.year,
        resolvedType: resolvedType ?? this.resolvedType,
        season: season ?? this.season,
        episode: episode ?? this.episode,
      );
}
