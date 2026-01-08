import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Native voice recognition service for Vivo/OEM devices
/// Uses direct Android SpeechRecognizer API instead of speech_to_text plugin
class NativeVoiceRecognitionService {
  static const MethodChannel _channel =
      MethodChannel('com.tadyuh.monie/voice_recognition');

  StreamController<String>? _resultController;
  StreamController<String>? _statusController;
  bool _isListening = false;

  NativeVoiceRecognitionService() {
    // Set up method call handler for callbacks from native side
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  /// Handle callbacks from native Android code
  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onResult':
        final args = call.arguments as Map;
        final text = args['text'] as String;
        final isFinal = args['isFinal'] as bool;

        debugPrint('🎤 Voice result: $text (final: $isFinal)');
        _resultController?.add(text);

        if (isFinal) {
          // Delay closing to allow listeners to process the result
          // This prevents the race condition where stream closes before listeners receive data
          await Future.delayed(const Duration(milliseconds: 100));
          _isListening = false;
          await _resultController?.close();
          _resultController = null;
          debugPrint('✅ Stream closed after result delivery');
        }
        break;

      case 'onError':
        final args = call.arguments as Map;
        final error = args['error'] as String;
        final errorCode = args['errorCode'] as int;

        debugPrint('❌ Voice error: $error (code: $errorCode)');
        _resultController?.addError(error);

        // Delay closing to allow error listeners to process
        await Future.delayed(const Duration(milliseconds: 50));
        _isListening = false;
        await _resultController?.close();
        _resultController = null;
        break;

      case 'onStatus':
        final args = call.arguments as Map;
        final status = args['status'] as String;

        debugPrint('📊 Voice status: $status');
        _statusController?.add(status);

        if (status == 'done') {
          _isListening = false;
        }
        break;
    }
  }

  /// Check if native speech recognition is available
  Future<bool> isAvailable() async {
    try {
      final result =
          await _channel.invokeMethod<Map>('checkAvailability') ?? {};
      final details = Map<String, dynamic>.from(result);

      debugPrint('📱 Native voice recognition availability: $details');

      return details['isAvailable'] == true &&
          details['hasMicrophonePermission'] == true;
    } on PlatformException catch (e) {
      debugPrint('❌ Error checking native voice availability: ${e.message}');
      return false;
    }
  }

  /// Get detailed availability information for diagnostics
  Future<Map<String, dynamic>> getAvailabilityDetails() async {
    try {
      final result =
          await _channel.invokeMethod<Map>('checkAvailability') ?? {};
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      debugPrint('❌ Error getting availability details: ${e.message}');
      return {
        'isAvailable': false,
        'error': e.message,
      };
    }
  }

  /// Start listening for voice input
  /// Returns a stream of recognized text
  Future<Stream<String>> startListening({String localeId = 'vi_VN'}) async {
    // Clean up any existing session first
    if (_isListening) {
      debugPrint('⚠️ Already listening, cleaning up previous session...');
      try {
        await cancel();
      } catch (e) {
        debugPrint('⚠️ Error during cancel, continuing anyway: $e');
      }
    }

    // Close old stream controllers if they exist
    try {
      _resultController?.close();
      _statusController?.close();
    } catch (e) {
      debugPrint('⚠️ Error closing old controllers: $e');
    }

    // Reset to null after closing
    _resultController = null;
    _statusController = null;

    try {
      // Create fresh stream controllers
      _resultController = StreamController<String>.broadcast();
      _statusController = StreamController<String>.broadcast();

      // Ensure controllers are created before proceeding
      if (_resultController == null || _statusController == null) {
        throw Exception('Failed to create stream controllers');
      }

      final success = await _channel.invokeMethod<bool>(
            'startListening',
            {'localeId': localeId},
          ) ??
          false;

      if (success) {
        _isListening = true;
        debugPrint('✅ Started native voice recognition');

        // Safe check before returning stream
        final controller = _resultController;
        if (controller == null) {
          throw Exception('Result controller is null after successful start');
        }

        return controller.stream;
      } else {
        _resultController?.close();
        _resultController = null;
        _statusController?.close();
        _statusController = null;
        throw Exception('Failed to start voice recognition');
      }
    } on PlatformException catch (e) {
      _resultController?.close();
      _resultController = null;
      _statusController?.close();
      _statusController = null;
      debugPrint('❌ Error starting native voice recognition: ${e.message}');
      rethrow;
    } catch (e) {
      _resultController?.close();
      _resultController = null;
      _statusController?.close();
      _statusController = null;
      debugPrint('❌ Unexpected error starting native voice recognition: $e');
      rethrow;
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _channel.invokeMethod('stopListening');
      _isListening = false;
      _resultController?.close();
      _resultController = null;
      _statusController?.close();
      _statusController = null;
      debugPrint('⏹️ Stopped native voice recognition');
    } on PlatformException catch (e) {
      debugPrint('❌ Error stopping native voice recognition: ${e.message}');
    }
  }

  /// Cancel listening
  Future<void> cancel() async {
    try {
      await _channel.invokeMethod('cancelListening');
      _isListening = false;
      _resultController?.close();
      _resultController = null;
      _statusController?.close();
      _statusController = null;
      debugPrint('❌ Cancelled native voice recognition');
    } on PlatformException catch (e) {
      debugPrint('❌ Error cancelling native voice recognition: ${e.message}');
      // Even if cancel fails, reset state
      _isListening = false;
      _resultController?.close();
      _resultController = null;
      _statusController?.close();
      _statusController = null;
    }
  }

  /// Check if currently listening
  bool get isListening => _isListening;

  /// Dispose resources
  void dispose() {
    _resultController?.close();
    _statusController?.close();
  }
}
