import 'package:uuid/uuid.dart';
import 'content_item.dart';
import 'metadata.dart';
import 'fetched_data.dart';
import 'scan_status.dart';

/// Represents a single music file variant
class MusicItem extends ContentItem {
  @override
  final String id;
  final FetchedData? fetchedData;
  final ScanStatus scanStatus;

  MusicItem({
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
  MusicItem copyWith({
    String? path,
    String? parentPath,
    String? name,
    Metadata? metadata,
    FetchedData? fetchedData,
    ScanStatus? scanStatus,
  }) => MusicItem(
    id: id,
    path: path ?? this.path,
    parentPath: parentPath ?? this.parentPath,
    name: name ?? this.name,
    metadata: metadata ?? this.metadata,
    fetchedData: fetchedData ?? this.fetchedData,
    scanStatus: scanStatus ?? this.scanStatus,
  );
}

/// Represents a Music container (album, artist folder, or track collection)
class Music {
  final String id;
  final String path;
  final String parentPath;
  final String name;
  final List<MusicItem> musicItems;
  final int totalSize;
  final ScanStatus scanStatus;
  final FetchedData fetchedData;

  Music({
    String? id,
    required String path,
    required String parentPath,
    required String name,
    List<MusicItem>? musicItems,
    int? totalSize,
    ScanStatus? scanStatus,
    FetchedData? fetchedData,
  }) : id = id ?? const Uuid().v4(),
       path = path,
       parentPath = parentPath,
       name = name,
       musicItems = musicItems ?? const [],
       totalSize = totalSize ?? 0,
       scanStatus = scanStatus ?? ScanStatus.pending,
       fetchedData = fetchedData ?? const FetchedData();

  Music copyWith({
    String? path,
    String? parentPath,
    String? name,
    List<MusicItem>? musicItems,
    int? totalSize,
    ScanStatus? scanStatus,
    FetchedData? fetchedData,
  }) => Music(
        id: id,
        path: path ?? this.path,
        parentPath: parentPath ?? this.parentPath,
        name: name ?? this.name,
        musicItems: musicItems ?? this.musicItems,
        totalSize: totalSize ?? this.totalSize,
        scanStatus: scanStatus ?? this.scanStatus,
        fetchedData: fetchedData ?? this.fetchedData,
      );
}
