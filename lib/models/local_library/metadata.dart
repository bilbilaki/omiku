import 'dart:io';

class Metadata {
  final int sizeBytes;
  final String extension;
  final DateTime modified;
  final DateTime? accessed;
  final DateTime? changed; // platform dependent

  const Metadata({
    required this.sizeBytes,
    required this.extension,
    required this.modified,
    this.accessed,
    this.changed,
  });

  String get sizeReadable {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    if (sizeBytes < 1024 * 1024 * 1024) return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  static Future<Metadata> fromFile(File file) async {
    final stat = await file.stat();
    final ext = file.path.split('.').length > 1 ? '.${file.path.split('.').last.toLowerCase()}' : '';
    return Metadata(
      sizeBytes: stat.size,
      extension: ext,
      modified: stat.modified,
      accessed: stat.accessed,
      changed: stat.changed,
    );
  }
}
