import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:omiku/vfs/models.dart';



// FFI Signatures
typedef ExecuteBatchRenameC = Void Function(Pointer<Utf8> configJson, Pointer<NativeFunction<DartCallbackC>> callback);
typedef ExecuteBatchRenameDart = void Function(Pointer<Utf8> configJson, Pointer<NativeFunction<DartCallbackC>> callback);
typedef DartCallbackC = Void Function(Pointer<Utf8> resultJson, Int32 status);

typedef InitEngineC = Int32 Function(Pointer<Utf8> root, Pointer<Utf8> dbPath);
typedef InitEngineDart = int Function(Pointer<Utf8> root, Pointer<Utf8> dbPath);


typedef PathActionC = Void Function(Pointer<Utf8> path);
typedef PathActionDart = void Function(Pointer<Utf8> path);

typedef DualPathActionC = Void Function(Pointer<Utf8> src, Pointer<Utf8> dst);
typedef DualPathActionDart = void Function(Pointer<Utf8> src, Pointer<Utf8> dst);

typedef WriteContentC = Void Function(Pointer<Utf8> path, Pointer<Utf8> contentHex);
typedef WriteContentDart = void Function(Pointer<Utf8> path, Pointer<Utf8> contentHex);

typedef GetFileContentC = Void Function(Pointer<Utf8> path, Pointer<NativeFunction<DartCallbackC>> callback);
typedef GetFileContentDart = void Function(Pointer<Utf8> path, Pointer<NativeFunction<DartCallbackC>> callback);
typedef ActionWithCallbackC = Void Function(Pointer<NativeFunction<DartCallbackC>> callback);
typedef ActionWithCallbackDart = void Function(Pointer<NativeFunction<DartCallbackC>> callback);
typedef VoidFunctionDart = void Function();

class VfsEngine {
  late DynamicLibrary _lib;
  late InitEngineDart _initEngine;
  late ActionWithCallbackDart _incrementalSync;
  late VoidFunctionDart _beginSandbox;
  late VoidFunctionDart _discardSandbox;
  late PathActionDart _sandboxCreateFolder;
  late PathActionDart _sandboxDelete;
  late DualPathActionDart _sandboxMove;
  late DualPathActionDart _sandboxCopy;
  late WriteContentDart _sandboxWriteContent;
  late ActionWithCallbackDart _commitSandbox;
  late GetFileContentDart _getFileContent;
  late ActionWithCallbackDart _getVirtualManifest;
  late ExecuteBatchRenameDart _executeBatchRename;

  VfsEngine() {
        _lib = _loadLibrary();
    _commitSandbox = _lib.lookupFunction<ActionWithCallbackC, ActionWithCallbackDart>('CommitSandbox');
    _initEngine = _lib.lookupFunction<InitEngineC, InitEngineDart>('InitEngine');
    _incrementalSync = _lib.lookupFunction<ActionWithCallbackC, ActionWithCallbackDart>('IncrementalSync');
    
    _beginSandbox = _lib.lookup<NativeFunction<Void Function()>>('BeginSandbox').asFunction<VoidFunctionDart>();
    _discardSandbox = _lib.lookup<NativeFunction<Void Function()>>('DiscardSandbox').asFunction<VoidFunctionDart>();
    
    _sandboxCreateFolder = _lib.lookupFunction<PathActionC, PathActionDart>('SandboxCreateFolder');
    _sandboxDelete = _lib.lookupFunction<PathActionC, PathActionDart>('SandboxDelete');
    _sandboxMove = _lib.lookupFunction<DualPathActionC, DualPathActionDart>('SandboxMove');
    _sandboxCopy = _lib.lookupFunction<DualPathActionC, DualPathActionDart>('SandboxCopy');
    _sandboxWriteContent = _lib.lookupFunction<WriteContentC, WriteContentDart>('SandboxWriteContent');
    _commitSandbox = _lib.lookupFunction<ActionWithCallbackC, ActionWithCallbackDart>('CommitSandbox');
    _getFileContent = _lib.lookupFunction<GetFileContentC, GetFileContentDart>('GetFileContent');
    _getVirtualManifest = _lib.lookupFunction<ActionWithCallbackC, ActionWithCallbackDart>('GetVirtualManifest');

    _executeBatchRename = _lib
        .lookup<NativeFunction<ExecuteBatchRenameC>>('ExecuteBatchRename')
        .asFunction<ExecuteBatchRenameDart>();
  }
  DynamicLibrary _loadLibrary() {
    if (Platform.isWindows) return DynamicLibrary.open('libvfs.dll');
    if (Platform.isAndroid) return DynamicLibrary.open('libvfs.so');
    throw UnsupportedError('Platform not supported');
  }
  void init(String rootPath, String dbFilePath) {
    final rootPtr = rootPath.toNativeUtf8();
    final dbPtr = dbFilePath.toNativeUtf8();
    _initEngine(rootPtr, dbPtr);
    calloc.free(rootPtr);
    calloc.free(dbPtr);
  }

  Future<void> sync() {
    final completer = Completer<void>();
    late final NativeCallable<DartCallbackC> nativeCallback;

    nativeCallback = NativeCallable<DartCallbackC>.listener((Pointer<Utf8> resultJson, int status) {
      if (status == 0) {
        completer.complete();
      } else {
        completer.completeError(Exception(_parseError(resultJson)));
      }
      nativeCallback.close();
    });

    _incrementalSync(nativeCallback.nativeFunction);
    return completer.future;
  }

  void beginTransaction() => _beginSandbox();
  void rollbackTransaction() => _discardSandbox();

  void stageCreateFolder(String relPath) {
    final pathPtr = relPath.toNativeUtf8();
    _sandboxCreateFolder(pathPtr);
    calloc.free(pathPtr);
  }

  void stageDelete(String relPath) {
    final pathPtr = relPath.toNativeUtf8();
    _sandboxDelete(pathPtr);
    calloc.free(pathPtr);
  }

  void stageMove(String srcRel, String dstRel) {
    final srcPtr = srcRel.toNativeUtf8();
    final dstPtr = dstRel.toNativeUtf8();
    _sandboxMove(srcPtr, dstPtr);
    calloc.free(srcPtr);
    calloc.free(dstPtr);
  }

  void stageCopy(String srcRel, String dstRel) {
    final srcPtr = srcRel.toNativeUtf8();
    final dstPtr = dstRel.toNativeUtf8();
    _sandboxCopy(srcPtr, dstPtr);
    calloc.free(srcPtr);
    calloc.free(dstPtr);
  }

  void stageWriteContent(String relPath, List<int> bytes) {
    final pathPtr = relPath.toNativeUtf8();
    final hexString = hexEncode(bytes);
    final contentPtr = hexString.toNativeUtf8();
    _sandboxWriteContent(pathPtr, contentPtr);
    calloc.free(pathPtr);
    calloc.free(contentPtr);
  }

  Future<List<int>> readFile(String relPath) {
    final completer = Completer<List<int>>();
    final pathPtr = relPath.toNativeUtf8();
    late final NativeCallable<DartCallbackC> nativeCallback;

    nativeCallback = NativeCallable<DartCallbackC>.listener((Pointer<Utf8> resultJson, int status) {
      if (status == 0) {
        final hexStr = resultJson.toDartString();
        completer.complete(hexDecode(hexStr));
      } else {
        completer.completeError(Exception(_parseError(resultJson)));
      }
      calloc.free(pathPtr);
      nativeCallback.close();
    });

    _getFileContent(pathPtr, nativeCallback.nativeFunction);
    return completer.future;
  }

  Future<void> commitTransaction() {
    final completer = Completer<void>();
    late final NativeCallable<DartCallbackC> nativeCallback;

    nativeCallback = NativeCallable<DartCallbackC>.listener((Pointer<Utf8> resultJson, int status) {
      if (status == 0) {
        completer.complete();
      } else {
        completer.completeError(Exception(_parseError(resultJson)));
      }
      nativeCallback.close();
    });

    _commitSandbox(nativeCallback.nativeFunction);
    return completer.future;
  }

  Future<List<VirtualNode>> getManifest() {
    final completer = Completer<List<VirtualNode>>();
    late final NativeCallable<DartCallbackC> nativeCallback;

    nativeCallback = NativeCallable<DartCallbackC>.listener((Pointer<Utf8> resultJson, int status) {
      if (status == 0) {
        final jsonString = resultJson.toDartString();
        final List<dynamic> decoded = jsonDecode(jsonString);
        completer.complete(decoded.map((e) => VirtualNode.fromJson(e)).toList());
      } else {
        completer.completeError(Exception(_parseError(resultJson)));
      }
      nativeCallback.close();
    });

    _getVirtualManifest(nativeCallback.nativeFunction);
    return completer.future;
  }

  String _parseError(Pointer<Utf8> ptr) {
    try {
      final jsonStr = ptr.toDartString();
      return jsonDecode(jsonStr)['error'] ?? 'Unknown native error';
    } catch (_) {
      return 'Native system crash';
    }
  }

  // Basic utility methods to avoid heavy external Dart dependencies
  String hexEncode(List<int> bytes) => bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  List<int> hexDecode(String hex) {
    final bytes = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return bytes;
  }



  /// Commits the sandbox transaction.
  /// Returns a [Stream] of [ProgressUpdate] events indicating archive rebuild progress.
  Stream<ProgressUpdate> commitTransactionWP() {
    final controller = StreamController<ProgressUpdate>();
    late final NativeCallable<DartCallbackC> nativeCallback;

    nativeCallback = NativeCallable<DartCallbackC>.listener((Pointer<Utf8> resultJson, int status) {
      if (status == 3) {
        // Status 3: Progress Update
        final jsonString = resultJson.toDartString();
        final decoded = jsonDecode(jsonString);
        controller.add(ProgressUpdate(decoded['progress'] as int, decoded['task'] as String));
      } else if (status == 0) {
        // Status 0: Completed successfully
        controller.close();
        nativeCallback.close();
      } else {
        // Status -1: Error
        final jsonString = resultJson.toDartString();
        controller.addError(Exception(jsonDecode(jsonString)['error'] ?? 'Commit failed'));
        controller.close();
        nativeCallback.close();
      }
    });

    _commitSandbox(nativeCallback.nativeFunction);
    return controller.stream;
  }


  /// Executes a batch rename or preview. 
  /// Streams lists of [RenameResult] in real-time.
  Stream<List<RenameResult>> runBatchRename(RenameConfig config) {
    final controller = StreamController<List<RenameResult>>();
    final configString = jsonEncode(config.toJson());
    final configPtr = configString.toNativeUtf8();
    late final NativeCallable<DartCallbackC> nativeCallback;

    nativeCallback = NativeCallable<DartCallbackC>.listener((Pointer<Utf8> resultJson, int status) {
      if (status == 1) {
        final jsonString = resultJson.toDartString();
        final List<dynamic> decodedList = jsonDecode(jsonString);
        final results = decodedList.map((e) => RenameResult.fromJson(e)).toList();
        controller.add(results);
      } else if (status == 0) {
        controller.close();
        calloc.free(configPtr);
        nativeCallback.close();
      } else {
        final jsonString = resultJson.toDartString();
        controller.addError(Exception(jsonDecode(jsonString)['error'] ?? 'Batch processing failed'));
        controller.close();
        calloc.free(configPtr);
        nativeCallback.close();
      }
    });

    _executeBatchRename(configPtr, nativeCallback.nativeFunction);
    return controller.stream;
  }
}