import 'package:uuid/uuid.dart';
import 'content_item.dart';
import 'fetched_data.dart';
import 'scan_status.dart';

/// Represents a Mixed Content container (folder with various media types)
class MixedContent {
  final String id;
  final String path;
  final String parentPath;
  final String name;
  final List<ContentItem> contentItems; // Mixed media files
  final int totalSize;
  final ScanStatus scanStatus;
  final FetchedData fetchedData;

  MixedContent({
    String? id,
    required this.path,
    required this.parentPath,
    required this.name,
    List<ContentItem>? contentItems,
    int? totalSize,
    ScanStatus? scanStatus,
    FetchedData? fetchedData,
  }) : id = id ?? const Uuid().v4(),
       contentItems = contentItems ?? const [],
       totalSize = totalSize ?? 0,
       scanStatus = scanStatus ?? ScanStatus.pending,
       fetchedData = fetchedData ?? const FetchedData();

  MixedContent copyWith({
    String? path,
    String? parentPath,
    String? name,
    List<ContentItem>? contentItems,
    int? totalSize,
    ScanStatus? scanStatus,
    FetchedData? fetchedData,
  }) => MixedContent(
        id: id,
        path: path ?? this.path,
        parentPath: parentPath ?? this.parentPath,
        name: name ?? this.name,
        contentItems: contentItems ?? this.contentItems,
        totalSize: totalSize ?? this.totalSize,
        scanStatus: scanStatus ?? this.scanStatus,
        fetchedData: fetchedData ?? this.fetchedData,
      );
}
