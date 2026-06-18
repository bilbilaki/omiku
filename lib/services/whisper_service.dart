import 'package:omiku/main.dart';
import 'package:path/path.dart' as p;
import 'package:whisper_kit/whisper_kit.dart';

class WhisperService {
  WhisperService() {
    final m = p.join(appSupportDir, "gglm-base.bin");
    whisper = Whisper(model: WhisperModel.base, modelDir: m);
  }
  Whisper? whisper;

  Future<String?> transcribe(String audiop,{bool shouldTranslate = false}) async {
    final TranscribeRequest request = TranscribeRequest(
      audio: audiop,
      isTranslate: shouldTranslate,
      language: 'auto',
    );

    try {
      final WhisperTranscribeResponse result = await whisper!.transcribe(
        transcribeRequest: request,
      );
      print('Transcription: ${result.text}');
      // Access segments if available
      if (result.segments != null) {
        for (final segment in result.segments!) {
          print('[${segment.fromTs} - ${segment.toTs}]: ${segment.text}');
        }
      }
      return result.text;
    } on ModelException catch (e) {
      print('Model error: $e');
    } on AudioException catch (e) {
      print('Audio error: $e');
    } on TranscriptionException catch (e) {
      print('Transcription error: $e');
    }
    return null;
  }
}
