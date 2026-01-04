import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:monie/features/speech_to_command/domain/usecases/create_transaction_from_command_usecase.dart';
import 'package:monie/features/speech_to_command/domain/usecases/parse_command_usecase.dart';
import 'package:monie/features/speech_to_command/domain/usecases/recognize_speech_usecase.dart';
import 'package:monie/features/speech_to_command/presentation/bloc/speech_event.dart';
import 'package:monie/features/speech_to_command/presentation/bloc/speech_state.dart';

class SpeechBloc extends Bloc<SpeechEvent, SpeechState> {
  final RecognizeSpeech _recognizeSpeech;
  final ParseCommand _parseCommand;
  final CreateTransactionFromCommand _createTransactionFromCommand;
  
  StreamSubscription<String>? _speechSubscription;
  SpeechCommand? _currentCommand;

  SpeechBloc({
    required RecognizeSpeech recognizeSpeech,
    required ParseCommand parseCommand,
    required CreateTransactionFromCommand createTransactionFromCommand,
  })  : _recognizeSpeech = recognizeSpeech,
        _parseCommand = parseCommand,
        _createTransactionFromCommand = createTransactionFromCommand,
        super(const SpeechInitial()) {
    on<StartListeningEvent>(_onStartListening);
    on<StopListeningEvent>(_onStopListening);
    on<CancelListeningEvent>(_onCancelListening);
    on<SpeechResultReceivedEvent>(_onSpeechResultReceived);
    on<ParseCommandEvent>(_onParseCommand);
    on<CreateTransactionFromCommandEvent>(_onCreateTransactionFromCommand);
    on<ResetSpeechStateEvent>(_onResetSpeechState);
  }

  Future<void> _onStartListening(
    StartListeningEvent event,
    Emitter<SpeechState> emit,
  ) async {
    emit(const SpeechCheckingAvailability());
    
    final result = await _recognizeSpeech(RecognizeSpeechParams());
    
    result.fold(
      (failure) {
        emit(SpeechNotAvailable(failure.message));
      },
      (speechStream) {
        emit(const SpeechListening());
        _speechSubscription?.cancel();
        _speechSubscription = speechStream.listen(
          (text) {
            if (text.isNotEmpty) {
              add(SpeechResultReceivedEvent(text));
            }
          },
          onError: (error) {
            emit(SpeechError(error.toString()));
          },
          onDone: () {
            // Stream is done, but we keep the state as SpeechResultReceived
            // if we have text, otherwise reset
            if (state is SpeechResultReceived) {
              // Keep the result
            } else {
              emit(const SpeechInitial());
            }
          },
        );
      },
    );
  }

  Future<void> _onStopListening(
    StopListeningEvent event,
    Emitter<SpeechState> emit,
  ) async {
    await _speechSubscription?.cancel();
    _speechSubscription = null;
    
    // If we have a result, keep it; otherwise reset
    if (state is! SpeechResultReceived) {
      emit(const SpeechInitial());
    }
  }

  Future<void> _onCancelListening(
    CancelListeningEvent event,
    Emitter<SpeechState> emit,
  ) async {
    await _speechSubscription?.cancel();
    _speechSubscription = null;
    _currentCommand = null;
    emit(const SpeechInitial());
  }

  Future<void> _onSpeechResultReceived(
    SpeechResultReceivedEvent event,
    Emitter<SpeechState> emit,
  ) async {
    emit(SpeechResultReceived(event.text));
    
    // Automatically parse the command
    add(ParseCommandEvent(event.text));
  }

  Future<void> _onParseCommand(
    ParseCommandEvent event,
    Emitter<SpeechState> emit,
  ) async {
    emit(CommandParsing(event.text));
    
    final result = await _parseCommand(ParseCommandParams(text: event.text));
    
    result.fold(
      (failure) {
        emit(CommandParseError(
          message: failure.message,
          originalText: event.text,
        ));
      },
      (command) {
        _currentCommand = command;
        emit(CommandParsed(
          command: command,
          originalText: event.text,
        ));
      },
    );
  }

  Future<void> _onCreateTransactionFromCommand(
    CreateTransactionFromCommandEvent event,
    Emitter<SpeechState> emit,
  ) async {
    if (_currentCommand == null) {
      emit(const SpeechError('No command to create transaction from'));
      return;
    }

    emit(CreatingTransaction(_currentCommand!));
    
    final result = await _createTransactionFromCommand(
      CreateTransactionFromCommandParams(
        command: _currentCommand!,
        userId: event.userId,
      ),
    );
    
    result.fold(
      (failure) {
        emit(SpeechError(failure.message));
      },
      (transaction) {
        emit(TransactionCreated(transaction));
        _currentCommand = null;
      },
    );
  }

  Future<void> _onResetSpeechState(
    ResetSpeechStateEvent event,
    Emitter<SpeechState> emit,
  ) async {
    await _speechSubscription?.cancel();
    _speechSubscription = null;
    _currentCommand = null;
    emit(const SpeechInitial());
  }

  @override
  Future<void> close() {
    _speechSubscription?.cancel();
    return super.close();
  }
}

