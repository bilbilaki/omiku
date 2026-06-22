import 'package:uuid/uuid.dart';
import 'content_item.dart';
import 'directory_entry.dart';
import 'scan_status.dart';

class Collection {
  final String id;
  final String name;
  final ContentType contentType;
  final List<ContentItem> items;
  final List<DirectoryEntry> directoryEntries;
  final ScanStatus status;

  Collection({
    String? id,
    required this.name,
    required this.contentType,
    List<ContentItem>? items,
    List<DirectoryEntry>? directoryEntries,
    this.status = ScanStatus.complete,
  })  : id = id ?? const Uuid().v4(),
        items = items ?? const [],
        directoryEntries = directoryEntries ?? const [];

  Collection copyWith({
    String? name,
    ContentType? contentType,
    List<ContentItem>? items,
    List<DirectoryEntry>? directoryEntries,
    ScanStatus? status,
  }) => Collection(
        id: id,
        name: name ?? this.name,
        contentType: contentType ?? this.contentType,
        items: items ?? this.items,
        directoryEntries: directoryEntries ?? this.directoryEntries,
        status: status ?? this.status,
      );
}
