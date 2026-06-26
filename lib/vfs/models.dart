class ProgressUpdate {
  final int progress;
  final String task;
  ProgressUpdate(this.progress, this.task);
}

// Add Archive Specific fields to VirtualNode
class VirtualNode {
  final String id;
  final String relPath;
  final int size;
  final DateTime modTime;
  final bool isDir;
  final String? mimeType;
  final String? headerHex;
  final String? pendingAction;
  final bool isArchiveMember;
  final String? archiveOwner;
  final String? archiveRelPath;

  VirtualNode({
    required this.id,
    required this.relPath,
    required this.size,
    required this.modTime,
    required this.isDir,
    this.mimeType,
    this.headerHex,
    this.pendingAction,
    required this.isArchiveMember,
    this.archiveOwner,
    this.archiveRelPath,
  });

  factory VirtualNode.fromJson(Map<String, dynamic> json) {
    return VirtualNode(
      id: json['id'] as String,
      relPath: json['rel_path'] as String,
      size: json['size'] as int,
      modTime: DateTime.fromMillisecondsSinceEpoch((json['mod_time'] as int) * 1000),
      isDir: json['is_dir'] as bool,
      mimeType: json['mime_type'] as String?,
      headerHex: json['header_hex'] as String?,
      pendingAction: json['pending_action'] as String?,
      isArchiveMember: json['is_archive_member'] as bool? ?? false,
      archiveOwner: json['archive_owner'] as String?,
      archiveRelPath: json['archive_rel_path'] as String?,
    );
  }
}
class RenameResult {
  final String before;
  final String after;
  final String status; // "success", "skipped", "error"
  final String? error;

  RenameResult({
    required this.before,
    required this.after,
    required this.status,
    this.error,
  });

  factory RenameResult.fromJson(Map<String, dynamic> json) {
    return RenameResult(
      before: json['before'] as String,
      after: json['after'] as String,
      status: json['status'] as String,
      error: json['error'] as String?,
    );
  }
}

enum RenameTarget { name, ext, both }
enum CollisionStrategy { fail, skip, increment }
enum CaseConversion { upper, lower, none }

class RenameConfig {
  final RenameTarget target;
  final String replaceOld;
  final String replaceNew;
  final String prefix;
  final String suffix;
  final CaseConversion caseConversion;
  final String pattern;
  final int startIndex;
  final double startDouble;
  final double doubleStep;
  final List<String> strArgs;
  final int concurrency;
  final int batchSize;
  final CollisionStrategy collisionStrategy;
  final bool previewOnly;
  final String? scanDir;
  final List<String>? explicitPaths;

  RenameConfig({
    this.target = RenameTarget.name,
    this.replaceOld = "",
    this.replaceNew = "",
    this.prefix = "",
    this.suffix = "",
    this.caseConversion = CaseConversion.none,
    this.pattern = "",
    this.startIndex = 0,
    this.startDouble = 0.0,
    this.doubleStep = 1.0,
    this.strArgs = const [],
    this.concurrency = 4,
    this.batchSize = 1000,
    this.collisionStrategy = CollisionStrategy.increment,
    this.previewOnly = false,
    this.scanDir,
    this.explicitPaths,
  });

  Map<String, dynamic> toJson() => {
        "target": target.name,
        "replace_old": replaceOld,
        "replace_new": replaceNew,
        "prefix": prefix,
        "suffix": suffix,
        "case": caseConversion.name,
        "pattern": pattern,
        "start_index": startIndex,
        "start_double": startDouble,
        "double_step": doubleStep,
        "str_args": strArgs,
        "concurrency": concurrency,
        "batch_size": batchSize,
        "collision_strategy": collisionStrategy.name,
        "preview_only": previewOnly,
        "scan_dir": scanDir,
        "explicit_paths": explicitPaths,
      };
}