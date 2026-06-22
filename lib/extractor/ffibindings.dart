import 'dart:ffi';
import 'dart:isolate';
import 'package:ffi/ffi.dart';

typedef InitializeDartAPIC =
    Void Function(
      Pointer<NativeFunction<Bool Function(Int64, Pointer<Dart_CObject>)>>,
    );
typedef InitializeDartAPIDart =
    void Function(
      Pointer<NativeFunction<Bool Function(Int64, Pointer<Dart_CObject>)>>,
    );

typedef StartExtractionC =
    Void Function(Int64 port, Pointer<Utf8> archivePath, Pointer<Utf8> pPath);
typedef StartExtractionDart =
    void Function(int port, Pointer<Utf8> archivePath, Pointer<Utf8> pPath);

typedef UnarchiveNC =
    Void Function(Int64 port, Pointer<Utf8> filePath, Pointer<Utf8> targetPath);
typedef UnarchiveNDart =
    void Function(int port, Pointer<Utf8> filePath, Pointer<Utf8> targetPath);
typedef UncbzNC =
    Void Function(Int64 port, Pointer<Utf8> filePath, Pointer<Utf8> targetPath);
typedef UncbzNDart =
    void Function(int port, Pointer<Utf8> filePath, Pointer<Utf8> targetPath);
typedef UnepubNC =
    Void Function(Int64 port, Pointer<Utf8> filePath, Pointer<Utf8> targetPath);
typedef UnepubNDart =
    void Function(int port, Pointer<Utf8> filePath, Pointer<Utf8> targetPath);
typedef UnpdfNC =
    Void Function(Int64 port, Pointer<Utf8> filePath, Pointer<Utf8> targetPath);
typedef UnpdfNDart =
    void Function(int port, Pointer<Utf8> filePath, Pointer<Utf8> targetPath);
typedef UntarNC =
    Void Function(Int64 port, Pointer<Utf8> filePath, Pointer<Utf8> targetPath);
typedef UntarNDart =
    void Function(int port, Pointer<Utf8> filePath, Pointer<Utf8> targetPath);
typedef StartExtractionSeriesArchiveC =
    Void Function(
      Int64 port,
      Pointer<Utf8> filePath,
      Pointer<Utf8> targetPat,
      Pointer<Utf8> seriesidh,
    );
typedef StartExtractionSeriesArchiveDart =
    void Function(
      int port,
      Pointer<Utf8> filePath,
      Pointer<Utf8> targetPath,
      Pointer<Utf8> seriesid,
    );
typedef StartExtractionChapterC =
    Void Function(
      Int64 port,
      Pointer<Utf8> filePath,
      Pointer<Utf8> targetPat,
      Pointer<Utf8> seriesidh,
      Int32 chapterId,
    );
typedef StartExtractionChapterDart =
    void Function(
      int port,
      Pointer<Utf8> filePath,
      Pointer<Utf8> targetPath,
      Pointer<Utf8> seriesid,
      int chapterId,
    );

class GoExtractor {
  late DynamicLibrary _lib;
  late StartExtractionDart _startExtraction;
  late UnarchiveNDart _unarchiveN;
  late UncbzNDart _uncbzN;
  late UnepubNDart _unepubN;
  late UnpdfNDart _unpdfN;
  late UntarNDart _untarN;
  late StartExtractionSeriesArchiveDart _startExtractionSeriesArchive;
  late StartExtractionChapterDart _startExtractionChapter;
  GoExtractor() {
    // Load your library
    _lib = DynamicLibrary.open('libextractor.so');

    // 2. Look up the initialization function with the updated signature
    final initApi = _lib
        .lookup<NativeFunction<InitializeDartAPIC>>('InitializeDartAPI')
        .asFunction<InitializeDartAPIDart>();

    _startExtraction = _lib
        .lookup<NativeFunction<StartExtractionC>>('StartExtraction')
        .asFunction<StartExtractionDart>();
    _unarchiveN = _lib
        .lookup<NativeFunction<UnarchiveNC>>('UnarchiveN')
        .asFunction<UnarchiveNDart>();
    _uncbzN = _lib
        .lookup<NativeFunction<UncbzNC>>('UncbzN')
        .asFunction<UncbzNDart>();
    _unepubN = _lib
        .lookup<NativeFunction<UnepubNC>>('UnepubN')
        .asFunction<UnepubNDart>();
    _unepubN = _lib
        .lookup<NativeFunction<UnpdfNC>>('UnpdfN')
        .asFunction<UnpdfNDart>();
    _untarN = _lib
        .lookup<NativeFunction<UntarNC>>('UntarN')
        .asFunction<UntarNDart>();
    _startExtractionSeriesArchive = _lib
        .lookup<NativeFunction<StartExtractionSeriesArchiveC>>(
          'StartExtractionSeriesArchive',
        )
        .asFunction<StartExtractionSeriesArchiveDart>();
    _startExtractionChapter = _lib
        .lookup<NativeFunction<StartExtractionChapterC>>(
          'StartExtractionChapter',
        )
        .asFunction<StartExtractionChapterDart>();

    // 3. This will now compile flawlessly without any casting!
    initApi(NativeApi.postCObject.cast());
  }

  Stream<String> extractPdf(String path, String tmppath) {
    final receivePort = ReceivePort();
    final nativePort = receivePort.sendPort.nativePort;

    final pathPointer = path.toNativeUtf8();
    final pPointer = tmppath.toNativeUtf8();

    // Trigger the Go process (returns immediately because Go runs a goroutine)
    _unpdfN(nativePort, pathPointer, pPointer);

    // Return the stream mapped to strings
    return receivePort.map((message) {
      final log = message as String;

      // If our specific end signal is received, close the port
      if (log.startsWith("SUCCESS") || log.startsWith("ERROR")) {
        malloc.free(pathPointer);
        receivePort.close();
      }
      return log;
    });
  }

  Stream<String> extractEpub(String path, String tmppath) {
    final receivePort = ReceivePort();
    final nativePort = receivePort.sendPort.nativePort;

    final pathPointer = path.toNativeUtf8();
    final pPointer = tmppath.toNativeUtf8();

    // Trigger the Go process (returns immediately because Go runs a goroutine)
    _unepubN(nativePort, pathPointer, pPointer);

    // Return the stream mapped to strings
    return receivePort.map((message) {
      final log = message as String;

      // If our specific end signal is received, close the port
      if (log.startsWith("SUCCESS") || log.startsWith("ERROR")) {
        malloc.free(pathPointer);
        receivePort.close();
      }
      return log;
    });
  }

  Stream<String> extractCbz(String path, String tmppath) {
    final receivePort = ReceivePort();
    final nativePort = receivePort.sendPort.nativePort;

    final pathPointer = path.toNativeUtf8();
    final pPointer = tmppath.toNativeUtf8();

    // Trigger the Go process (returns immediately because Go runs a goroutine)
    _uncbzN(nativePort, pathPointer, pPointer);

    // Return the stream mapped to strings
    return receivePort.map((message) {
      final log = message as String;

      // If our specific end signal is received, close the port
      if (log.startsWith("SUCCESS") || log.startsWith("ERROR")) {
        malloc.free(pathPointer);
        receivePort.close();
      }
      return log;
    });
  }

  Stream<String> extractTar(String path, String tmppath) {
    final receivePort = ReceivePort();
    final nativePort = receivePort.sendPort.nativePort;

    final pathPointer = path.toNativeUtf8();
    final pPointer = tmppath.toNativeUtf8();

    // Trigger the Go process (returns immediately because Go runs a goroutine)
    _untarN(nativePort, pathPointer, pPointer);

    // Return the stream mapped to strings
    return receivePort.map((message) {
      final log = message as String;

      // If our specific end signal is received, close the port
      if (log.startsWith("SUCCESS") || log.startsWith("ERROR")) {
        malloc.free(pathPointer);
        receivePort.close();
      }
      return log;
    });
  }

  Stream<String> extractArchiveS(String path, String tmppath) {
    final receivePort = ReceivePort();
    final nativePort = receivePort.sendPort.nativePort;

    final pathPointer = path.toNativeUtf8();
    final pPointer = tmppath.toNativeUtf8();

    // Trigger the Go process (returns immediately because Go runs a goroutine)
    _unarchiveN(nativePort, pathPointer, pPointer);

    // Return the stream mapped to strings
    return receivePort.map((message) {
      final log = message as String;

      // If our specific end signal is received, close the port
      if (log.startsWith("SUCCESS") || log.startsWith("ERROR")) {
        malloc.free(pathPointer);
        receivePort.close();
      }
      return log;
    });
  }

  Stream<String> autoExtractSeries(
    String path,
    String tmppath,
    String seriesId,
  ) {
    final receivePort = ReceivePort();
    final nativePort = receivePort.sendPort.nativePort;

    final pathPointer = path.toNativeUtf8();
    final pPointer = tmppath.toNativeUtf8();
    final pSeriesId = seriesId.toNativeUtf8();
    // Trigger the Go process (returns immediately because Go runs a goroutine)
    _startExtractionSeriesArchive(nativePort, pathPointer, pPointer, pSeriesId);

    // Return the stream mapped to strings
    return receivePort.map((message) {
      final log = message as String;

      // If our specific end signal is received, close the port
      if (log.startsWith("SUCCESS") || log.startsWith("ERROR")) {
        malloc.free(pathPointer);
        receivePort.close();
      }
      return log;
    });
  }
// This stream returns logs as they arrive from Go
  Stream<String> extractArchive(String path, String tmppath) {
    final receivePort = ReceivePort();
    final nativePort = receivePort.sendPort.nativePort;

    final pathPointer = path.toNativeUtf8();
    final pPointer = tmppath.toNativeUtf8();

    // Trigger the Go process (returns immediately because Go runs a goroutine)
    _startExtraction(nativePort, pathPointer, pPointer);

    // Return the stream mapped to strings
    return receivePort.map((message) {
      final log = message as String;

      // If our specific end signal is received, close the port
      if (log.startsWith("SUCCESS") || log.startsWith("ERROR")) {
        malloc.free(pathPointer);
        receivePort.close();
      }
      return log;
    });
  }

  Stream<String> autoExtractSeriesChapter(
    String path,
    String tmppath,
    String seriesId,
    int chapNum,
  ) {
    final receivePort = ReceivePort();
    final nativePort = receivePort.sendPort.nativePort;

    final pathPointer = path.toNativeUtf8();
    final pPointer = tmppath.toNativeUtf8();
    final pSeriesId = seriesId.toNativeUtf8();
    // Trigger the Go process (returns immediately because Go runs a goroutine)
    _startExtractionChapter(nativePort, pathPointer, pPointer, pSeriesId,chapNum);

    // Return the stream mapped to strings
    return receivePort.map((message) {
      final log = message as String;

      // If our specific end signal is received, close the port
      if (log.startsWith("SUCCESS") || log.startsWith("ERROR")) {
        malloc.free(pathPointer);
        receivePort.close();
      }
      return log;
    });
  }
}
