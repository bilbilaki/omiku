import 'package:uuid/uuid.dart';
import 'content_item.dart';
import 'metadata.dart';
import 'fetched_data.dart';
import 'scan_status.dart';

/// Represents a single movie file variant (different quality, edition, etc.)
class MovieItem extends ContentItem {
  @override
  final String id;
  final FetchedData? fetchedData;
  final ScanStatus scanStatus;

  MovieItem({
    String? id,
    required super.path,
    required super.parentPath,
    required super.name,
    required super.metadata,
    this.fetchedData,
    this.scanStatus = ScanStatus.pending,
  }) : id = id ?? const Uuid().v4(),
       super(
    id: id ?? const Uuid().v4(),
  );

  @override
  MovieItem copyWith({
    String? path,
    String? parentPath,
    String? name,
    Metadata? metadata,
    FetchedData? fetchedData,
    ScanStatus? scanStatus,
  }) => MovieItem(
    id: id,
    path: path ?? this.path,
    parentPath: parentPath ?? this.parentPath,
    name: name ?? this.name,
    metadata: metadata ?? this.metadata,
    fetchedData: fetchedData ?? this.fetchedData,
    scanStatus: scanStatus ?? this.scanStatus,
  );
}

/// Represents a Movie container that can hold multiple movie item files
/// (e.g., different qualities, editions, bonus features)
class Movie {
  final int? tmdbId;
  final String path;
  final String parentPath;
  final String name;
  final List<MovieItem> movieItems;
  final int totalSize;
  final ScanStatus scanStatus;
  final FetchedData fetchedData;

  Movie({
    this.tmdbId,
    required this.path,
    required String parentPath,
    required this.name,
    List<MovieItem>? movieItems,
    int? totalSize,
    ScanStatus? scanStatus,
    FetchedData? fetchedData,
  }) : parentPath = parentPath,
       movieItems = movieItems ?? const [],
       totalSize = totalSize ?? 0,
       scanStatus = scanStatus ?? ScanStatus.pending,
       fetchedData = fetchedData ?? const FetchedData();

  Movie copyWith({
    int? tmdbId,
    String? path,
    String? parentPath,
    String? name,
    List<MovieItem>? movieItems,
    int? totalSize,
    ScanStatus? scanStatus,
    FetchedData? fetchedData,
  }) => Movie(
        tmdbId: tmdbId ?? this.tmdbId,
        path: path ?? this.path,
        parentPath: parentPath ?? this.parentPath,
        name: name ?? this.name,
        movieItems: movieItems ?? this.movieItems,
        totalSize: totalSize ?? this.totalSize,
        scanStatus: scanStatus ?? this.scanStatus,
        fetchedData: fetchedData ?? this.fetchedData,
      );
}
