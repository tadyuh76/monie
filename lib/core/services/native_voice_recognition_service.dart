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
  String? _lastPartialResult; // Store last partial result for fallback

  NativeVoiceRecognitionService() {
    // Set up method call handler for callbacks from native side
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  /// Handle callbacks from native Android code
  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onResult':
        final args = call.arguments as Map?;
        if (args == null) {
          debugPrint('Voice result: null args received');
          return;
        }
        final text = args['text'] as String? ?? '';
        final isFinal = args['isFinal'] as bool? ?? false;

        debugPrint('Voice result: $text (final: $isFinal)');

        // Only add final results to avoid triggering multiple parse commands
        // Partial results are logged but not processed
        if (isFinal) {
          // Only add if controller exists and is not closed
          final controller = _resultController;
          if (controller != null && !controller.isClosed && text.isNotEmpty) {
            controller.add(text);
          }

          // Delay closing to allow listeners to process the result
          // This prevents the race condition where stream closes before listeners receive data
          await Future.delayed(const Duration(milliseconds: 100));
          _isListening = false;
          if (_resultController != null && !_resultController!.isClosed) {
            await _resultController?.close();
          }
          _resultController = null;
          _lastPartialResult = null;
          debugPrint('Stream closed after final result delivery');
        } else {
          // Store partial result as fallback in case onResults is not called
          if (text.isNotEmpty) {
            _lastPartialResult = text;
          }
          debugPrint('Skipping partial result, waiting for final...');
        }
        break;

      case 'onError':
        final args = call.arguments as Map?;
        if (args == null) {
          debugPrint('Voice error: null args received');
          return;
        }
        final error = args['error'] as String? ?? 'Unknown error';
        final errorCode = args['errorCode'] as int? ?? -1;

        debugPrint('Voice error: $error (code: $errorCode)');

        // Only add error if controller exists and is not closed
        final errorController = _resultController;
        if (errorController != null && !errorController.isClosed) {
          errorController.addError(error);
        }

        // Delay closing to allow error listeners to process
        await Future.delayed(const Duration(milliseconds: 50));
        _isListening = false;
        if (_resultController != null && !_resultController!.isClosed) {
          await _resultController?.close();
        }
        _resultController = null;
        break;

      case 'onStatus':
        final args = call.arguments as Map?;
        if (args == null) {
          debugPrint('Voice status: null args received');
          return;
        }
        final status = args['status'] as String? ?? 'unknown';

        debugPrint('Voice status: $status');

        // Only add status if controller exists and is not closed
        final statusController = _statusController;
        if (statusController != null && !statusController.isClosed) {
          statusController.add(status);
        }

        // When recognition is done but no final result was received,
        // use the last partial result as the final result
        if (status == 'done') {
          _isListening = false;
          
          // Wait a bit for any final partial result that might come after 'done' status
          await Future.delayed(const Duration(milliseconds: 200));
          
          // If we have a partial result but no final result was sent, emit it now
          if (_lastPartialResult != null && _lastPartialResult!.isNotEmpty) {
            final controller = _resultController;
            if (controller != null && !controller.isClosed) {
              debugPrint('Emitting last partial result as final: $_lastPartialResult');
              controller.add(_lastPartialResult!);
              
              // Delay closing to allow listeners to process
              await Future.delayed(const Duration(milliseconds: 100));
            }
          }
          
          // Close the stream
          if (_resultController != null && !_resultController!.isClosed) {
            await _resultController?.close();
          }
          _resultController = null;
          _lastPartialResult = null;
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

      debugPrint('Native voice recognition availability: $details');

      return details['isAvailable'] == true &&
          details['hasMicrophonePermission'] == true;
    } on PlatformException catch (e) {
      debugPrint('Error checking native voice availability: ${e.message}');
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
      debugPrint('Error getting availability details: ${e.message}');
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
      debugPrint('Already listening, cleaning up previous session...');
      try {
        await cancel();
      } catch (e) {
        debugPrint('Error during cancel, continuing anyway: $e');
      }
    }

    // Close old stream controllers if they exist
    try {
      _resultController?.close();
      _statusController?.close();
    } catch (e) {
      debugPrint('Error closing old controllers: $e');
    }

    // Reset to null after closing
    _resultController = null;
    _statusController = null;
    _lastPartialResult = null; // Reset partial result tracker

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
        debugPrint('Started native voice recognition');

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
      debugPrint('Error starting native voice recognition: ${e.message}');
      rethrow;
    } catch (e) {
      _resultController?.close();
      _resultController = null;
      _statusController?.close();
      _statusController = null;
      debugPrint('Unexpected error starting native voice recognition: $e');
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
      _lastPartialResult = null;
      debugPrint('Stopped native voice recognition');
    } on PlatformException catch (e) {
      debugPrint('Error stopping native voice recognition: ${e.message}');
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
      _lastPartialResult = null;
      debugPrint('Cancelled native voice recognition');
    } on PlatformException catch (e) {
      debugPrint('Error cancelling native voice recognition: ${e.message}');
      // Even if cancel fails, reset state
      _isListening = false;
      _resultController?.close();
      _resultController = null;
      _statusController?.close();
      _statusController = null;
      _lastPartialResult = null;
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
