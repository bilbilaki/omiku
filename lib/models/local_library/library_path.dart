import 'package:uuid/uuid.dart';

class LibraryPath {
  final String id;
  final String path;
  final String name;

  LibraryPath({
    String? id,
    required this.path,
    required this.name,
  }) : id = id ?? const Uuid().v4();

  LibraryPath copyWith({
    String? id,
    String? path,
    String? name,
  }) {
    return LibraryPath(
      id: id ?? this.id,
      path: path ?? this.path,
      name: name ?? this.name,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'path': path,
    'name': name,
  };

  factory LibraryPath.fromJson(Map<String, dynamic> json) => LibraryPath(
    id: json['id'] as String?,
    path: json['path'] as String,
    name: json['name'] as String,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LibraryPath &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          path == other.path &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ path.hashCode ^ name.hashCode;
}
