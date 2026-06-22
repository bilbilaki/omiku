import 'package:uuid/uuid.dart';
import 'content_item.dart';
import 'metadata.dart';
import 'fetched_data.dart';
import 'scan_status.dart';

/// Represents a single photo file variant
class PhotoItem extends ContentItem {
  @override
  final String id;
  final FetchedData? fetchedData;
  final ScanStatus scanStatus;

  PhotoItem({
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
  PhotoItem copyWith({
    String? path,
    String? parentPath,
    String? name,
    Metadata? metadata,
    FetchedData? fetchedData,
    ScanStatus? scanStatus,
  }) => PhotoItem(
    id: id,
    path: path ?? this.path,
    parentPath: parentPath ?? this.parentPath,
    name: name ?? this.name,
    metadata: metadata ?? this.metadata,
    fetchedData: fetchedData ?? this.fetchedData,
    scanStatus: scanStatus ?? this.scanStatus,
  );
}

/// Represents a Photo container (album/collection folder)
class Photo {
  final String id;
  final String path;
  final String parentPath;
  final String name;
  final List<PhotoItem> photoItems;
  final int totalSize;
  final ScanStatus scanStatus;
  final FetchedData fetchedData;

  Photo({
    String? id,
    required String path,
    required String parentPath,
    required String name,
    List<PhotoItem>? photoItems,
    int? totalSize,
    ScanStatus? scanStatus,
    FetchedData? fetchedData,
  }) : id = id ?? const Uuid().v4(),
       path = path,
       parentPath = parentPath,
       name = name,
       photoItems = photoItems ?? const [],
       totalSize = totalSize ?? 0,
       scanStatus = scanStatus ?? ScanStatus.pending,
       fetchedData = fetchedData ?? const FetchedData();

  Photo copyWith({
    String? path,
    String? parentPath,
    String? name,
    List<PhotoItem>? photoItems,
    int? totalSize,
    ScanStatus? scanStatus,
    FetchedData? fetchedData,
  }) => Photo(
        id: id,
        path: path ?? this.path,
        parentPath: parentPath ?? this.parentPath,
        name: name ?? this.name,
        photoItems: photoItems ?? this.photoItems,
        totalSize: totalSize ?? this.totalSize,
        scanStatus: scanStatus ?? this.scanStatus,
        fetchedData: fetchedData ?? this.fetchedData,
      );
}
