import 'dart:async';
import 'package:flutter/foundation.dart';
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
    String? localeId,
  });
  Future<void> stopListening();
  Future<void> cancel();
}

class SpeechRemoteDataSourceImpl implements SpeechRemoteDataSource {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;
  String? _lastError;
  List<String> _availableLocales = [];
  String? _lastPartialResult; // Store last partial for fallback

  /// Get the last error message for debugging
  String? getLastError() => _lastError;

  /// Get available locales for speech recognition
  List<String> getAvailableLocales() => _availableLocales;

  /// Check if a specific locale is available
  bool isLocaleAvailable(String localeId) {
    return _availableLocales.any((locale) =>
        locale.toLowerCase().startsWith(localeId.toLowerCase().substring(0, 2)));
  }

  @override
  Future<bool> isAvailable() async {
    try {
      _lastError = null;
      return await _speech.initialize(
        onError: (error) {
          _lastError = error.errorMsg;
          debugPrint('Speech initialization error: ${error.errorMsg}');
        },
        onStatus: (status) {
          debugPrint('Speech status: $status');
        },
      );
    } catch (e) {
      _lastError = e.toString();
      debugPrint('Speech availability check failed: $e');
      return false;
    }
  }

  @override
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _lastError = null;

      final available = await _speech.initialize(
        onError: (error) {
          _lastError = error.errorMsg;
          debugPrint('Speech error: ${error.errorMsg}');
        },
        onStatus: (status) {
          debugPrint('Speech status: $status');
        },
      );

      if (available) {
        // Get available locales
        final locales = await _speech.locales();
        _availableLocales =
            locales.map((locale) => locale.localeId).toList();
        debugPrint('Available locales: ${_availableLocales.take(5).join(", ")}...');
      } else {
        debugPrint('Speech recognition not available');
      }

      _isInitialized = available;
      return available;
    } catch (e) {
      _lastError = e.toString();
      _isInitialized = false;
      debugPrint('Speech initialization failed: $e');
      return false;
    }
  }

  @override
  Future<void> startListening({
    required Function(String text) onResult,
    required Function() onDone,
    required Function(String error) onError,
    String? localeId,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        onError(_lastError ?? 'Speech recognition not available');
        return;
      }
    }

    // Use provided locale or default to English (more universally available)
    // Vietnamese requires language pack to be installed on the device
    String effectiveLocaleId = localeId ?? 'en_US';

    // Check locale availability and use fallback if needed
    if (!isLocaleAvailable(effectiveLocaleId)) {
      debugPrint('Locale $effectiveLocaleId not available, falling back to en_US');
      effectiveLocaleId = 'en_US';
    }

    debugPrint('Starting speech recognition with locale: $effectiveLocaleId');

    // Reset partial result tracker
    _lastPartialResult = null;

    try {
      await _speech.listen(
        onResult: (stt.SpeechRecognitionResult result) {
          // Only process final results to avoid triggering multiple parse commands
          // Partial results cause premature parsing with incomplete text
          if (result.finalResult) {
            debugPrint('Final result: ${result.recognizedWords}');
            onResult(result.recognizedWords);
            _lastPartialResult = null;
            onDone();
          } else {
            // Store partial result as fallback
            if (result.recognizedWords.isNotEmpty) {
              _lastPartialResult = result.recognizedWords;
            }
            // Log partial results but don't process them
            debugPrint('Partial result (skipped): ${result.recognizedWords}');
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        localeId: effectiveLocaleId,
        onSoundLevelChange: (_) {},
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
          listenMode: stt.ListenMode.confirmation,
          onDevice: false,
        ),
      );
      
      // Set up a safety timer to emit last partial if no final result comes
      Timer(const Duration(seconds: 32), () {
        if (_lastPartialResult != null && _lastPartialResult!.isNotEmpty) {
          debugPrint('Timeout: Using last partial result as final: $_lastPartialResult');
          onResult(_lastPartialResult!);
          _lastPartialResult = null;
          onDone();
        }
      });
    } catch (e) {
      debugPrint('Failed to start listening: $e');
      onError(e.toString());
    }
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

