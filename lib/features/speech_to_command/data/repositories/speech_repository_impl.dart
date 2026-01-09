import 'dart:async' show StreamController, TimeoutException;
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:monie/core/errors/failures.dart';
import 'package:monie/core/services/gemini_service.dart';
import 'package:monie/core/services/permission_service.dart';
import 'package:monie/core/services/device_info_service.dart';
import 'package:monie/features/speech_to_command/data/datasources/speech_remote_data_source.dart';
import 'package:monie/features/speech_to_command/data/datasources/native_speech_data_source.dart';
import 'package:monie/core/utils/command_parser.dart';
import 'package:monie/features/speech_to_command/domain/entities/speech_command.dart';
import 'package:monie/features/speech_to_command/domain/repositories/speech_repository.dart';

class SpeechRepositoryImpl implements SpeechRepository {
  final SpeechRemoteDataSource dataSource;
  final GeminiService? geminiService;
  final PermissionService permissionService;
  final DeviceInfoService deviceInfoService;
  StreamController<String>? _speechStreamController;

  SpeechRepositoryImpl({
    required this.dataSource,
    required this.permissionService,
    required this.deviceInfoService,
    this.geminiService,
  });

  @override
  Future<Either<Failure, bool>> isAvailable() async {
    try {
      debugPrint('📱 Checking speech recognition availability...');

      // Log device info for debugging
      final deviceCategory = deviceInfoService.getDeviceCategory();
      debugPrint('📱 Device: ${deviceInfoService.getManufacturer()} ${deviceInfoService.getModel()} (${deviceCategory.name})');

      // 1. Check microphone permission
      final hasPermission =
          await permissionService.isMicrophonePermissionGranted();
      if (!hasPermission) {
        debugPrint('❌ Microphone permission not granted');
        final isPermanent =
            await permissionService.isMicrophonePermissionPermanentlyDenied();
        if (isPermanent) {
          return const Left(PermissionPermanentlyDeniedFailure());
        }
        return const Left(PermissionDeniedFailure());
      }
      debugPrint('✅ Microphone permission granted');

      // 2. Check Google Speech Services availability
      final googleServicesAvailable =
          await deviceInfoService.isGoogleSpeechServicesAvailable();
      if (!googleServicesAvailable) {
        debugPrint('❌ Google Speech Services not available');
        return Left(GoogleSpeechServicesMissingFailure(
          deviceCategory: deviceCategory,
        ));
      }
      debugPrint('✅ Google Speech Services available');

      // 3. Check OEM-specific requirements (only for Chinese OEMs)
      if (deviceInfoService.isChineseOEM()) {
        debugPrint('📱 Chinese OEM detected, checking additional permissions...');
        final speechPermStatus =
            await permissionService.checkSpeechPermissions();

        if (!speechPermStatus.isReady) {
          debugPrint('❌ OEM-specific permissions not satisfied');
          debugPrint('   Issues: ${speechPermStatus.issues.length}');
          for (final issue in speechPermStatus.issues) {
            debugPrint('   - ${issue.title}: ${issue.description}');
          }
          return Left(ManufacturerRestrictionFailure(
            deviceCategory: deviceCategory,
            issues: speechPermStatus.issues,
          ));
        }
        debugPrint('✅ OEM-specific permissions satisfied');
      }

      // 4. Test actual speech service initialization
      final available = await dataSource.isAvailable();
      if (!available) {
        debugPrint('❌ Speech data source not available');

        // Get error message from the appropriate data source type
        String? error;
        if (dataSource is SpeechRemoteDataSourceImpl) {
          error = (dataSource as SpeechRemoteDataSourceImpl).getLastError();
        } else if (dataSource is NativeSpeechDataSource) {
          error = (dataSource as NativeSpeechDataSource).getLastError();
        }

        if (error != null && error.contains('not available')) {
          return const Left(SpeechServiceUnavailableFailure());
        }
        return const Left(SpeechNotAvailableFailure());
      }

      debugPrint('✅ Speech recognition fully available');
      return Right(available);
    } catch (e) {
      debugPrint('❌ Error checking speech availability: $e');
      return Left(SpeechRecognitionFailure(
        message: 'Failed to check speech availability: $e',
      ));
    }
  }

  @override
  Future<Either<Failure, void>> initialize() async {
    try {
      // Check permission first
      final hasPermission =
          await permissionService.isMicrophonePermissionGranted();
      if (!hasPermission) {
        // Try to request permission
        final granted = await permissionService.requestMicrophonePermission();
        if (!granted) {
          final isPermanent =
              await permissionService.isMicrophonePermissionPermanentlyDenied();
          if (isPermanent) {
            return const Left(PermissionPermanentlyDeniedFailure());
          }
          return const Left(PermissionDeniedFailure());
        }
      }

      final initialized = await dataSource.initialize();
      if (initialized) {
        return const Right(null);
      } else {
        final error = (dataSource as SpeechRemoteDataSourceImpl).getLastError();
        if (error != null && error.contains('not available')) {
          return const Left(SpeechServiceUnavailableFailure());
        }
        return const Left(SpeechNotAvailableFailure());
      }
    } catch (e) {
      return Left(SpeechRecognitionFailure(
        message: 'Failed to initialize speech recognition: $e',
      ));
    }
  }

  @override
  Future<Either<Failure, Stream<String>>> startListening({String? localeId}) async {
    try {
      // Clean up any existing controller
      _speechStreamController?.close();
      _speechStreamController = StreamController<String>.broadcast();

      // Capture the stream BEFORE setting up callbacks
      // This prevents the race condition where onDone nullifies the controller
      // before we can return the stream
      final stream = _speechStreamController!.stream;

      await dataSource.startListening(
        onResult: (text) {
          // Only add if controller is still open
          if (_speechStreamController != null &&
              !_speechStreamController!.isClosed) {
            _speechStreamController?.add(text);
          }
        },
        onDone: () {
          // Close the controller but the stream reference is already captured
          _speechStreamController?.close();
          _speechStreamController = null;
        },
        onError: (error) {
          if (_speechStreamController != null &&
              !_speechStreamController!.isClosed) {
            _speechStreamController?.addError(error);
          }
          _speechStreamController?.close();
          _speechStreamController = null;
        },
        localeId: localeId,
      );

      return Right(stream);
    } catch (e) {
      _speechStreamController?.close();
      _speechStreamController = null;
      return Left(SpeechRecognitionFailure(
        message: 'Failed to start listening: $e',
      ));
    }
  }

  @override
  Future<Either<Failure, void>> stopListening() async {
    try {
      await dataSource.stopListening();
      _speechStreamController?.close();
      _speechStreamController = null;
      return const Right(null);
    } catch (e) {
      return Left(SpeechRecognitionFailure(
        message: 'Failed to stop listening: $e',
      ));
    }
  }

  @override
  Future<Either<Failure, void>> cancel() async {
    try {
      await dataSource.cancel();
      _speechStreamController?.close();
      _speechStreamController = null;
      return const Right(null);
    } catch (e) {
      return Left(SpeechRecognitionFailure(
        message: 'Failed to cancel: $e',
      ));
    }
  }

  @override
  Future<Either<Failure, SpeechCommand>> parseCommand(String text) async {
    try {
      if (text.trim().isEmpty) {
        return Left(InvalidCommandFailure(
          message: 'Command text is empty',
        ));
      }

      // Try AI parsing first if Gemini service is available
      if (geminiService != null) {
        final aiCommand = await _parseWithGemini(text);
        if (aiCommand != null && aiCommand.isValid) {
          debugPrint('✅ Using AI-parsed command');
          return Right(aiCommand);
        }
        debugPrint('⚠️ AI parsing failed or invalid, falling back to local parser');
      }

      // Fallback to local rule-based parsing
      final command = CommandParser.parse(text);

      if (!command.isValid) {
        return Left(InvalidCommandFailure(
          message: 'Could not extract valid amount from command',
        ));
      }

      return Right(command);
    } catch (e) {
      return Left(InvalidCommandFailure(
        message: 'Failed to parse command: $e',
      ));
    }
  }

  /// Parse voice command using Gemini AI
  /// Uses a 5-second timeout to prevent blocking the fallback parser
  Future<SpeechCommand?> _parseWithGemini(String text) async {
    try {
      final result = await geminiService!
          .parseVoiceCommand(text)
          .timeout(const Duration(seconds: 5));

      if (result == null) return null;

      final amount = (result['amount'] as num?)?.toDouble();
      if (amount == null || amount <= 0) return null;

      // Parse date if provided
      DateTime? parsedDate;
      if (result['date'] != null && result['date'] != 'null') {
        try {
          parsedDate = DateTime.parse(result['date']);
        } catch (e) {
          debugPrint('⚠️ Failed to parse date: ${result['date']}');
        }
      }

      return SpeechCommand(
        amount: amount,
        categoryName: result['category'] as String?,
        description: result['description'] as String?,
        isIncome: result['isIncome'] as bool? ?? false,
        date: parsedDate,
        confidence: (result['confidence'] as num?)?.toDouble() ?? 0.8,
      );
    } on TimeoutException {
      debugPrint('⚠️ Gemini parsing timed out, falling back to local parser');
      return null;
    } catch (e) {
      debugPrint('❌ Gemini parsing failed: $e');
      return null;
    }
  }
}

