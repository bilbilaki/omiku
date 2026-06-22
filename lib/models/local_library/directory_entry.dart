import 'package:uuid/uuid.dart';
import 'content_item.dart';
import 'scan_status.dart';

enum ContentType {
  music,
  movie,
  tvSeries,
  musicVideo,
  photo,
  mixed,
}

class DirectoryEntry {
  final String id;
  final String path;
  final String parentPath;
  final ContentType contentType;
  final List<ContentItem> items;
  final int sizeBytes; // aggregate size of items
  final ScanStatus status;

  DirectoryEntry({
    String? id,
    required this.path,
    required this.parentPath,
    required this.contentType,
    List<ContentItem>? items,
    this.sizeBytes = 0,
    this.status = ScanStatus.pending,
  })  : id = id ?? const Uuid().v4(),
        items = items ?? const [];

  DirectoryEntry copyWith({
    String? path,
    String? parentPath,
    ContentType? contentType,
    List<ContentItem>? items,
    int? sizeBytes,
    ScanStatus? status,
  }) => DirectoryEntry(
        id: id,
        path: path ?? this.path,
        parentPath: parentPath ?? this.parentPath,
        contentType: contentType ?? this.contentType,
        items: items ?? this.items,
        sizeBytes: sizeBytes ?? this.sizeBytes,
        status: status ?? this.status,
      );
}
