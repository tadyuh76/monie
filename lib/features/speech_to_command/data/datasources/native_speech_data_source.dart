import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:monie/core/services/native_voice_recognition_service.dart';
import 'package:monie/features/speech_to_command/data/datasources/speech_remote_data_source.dart';

/// Native speech data source for Vivo/OEM devices
/// Uses direct Android SpeechRecognizer instead of speech_to_text plugin
class NativeSpeechDataSource implements SpeechRemoteDataSource {
  final NativeVoiceRecognitionService _voiceService;
  bool _isInitialized = false;
  String? _lastError;
  StreamSubscription<String>? _streamSubscription;

  NativeSpeechDataSource(this._voiceService);

  @override
  Future<bool> isAvailable() async {
    try {
      _lastError = null;
      final available = await _voiceService.isAvailable();

      if (!available) {
        final details = await _voiceService.getAvailabilityDetails();
        _lastError = details['error']?.toString() ??
            'Native speech recognition not available';
        debugPrint('❌ Native speech not available: $_lastError');
      }

      return available;
    } catch (e) {
      _lastError = e.toString();
      debugPrint('❌ Error checking native speech availability: $e');
      return false;
    }
  }

  @override
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _lastError = null;
      final available = await _voiceService.isAvailable();

      if (available) {
        _isInitialized = true;
        debugPrint('✅ Native speech recognition initialized');
        return true;
      } else {
        final details = await _voiceService.getAvailabilityDetails();
        _lastError = details['error']?.toString() ??
            'Native speech recognition not available';
        debugPrint('❌ Native speech initialization failed: $_lastError');
        return false;
      }
    } catch (e) {
      _lastError = e.toString();
      _isInitialized = false;
      debugPrint('❌ Native speech initialization error: $e');
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

    try {
      // Cancel any existing subscription first to avoid conflicts
      await _streamSubscription?.cancel();
      _streamSubscription = null;

      // Use provided locale or default to English
      final effectiveLocaleId = localeId ?? 'en_US';
      debugPrint('🎤 Starting native speech recognition with locale: $effectiveLocaleId');
      final stream = await _voiceService.startListening(localeId: effectiveLocaleId);

      _streamSubscription = stream.listen(
        (text) {
          debugPrint('🎤 Recognized: $text');
          onResult(text);
        },
        onError: (error) {
          debugPrint('❌ Recognition error: $error');
          onError(error.toString());
          _streamSubscription = null;
          onDone();
        },
        onDone: () {
          debugPrint('✅ Recognition done');
          _streamSubscription = null;
          onDone();
        },
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint('❌ Failed to start native listening: $e');
      onError(e.toString());
    }
  }

  @override
  Future<void> stopListening() async {
    try {
      // Cancel subscription first, then stop the service
      await _streamSubscription?.cancel();
      _streamSubscription = null;
      await _voiceService.stopListening();
      debugPrint('✅ DataSource: Stopped listening and cancelled subscription');
    } catch (e) {
      debugPrint('❌ Error stopping native speech: $e');
    }
  }

  @override
  Future<void> cancel() async {
    try {
      // Cancel subscription first, then cancel the service
      await _streamSubscription?.cancel();
      _streamSubscription = null;
      await _voiceService.cancel();
      debugPrint('✅ DataSource: Cancelled listening and cancelled subscription');
    } catch (e) {
      debugPrint('❌ Error cancelling native speech: $e');
    }
  }

  /// Get the last error message for debugging
  String? getLastError() => _lastError;

  /// Get available locales (native implementation supports standard Android locales)
  List<String> getAvailableLocales() {
    // Native Android SpeechRecognizer supports these common locales
    return [
      'vi_VN', // Vietnamese
      'en_US', // English (US)
      'en_GB', // English (UK)
      'zh_CN', // Chinese (Simplified)
      'ja_JP', // Japanese
      'ko_KR', // Korean
    ];
  }

  /// Check if a specific locale is available
  bool isLocaleAvailable(String localeId) {
    final availableLocales = getAvailableLocales();
    return availableLocales.any((locale) =>
        locale.toLowerCase().startsWith(localeId.toLowerCase().substring(0, 2)));
  }
}
