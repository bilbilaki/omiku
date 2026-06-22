import 'package:uuid/uuid.dart';
import 'collection.dart';
import 'directory_entry.dart';
import 'episode.dart';
import 'movie.dart';
import 'music.dart';
import 'music_video.dart';
import 'photo.dart';
import 'season.dart';
import 'tv_series.dart';
import 'scan_status.dart';

class LibraryModel {
  final String id;
  final String name;
  final List<DirectoryEntry> directories;
  final List<Collection> collections;
  final List<Movie> movies;
  final List<Music> musicAlbums;
  final List<MusicVideo> musicVideos;
  final List<Photo> photoCollections;
  final List<TvSeries> tvSeries;
  final List<Season> seasons;
  final List<Episode> episodes;
  final ScanStatus status;
  final DateTime createdAt;

  LibraryModel({
    String? id,
    required this.name,
    List<DirectoryEntry>? directories,
    List<Collection>? collections,
    List<Movie>? movies,
    List<Music>? musicAlbums,
    List<MusicVideo>? musicVideos,
    List<Photo>? photoCollections,
    List<TvSeries>? tvSeries,
    List<Season>? seasons,
    List<Episode>? episodes,
    this.status = ScanStatus.pending,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        directories = directories ?? const [],
        collections = collections ?? const [],
        movies = movies ?? const [],
        musicAlbums = musicAlbums ?? const [],
        musicVideos = musicVideos ?? const [],
        photoCollections = photoCollections ?? const [],
        tvSeries = tvSeries ?? const [],
        seasons = seasons ?? const [],
        episodes = episodes ?? const [],
        createdAt = createdAt ?? DateTime.now();

  LibraryModel copyWith({
    String? name,
    List<DirectoryEntry>? directories,
    List<Collection>? collections,
    List<Movie>? movies,
    List<Music>? musicAlbums,
    List<MusicVideo>? musicVideos,
    List<Photo>? photoCollections,
    List<TvSeries>? tvSeries,
    List<Season>? seasons,
    List<Episode>? episodes,
    ScanStatus? status,
  }) => LibraryModel(
        id: id,
        name: name ?? this.name,
        directories: directories ?? this.directories,
        collections: collections ?? this.collections,
        movies: movies ?? this.movies,
        musicAlbums: musicAlbums ?? this.musicAlbums,
        musicVideos: musicVideos ?? this.musicVideos,
        photoCollections: photoCollections ?? this.photoCollections,
        tvSeries: tvSeries ?? this.tvSeries,
        seasons: seasons ?? this.seasons,
        episodes: episodes ?? this.episodes,
        status: status ?? this.status,
        createdAt: createdAt,
      );
}
