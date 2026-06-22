import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';
import 'package:ffi/ffi.dart';
import 'package:omiku/myanime/myanime_models.dart';

typedef InitializeDartAPIC =
    Void Function(
      Pointer<NativeFunction<Bool Function(Int64, Pointer<Dart_CObject>)>>,
    );
typedef InitializeDartAPIDart =
    void Function(
      Pointer<NativeFunction<Bool Function(Int64, Pointer<Dart_CObject>)>>,
    );
typedef NativeSearchAnimeC =
    Void Function(Int64 port, Pointer<Utf8> query, Int32 limit);
typedef NativeSearchAnimeD =
    void Function(int port, Pointer<Utf8> query, int limit);

typedef NativeDetailC = Void Function(Int64 port, Int32 animeId);
typedef NativeDetailD = void Function(int port, int animeId);
typedef NativeGetMangaC = Void Function(Int64 port, Pointer<Utf8> query);
typedef NativeGetMangaD = void Function(int port, Pointer<Utf8> query);

class MalNativeClient {
  late DynamicLibrary _lib;
  late NativeDetailD _nativeAnimeDetail;
  late NativeSearchAnimeD _nativeSearchAnime;
  late NativeGetMangaD _nativeGetManga;

  MalNativeClient() {
    // Open the compiled binary
    _lib = DynamicLibrary.open("myanimelib.so");

    final initApi = _lib
        .lookup<NativeFunction<InitializeDartAPIC>>('InitializeDartAPI')
        .asFunction<InitializeDartAPIDart>();
    _nativeAnimeDetail = _lib
        .lookup<NativeFunction<NativeDetailC>>("NativeAnimeDetail")
        .asFunction<NativeDetailD>();
    _nativeSearchAnime = _lib
        .lookup<NativeFunction<NativeSearchAnimeC>>("NativeSearchAnime")
        .asFunction<NativeSearchAnimeD>();
    _nativeGetManga = _lib
        .lookup<NativeFunction<NativeGetMangaC>>("NativeSearchMangaAniList")
        .asFunction<NativeGetMangaD>();

    initApi(NativeApi.postCObject.cast());
  }

  // void _initializeDartMessaging() {
  //   final initAPI = _lib
  //       .lookup<NativeFunction<Void Function(Pointer<Void>)>>(
  //         "InitializeDartAPI",
  //       );
  //   final asFunction = initAPI
  //       .asFunction<void Function(Pointer<Void>)>();
  //   asFunction(NativeApi.initializeApiDLData);
  // }

  /// Request full details by passing an ID.
  /// Seamlessly switches from Go threads straight back to Flutter Futures.
  Future<GetAnimeDetailResult> getAnimeDetails(int animeId) {
    final completer = Completer<GetAnimeDetailResult>();
    final receivePort = ReceivePort();
    final nativePort = receivePort.sendPort.nativePort;
    StringBuffer responseBuffer = StringBuffer();
    _nativeAnimeDetail(nativePort, animeId);

    receivePort.listen((message) {
      if (message == "done") {
        receivePort.close();
        try {
          final parsedJson = jsonDecode(responseBuffer.toString());
          completer.complete(parsedJson);
        } catch (e) {
          completer.completeError("JSON Parsing Error from Go Layer");
        }
      } else {
        // Append chunks or status payloads
        responseBuffer.write(message);
      }
    });

    // Fire across FFI boundary asynchronously

    return completer.future;
  }

  Future<GetAnimeListResult> searchAnime(String query, {int limit = 100}) {
    final completer = Completer<GetAnimeListResult>();

    final receivePort = ReceivePort();
    final nativePort = receivePort.sendPort.nativePort;
    StringBuffer responseBuffer = StringBuffer();

    final queryi = query.toNativeUtf8();
    final limiti = limit.toInt();
    _nativeSearchAnime(nativePort, queryi, limiti);

    receivePort.listen((message) {
      if (message == "done") {
        malloc.free(queryi);
        receivePort.close();
        try {
          final parsedJson = jsonDecode(responseBuffer.toString());
          completer.complete(parsedJson);
        } catch (e) {
          completer.completeError("JSON Parsing Error from Go Layer");
        }
      } else {
        // Append chunks or status payloads
        responseBuffer.write(message);
      }
    });
    return completer.future;
  }
  Future<GetMangaResult> searchManga(String query) {
    final completer = Completer<GetMangaResult>();

    final receivePort = ReceivePort();
    final nativePort = receivePort.sendPort.nativePort;
    StringBuffer responseBuffer = StringBuffer();

    final queryi = query.toNativeUtf8();

    _nativeGetManga(nativePort, queryi);

    receivePort.listen((message) {
      if (message == "done") {
        malloc.free(queryi);
        receivePort.close();
        try {
          final parsedJson = jsonDecode(responseBuffer.toString());
          completer.complete(parsedJson);
        } catch (e) {
          completer.completeError("JSON Parsing Error from Go Layer");
        }
      } else {
        // Append chunks or status payloads
        responseBuffer.write(message);
      }
    });
    return completer.future;
  }

}
