import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:monie/core/errors/failures.dart';
import 'package:monie/core/services/permission_service.dart';
import 'package:monie/features/speech_to_command/domain/entities/speech_command.dart';
import 'package:monie/features/speech_to_command/domain/usecases/create_transaction_from_command_usecase.dart';
import 'package:monie/features/speech_to_command/domain/usecases/parse_command_usecase.dart';
import 'package:monie/features/speech_to_command/domain/usecases/recognize_speech_usecase.dart';
import 'package:monie/features/speech_to_command/presentation/bloc/speech_event.dart';
import 'package:monie/features/speech_to_command/presentation/bloc/speech_state.dart';

class SpeechBloc extends Bloc<SpeechEvent, SpeechState> {
  final RecognizeSpeech _recognizeSpeech;
  final ParseCommand _parseCommand;
  final CreateTransactionFromCommand? _createTransactionFromCommand;
  final PermissionService _permissionService;

  StreamSubscription<String>? _speechSubscription;
  SpeechCommand? _currentCommand;
  String? _currentOriginalText;

  SpeechBloc({
    required RecognizeSpeech recognizeSpeech,
    required ParseCommand parseCommand,
    required PermissionService permissionService,
    CreateTransactionFromCommand? createTransactionFromCommand,
  })  : _recognizeSpeech = recognizeSpeech,
        _parseCommand = parseCommand,
        _permissionService = permissionService,
        _createTransactionFromCommand = createTransactionFromCommand,
        super(const SpeechInitial()) {
    on<StartListeningEvent>(_onStartListening);
    on<StopListeningEvent>(_onStopListening);
    on<CancelListeningEvent>(_onCancelListening);
    on<SpeechResultReceivedEvent>(_onSpeechResultReceived);
    on<ParseCommandEvent>(_onParseCommand);
    on<CreateTransactionFromCommandEvent>(_onCreateTransactionFromCommand);
    on<OpenTransactionFormEvent>(_onOpenTransactionForm);
    on<ResetSpeechStateEvent>(_onResetSpeechState);
    on<RequestPermissionEvent>(_onRequestPermission);
    on<OpenAppSettingsEvent>(_onOpenAppSettings);
    // Device-specific event handlers
    on<RetryPermissionCheckEvent>(_onRetryPermissionCheck);
    on<OpenGooglePlayStoreEvent>(_onOpenGooglePlayStore);
    on<OpenManufacturerSettingsEvent>(_onOpenManufacturerSettings);
    on<ExecutePermissionActionEvent>(_onExecutePermissionAction);
  }

  Future<void> _onStartListening(
    StartListeningEvent event,
    Emitter<SpeechState> emit,
  ) async {
    // If already listening or processing, cancel first to avoid conflicts
    if (state is SpeechListening ||
        state is SpeechCheckingAvailability ||
        state is CommandParsing) {
      debugPrint('⚠️ Already in active state, canceling first...');
      await _speechSubscription?.cancel();
      _speechSubscription = null;
      await _recognizeSpeech.repository.cancel();
      // Small delay to ensure cleanup completes
      await Future.delayed(const Duration(milliseconds: 200));
    }

    emit(const SpeechCheckingAvailability());

    final result = await _recognizeSpeech(RecognizeSpeechParams());

    result.fold(
      (failure) {
        // Handle device-specific failures
        if (failure is GoogleSpeechServicesMissingFailure) {
          emit(GoogleServicesRequired(
            isInstalled: false,
            currentVersion: null,
          ));
        } else if (failure is ManufacturerRestrictionFailure) {
          emit(ManufacturerRestriction(
            deviceCategory: failure.deviceCategory,
            issues: failure.issues,
            currentStepIndex: 0,
          ));
        } else if (failure is PermissionDeniedFailure) {
          emit(PermissionRequired(
            message: failure.message,
            isPermanentlyDenied: false,
          ));
        } else if (failure is PermissionPermanentlyDeniedFailure) {
          emit(PermissionRequired(
            message: failure.message,
            isPermanentlyDenied: true,
          ));
        } else {
          emit(SpeechNotAvailable(failure.message));
        }
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
    // Cancel BLoC's subscription first
    await _speechSubscription?.cancel();
    _speechSubscription = null;

    // Now stop the native service to prevent background listening
    await _recognizeSpeech.repository.stopListening();
    debugPrint('✅ Stopped listening - native service stopped');

    // If we have a result, keep it; otherwise reset
    if (state is! SpeechResultReceived) {
      emit(const SpeechInitial());
    }
  }

  Future<void> _onCancelListening(
    CancelListeningEvent event,
    Emitter<SpeechState> emit,
  ) async {
    // Cancel BLoC's subscription first
    await _speechSubscription?.cancel();
    _speechSubscription = null;

    // Now cancel the native service
    await _recognizeSpeech.repository.cancel();
    debugPrint('✅ Cancelled listening - native service cancelled');

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
        _currentOriginalText = event.text;
        emit(CommandParsed(
          command: command,
          originalText: event.text,
        ));
      },
    );
  }

  Future<void> _onOpenTransactionForm(
    OpenTransactionFormEvent event,
    Emitter<SpeechState> emit,
  ) async {
    if (_currentCommand == null) {
      emit(const SpeechError('No command available'));
      return;
    }

    emit(CommandReadyForForm(
      command: _currentCommand!,
      originalText: _currentOriginalText ?? '',
    ));
  }

  Future<void> _onCreateTransactionFromCommand(
    CreateTransactionFromCommandEvent event,
    Emitter<SpeechState> emit,
  ) async {
    if (_currentCommand == null) {
      emit(const SpeechError('No command to create transaction from'));
      return;
    }

    if (_createTransactionFromCommand == null) {
      emit(const SpeechError('Transaction creation not available'));
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

  Future<void> _onRequestPermission(
    RequestPermissionEvent event,
    Emitter<SpeechState> emit,
  ) async {
    emit(const SpeechCheckingAvailability());

    // Request permission
    final granted = await _permissionService.requestMicrophonePermission();

    if (granted) {
      // Permission granted, try to start listening
      emit(const SpeechInitial());
      add(const StartListeningEvent());
    } else {
      // Check if permanently denied
      final isPermanent =
          await _permissionService.isMicrophonePermissionPermanentlyDenied();
      if (isPermanent) {
        emit(const PermissionRequired(
          message:
              'Microphone permission was permanently denied. Please enable it in Settings > Apps > Monie > Permissions.',
          isPermanentlyDenied: true,
        ));
      } else {
        emit(const PermissionRequired(
          message:
              'Microphone permission is required. Please grant permission to use voice commands.',
          isPermanentlyDenied: false,
        ));
      }
    }
  }

  Future<void> _onOpenAppSettings(
    OpenAppSettingsEvent event,
    Emitter<SpeechState> emit,
  ) async {
    await _permissionService.openAppSettings();
  }

  // ===== Device-Specific Event Handlers =====

  /// Retry permission check after user returns from settings
  Future<void> _onRetryPermissionCheck(
    RetryPermissionCheckEvent event,
    Emitter<SpeechState> emit,
  ) async {
    // Re-trigger the availability check
    emit(const SpeechCheckingAvailability());
    add(const StartListeningEvent());
  }

  /// Open Google Play Store to install/update Google app
  Future<void> _onOpenGooglePlayStore(
    OpenGooglePlayStoreEvent event,
    Emitter<SpeechState> emit,
  ) async {
    // Open Play Store with Google app package
    // This will be handled by the UI layer opening an external link
    // The event is here for state tracking if needed
  }

  /// Open manufacturer-specific settings
  Future<void> _onOpenManufacturerSettings(
    OpenManufacturerSettingsEvent event,
    Emitter<SpeechState> emit,
  ) async {
    switch (event.type) {
      case SettingType.autoStart:
        await _permissionService.openAutoStartSettings();
        break;
      case SettingType.batteryOptimization:
        await _permissionService.openBatteryOptimizationSettings();
        break;
      case SettingType.microphone:
        await _permissionService.openAppSettings();
        break;
      case SettingType.appDetails:
        await _permissionService.openAppSettings();
        break;
    }
  }

  /// Execute a specific permission issue action
  Future<void> _onExecutePermissionAction(
    ExecutePermissionActionEvent event,
    Emitter<SpeechState> emit,
  ) async {
    // Execute the action callback from the PermissionIssue
    await event.issue.action();
  }

  @override
  Future<void> close() {
    _speechSubscription?.cancel();
    return super.close();
  }
}

