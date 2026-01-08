import 'package:equatable/equatable.dart';
import 'package:monie/features/speech_to_command/domain/entities/speech_command.dart';
import 'package:monie/features/transactions/domain/entities/transaction.dart';

abstract class SpeechState extends Equatable {
  const SpeechState();

  @override
  List<Object?> get props => [];
}

class SpeechInitial extends SpeechState {
  const SpeechInitial();
}

class SpeechCheckingAvailability extends SpeechState {
  const SpeechCheckingAvailability();
}

class SpeechAvailable extends SpeechState {
  const SpeechAvailable();
}

class SpeechNotAvailable extends SpeechState {
  final String message;

  const SpeechNotAvailable(this.message);

  @override
  List<Object?> get props => [message];
}

class SpeechListening extends SpeechState {
  final String? partialText;

  const SpeechListening({this.partialText});

  @override
  List<Object?> get props => [partialText];
}

class SpeechResultReceived extends SpeechState {
  final String text;

  const SpeechResultReceived(this.text);

  @override
  List<Object?> get props => [text];
}

class CommandParsing extends SpeechState {
  final String text;

  const CommandParsing(this.text);

  @override
  List<Object?> get props => [text];
}

class CommandParsed extends SpeechState {
  final SpeechCommand command;
  final String originalText;

  const CommandParsed({
    required this.command,
    required this.originalText,
  });

  @override
  List<Object?> get props => [command, originalText];
}

class CommandParseError extends SpeechState {
  final String message;
  final String? originalText;

  const CommandParseError({
    required this.message,
    this.originalText,
  });

  @override
  List<Object?> get props => [message, originalText];
}

class CreatingTransaction extends SpeechState {
  final SpeechCommand command;

  const CreatingTransaction(this.command);

  @override
  List<Object?> get props => [command];
}

class TransactionCreated extends SpeechState {
  final Transaction transaction;

  const TransactionCreated(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

/// State for opening transaction form with pre-filled data from voice command
class CommandReadyForForm extends SpeechState {
  final SpeechCommand command;
  final String originalText;

  const CommandReadyForForm({
    required this.command,
    required this.originalText,
  });

  @override
  List<Object?> get props => [command, originalText];
}

class SpeechError extends SpeechState {
  final String message;

  const SpeechError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Permission required state - show permission request prompt
class PermissionRequired extends SpeechState {
  final String message;
  final bool isPermanentlyDenied;

  const PermissionRequired({
    required this.message,
    this.isPermanentlyDenied = false,
  });

  @override
  List<Object?> get props => [message, isPermanentlyDenied];
}

