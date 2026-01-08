import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:monie/core/errors/failures.dart';
import 'package:monie/core/services/gemini_service.dart';
import 'package:monie/features/speech_to_command/data/datasources/speech_remote_data_source.dart';
import 'package:monie/core/utils/command_parser.dart';
import 'package:monie/features/speech_to_command/domain/entities/speech_command.dart';
import 'package:monie/features/speech_to_command/domain/repositories/speech_repository.dart';

class SpeechRepositoryImpl implements SpeechRepository {
  final SpeechRemoteDataSource dataSource;
  final GeminiService? geminiService;
  StreamController<String>? _speechStreamController;

  SpeechRepositoryImpl({
    required this.dataSource,
    this.geminiService,
  });

  @override
  Future<Either<Failure, bool>> isAvailable() async {
    try {
      final available = await dataSource.isAvailable();
      return Right(available);
    } catch (e) {
      return Left(SpeechRecognitionFailure(
        message: 'Failed to check speech availability: $e',
      ));
    }
  }

  @override
  Future<Either<Failure, void>> initialize() async {
    try {
      final initialized = await dataSource.initialize();
      if (initialized) {
        return const Right(null);
      } else {
        return Left(SpeechNotAvailableFailure());
      }
    } catch (e) {
      return Left(SpeechRecognitionFailure(
        message: 'Failed to initialize speech recognition: $e',
      ));
    }
  }

  @override
  Future<Either<Failure, Stream<String>>> startListening() async {
    try {
      _speechStreamController?.close();
      _speechStreamController = StreamController<String>.broadcast();

      await dataSource.startListening(
        onResult: (text) {
          _speechStreamController?.add(text);
        },
        onDone: () {
          _speechStreamController?.close();
          _speechStreamController = null;
        },
        onError: (error) {
          _speechStreamController?.addError(error);
          _speechStreamController?.close();
          _speechStreamController = null;
        },
      );

      return Right(_speechStreamController!.stream);
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
  Future<SpeechCommand?> _parseWithGemini(String text) async {
    try {
      final result = await geminiService!.parseVoiceCommand(text);

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
    } catch (e) {
      debugPrint('❌ Gemini parsing failed: $e');
      return null;
    }
  }
}

