import 'package:equatable/equatable.dart';

abstract class SpeechEvent extends Equatable {
  const SpeechEvent();

  @override
  List<Object?> get props => [];
}

class StartListeningEvent extends SpeechEvent {
  const StartListeningEvent();
}

class StopListeningEvent extends SpeechEvent {
  const StopListeningEvent();
}

class CancelListeningEvent extends SpeechEvent {
  const CancelListeningEvent();
}

class SpeechResultReceivedEvent extends SpeechEvent {
  final String text;

  const SpeechResultReceivedEvent(this.text);

  @override
  List<Object?> get props => [text];
}

class ParseCommandEvent extends SpeechEvent {
  final String text;

  const ParseCommandEvent(this.text);

  @override
  List<Object?> get props => [text];
}

class CreateTransactionFromCommandEvent extends SpeechEvent {
  final String userId;

  const CreateTransactionFromCommandEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Event to open transaction form with pre-filled data from parsed command
class OpenTransactionFormEvent extends SpeechEvent {
  const OpenTransactionFormEvent();
}

class ResetSpeechStateEvent extends SpeechEvent {
  const ResetSpeechStateEvent();
}

