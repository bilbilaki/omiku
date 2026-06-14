import 'dart:ffi';
import 'dart:isolate';
import 'package:ffi/ffi.dart';

typedef InitializeDartAPIC = Void Function(Pointer<NativeFunction<Bool Function(Int64, Pointer<Dart_CObject>)>>);
typedef InitializeDartAPIDart = void Function(Pointer<NativeFunction<Bool Function(Int64, Pointer<Dart_CObject>)>>);

typedef StartExtractionC = Void Function(Int64 port, Pointer<Utf8> archivePath,Pointer<Utf8> pPath);
typedef StartExtractionDart = void Function(int port, Pointer<Utf8> archivePath,Pointer<Utf8> pPath);

class GoExtractor {
  late DynamicLibrary _lib;
  late StartExtractionDart _startExtraction;

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

    // 3. This will now compile flawlessly without any casting!
initApi(NativeApi.postCObject.cast());
  }

  // This stream returns logs as they arrive from Go
  Stream<String> extractArchive(String path,String tmppath) {
    final receivePort = ReceivePort();
    final nativePort = receivePort.sendPort.nativePort;

    final pathPointer = path.toNativeUtf8();
    final pPointer = tmppath.toNativeUtf8();

    // Trigger the Go process (returns immediately because Go runs a goroutine)
    _startExtraction(nativePort, pathPointer,pPointer);

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