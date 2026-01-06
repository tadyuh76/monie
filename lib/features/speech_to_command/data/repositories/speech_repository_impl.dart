import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:monie/core/errors/failures.dart';
import 'package:monie/features/speech_to_command/data/datasources/speech_remote_data_source.dart';
import 'package:monie/core/utils/command_parser.dart';
import 'package:monie/features/speech_to_command/domain/entities/speech_command.dart';
import 'package:monie/features/speech_to_command/domain/repositories/speech_repository.dart';

class SpeechRepositoryImpl implements SpeechRepository {
  final SpeechRemoteDataSource dataSource;
  StreamController<String>? _speechStreamController;

  SpeechRepositoryImpl({required this.dataSource});

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
}

