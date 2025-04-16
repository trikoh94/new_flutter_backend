import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (!_isInitialized) {
      _isInitialized = await _speechToText.initialize();
    }
  }

  Future<bool> isAvailable() async {
    if (!_isInitialized) {
      await initialize();
    }
    return _isInitialized;
  }

  Future<void> startListening({
    required Function(String) onResult,
    List<String> tags = const [],
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_isInitialized) {
      await _speechToText.listen(
        onResult: (result) {
          if (result.finalResult) {
            onResult(result.recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: false,
        cancelOnError: true,
      );
    }
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
  }

  bool get isListening => _speechToText.isListening;
}
