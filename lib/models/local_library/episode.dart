import 'package:omiku/models/local_library/content_item.dart';
import 'package:omiku/models/local_library/fetched_data.dart';
import 'package:omiku/models/local_library/scan_status.dart';
import 'package:omiku/models/local_library/metadata.dart';

class Episode extends ContentItem {
  final int seasonNumber;
  final int episodeNumber;
  final String? tvSeriesId;
  final String? tvSeriesName;
  final FetchedData? fetchedData;
  final ScanStatus scanStatus;

  Episode({
    super.id,
    required this.seasonNumber,
    required this.episodeNumber,
    required super.name,
    required super.path,
    required super.parentPath,
    required super.metadata,
    this.tvSeriesId,
    this.tvSeriesName,
    this.fetchedData,
    this.scanStatus = ScanStatus.complete,
  });

  @override
  Episode copyWith({
    String? path,
    String? parentPath,
    String? name,
    Metadata? metadata,
    int? seasonNumber,
    int? episodeNumber,
    String? tvSeriesId,
    String? tvSeriesName,
    FetchedData? fetchedData,
    ScanStatus? scanStatus,
  }) {
    return Episode(
      id: id,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      episodeNumber: episodeNumber ?? this.episodeNumber,
      name: name ?? this.name,
      path: path ?? this.path,
      parentPath: parentPath ?? this.parentPath,
      metadata: metadata ?? this.metadata,
      tvSeriesId: tvSeriesId ?? this.tvSeriesId,
      tvSeriesName: tvSeriesName ?? this.tvSeriesName,
      fetchedData: fetchedData ?? this.fetchedData,
      scanStatus: scanStatus ?? this.scanStatus,
    );
  }
}
