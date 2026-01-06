import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart' as stt;

/// Data source for speech recognition using speech_to_text package
abstract class SpeechRemoteDataSource {
  Future<bool> isAvailable();
  Future<bool> initialize();
  Future<void> startListening({
    required Function(String text) onResult,
    required Function() onDone,
    required Function(String error) onError,
  });
  Future<void> stopListening();
  Future<void> cancel();
}

class SpeechRemoteDataSourceImpl implements SpeechRemoteDataSource {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;

  @override
  Future<bool> isAvailable() async {
    try {
      return await _speech.initialize(
        onError: (_) {},
        onStatus: (_) {},
      );
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      final available = await _speech.initialize(
        onError: (_) {},
        onStatus: (_) {},
      );
      _isInitialized = available;
      return available;
    } catch (e) {
      _isInitialized = false;
      return false;
    }
  }

  @override
  Future<void> startListening({
    required Function(String text) onResult,
    required Function() onDone,
    required Function(String error) onError,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        onError('Speech recognition not available');
        return;
      }
    }

    await _speech.listen(
      onResult: (stt.SpeechRecognitionResult result) {
        if (result.finalResult) {
          onResult(result.recognizedWords);
          onDone();
        } else {
          // Partial results can be handled here if needed
          onResult(result.recognizedWords);
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      localeId: 'vi_VN', // Default to Vietnamese, can be made configurable
      onSoundLevelChange: (_) {},
      cancelOnError: true,
      listenMode: stt.ListenMode.confirmation,
    );
  }

  @override
  Future<void> stopListening() async {
    await _speech.stop();
  }

  @override
  Future<void> cancel() async {
    await _speech.cancel();
  }
}

