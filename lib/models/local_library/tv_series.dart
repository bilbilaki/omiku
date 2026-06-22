import 'package:uuid/uuid.dart';
import 'season.dart';
import 'fetched_data.dart';
import 'scan_status.dart';

/// Represents a TV Series container that holds Season containers
class TvSeries {
  final String id;
  final String path;
  final String parentPath;
  final String name;
  final List<Season> seasons;
  final int totalSize;
  final ScanStatus scanStatus;
  final FetchedData fetchedData;

  TvSeries({
    String? id,
    required String path,
    required String parentPath,
    required String name,
    List<Season>? seasons,
    int? totalSize,
    ScanStatus? scanStatus,
    FetchedData? fetchedData,
  }) : id = id ?? const Uuid().v4(),
       path = path,
       parentPath = parentPath,
       name = name,
       seasons = seasons ?? const [],
       totalSize = totalSize ?? 0,
       scanStatus = scanStatus ?? ScanStatus.pending,
       fetchedData = fetchedData ?? const FetchedData();

  TvSeries copyWith({
    String? path,
    String? parentPath,
    String? name,
    List<Season>? seasons,
    int? totalSize,
    ScanStatus? scanStatus,
    FetchedData? fetchedData,
  }) => TvSeries(
        id: id,
        path: path ?? this.path,
        parentPath: parentPath ?? this.parentPath,
        name: name ?? this.name,
        seasons: seasons ?? this.seasons,
        totalSize: totalSize ?? this.totalSize,
        scanStatus: scanStatus ?? this.scanStatus,
        fetchedData: fetchedData ?? this.fetchedData,
      );
}
