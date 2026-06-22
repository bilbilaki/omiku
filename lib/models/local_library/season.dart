import 'package:uuid/uuid.dart';
import 'episode.dart';
import 'fetched_data.dart';
import 'scan_status.dart';

/// Represents a Season container that holds Episode content items
class Season {
  final String id;
  final String path;
  final String parentPath;
  final String? name;
  final String? seriesId;
  final String? seriesName;
  final int seasonNumber;
  final List<Episode> episodes;
  final int totalSize;
  final ScanStatus scanStatus;
  final FetchedData fetchedData;

  Season({
    String? id,
    required this.path,
    required this.parentPath,
    this.name,
    this.seriesId,
    this.seriesName,
    int? seasonNumber,
    List<Episode>? episodes,
    int? totalSize,
    ScanStatus? scanStatus,
    FetchedData? fetchedData,
  })  : id = id ?? const Uuid().v4(),
        seasonNumber = seasonNumber ?? 1,
        episodes = episodes ?? const [],
        totalSize = totalSize ?? 0,
        scanStatus = scanStatus ?? ScanStatus.pending,
        fetchedData = fetchedData ?? const FetchedData();

  Season copyWith({
    String? path,
    String? parentPath,
    String? name,
    String? seriesId,
    String? seriesName,
    int? seasonNumber,
    List<Episode>? episodes,
    int? totalSize,
    ScanStatus? scanStatus,
    FetchedData? fetchedData,
  }) =>
      Season(
        id: id,
        path: path ?? this.path,
        parentPath: parentPath ?? this.parentPath,
        name: name ?? this.name,
        seriesId: seriesId ?? this.seriesId,
        seriesName: seriesName ?? this.seriesName,
        seasonNumber: seasonNumber ?? this.seasonNumber,
        episodes: episodes ?? this.episodes,
        totalSize: totalSize ?? this.totalSize,
        scanStatus: scanStatus ?? this.scanStatus,
        fetchedData: fetchedData ?? this.fetchedData,
      );
}
