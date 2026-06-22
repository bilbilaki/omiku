import 'package:uuid/uuid.dart';
import 'metadata.dart';

/// Represents a single playable/watchable/viewable file
abstract class ContentItem {
  final String id;
  final String path;
  final String parentPath;
  final String name;
  final Metadata metadata;

  ContentItem({
    String? id,
    required this.path,
    required this.parentPath,
    required this.name,
    required this.metadata,
  }) : id = id ?? const Uuid().v4();

  ContentItem copyWith({
    String? path,
    String? parentPath,
    String? name,
    Metadata? metadata,
  });
}
