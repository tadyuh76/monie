import 'package:dartz/dartz.dart';
import 'package:monie/core/errors/failures.dart';
import 'package:monie/features/speech_to_command/domain/entities/speech_command.dart';

/// Repository interface for speech recognition and command parsing
abstract class SpeechRepository {
  /// Check if speech recognition is available on the device
  Future<Either<Failure, bool>> isAvailable();

  /// Initialize speech recognition
  Future<Either<Failure, void>> initialize();

  /// Start listening for speech input
  /// [localeId] - Language locale (e.g., 'vi_VN' for Vietnamese, 'en_US' for English)
  Future<Either<Failure, Stream<String>>> startListening({String? localeId});

  /// Stop listening for speech input
  Future<Either<Failure, void>> stopListening();

  /// Cancel speech recognition
  Future<Either<Failure, void>> cancel();

  /// Parse text command into SpeechCommand entity
  /// Supports Vietnamese and English commands
  /// Examples:
  /// - "chi 50000 cho ăn uống" -> amount: 50000, category: "Dining"
  /// - "thu 100000 từ lương" -> amount: 100000, isIncome: true, category: "Salary"
  /// - "spend 50000 on groceries" -> amount: 50000, category: "Groceries"
  Future<Either<Failure, SpeechCommand>> parseCommand(String text);
}

