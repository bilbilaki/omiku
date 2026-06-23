import 'package:uuid/uuid.dart';
import 'content_item.dart';
import 'metadata.dart';
import 'fetched_data.dart';
import 'scan_status.dart';

/// Represents a single music video file variant
class MusicVideoItem extends ContentItem {
  @override
  final String id;
  final FetchedData? fetchedData;
  final ScanStatus scanStatus;

  MusicVideoItem({
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
  MusicVideoItem copyWith({
    String? path,
    String? parentPath,
    String? name,
    Metadata? metadata,
    FetchedData? fetchedData,
    ScanStatus? scanStatus,
  }) => MusicVideoItem(
    id: id,
    path: path ?? this.path,
    parentPath: parentPath ?? this.parentPath,
    name: name ?? this.name,
    metadata: metadata ?? this.metadata,
    fetchedData: fetchedData ?? this.fetchedData,
    scanStatus: scanStatus ?? this.scanStatus,
  );
}

/// Represents a Music Video container (artist/album folder)
class MusicVideo {
  final String id;
  final String path;
  final String parentPath;
  final String name;
  final List<MusicVideoItem> musicVideoItems;
  final int totalSize;
  final ScanStatus scanStatus;
  final FetchedData fetchedData;

  MusicVideo({
    String? id,
    required this.path,
    required this.parentPath,
    required this.name,
    List<MusicVideoItem>? musicVideoItems,
    int? totalSize,
    ScanStatus? scanStatus,
    FetchedData? fetchedData,
  }) : id = id ?? const Uuid().v4(),
       musicVideoItems = musicVideoItems ?? const [],
       totalSize = totalSize ?? 0,
       scanStatus = scanStatus ?? ScanStatus.pending,
       fetchedData = fetchedData ?? const FetchedData();

  MusicVideo copyWith({
    String? path,
    String? parentPath,
    String? name,
    List<MusicVideoItem>? musicVideoItems,
    int? totalSize,
    ScanStatus? scanStatus,
    FetchedData? fetchedData,
  }) => MusicVideo(
        id: id,
        path: path ?? this.path,
        parentPath: parentPath ?? this.parentPath,
        name: name ?? this.name,
        musicVideoItems: musicVideoItems ?? this.musicVideoItems,
        totalSize: totalSize ?? this.totalSize,
        scanStatus: scanStatus ?? this.scanStatus,
        fetchedData: fetchedData ?? this.fetchedData,
      );
}
