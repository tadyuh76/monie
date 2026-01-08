import 'package:equatable/equatable.dart';
import 'package:monie/core/services/permission_service.dart';

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

/// Event to request microphone permission
class RequestPermissionEvent extends SpeechEvent {
  const RequestPermissionEvent();
}

/// Event to open app settings for manual permission grant
class OpenAppSettingsEvent extends SpeechEvent {
  const OpenAppSettingsEvent();
}

// ===== Device-Specific Events =====

/// Retry permission check after user returns from settings
class RetryPermissionCheckEvent extends SpeechEvent {
  const RetryPermissionCheckEvent();
}

/// Open Google Play Store to install/update Google app
class OpenGooglePlayStoreEvent extends SpeechEvent {
  const OpenGooglePlayStoreEvent();
}

/// Open manufacturer-specific settings
class OpenManufacturerSettingsEvent extends SpeechEvent {
  final SettingType type;

  const OpenManufacturerSettingsEvent({required this.type});

  @override
  List<Object?> get props => [type];
}

/// Complete current permission step and move to next
class CompletePermissionStepEvent extends SpeechEvent {
  final int stepIndex;

  const CompletePermissionStepEvent({required this.stepIndex});

  @override
  List<Object?> get props => [stepIndex];
}

/// Execute a specific permission issue action
class ExecutePermissionActionEvent extends SpeechEvent {
  final PermissionIssue issue;

  const ExecutePermissionActionEvent({required this.issue});

  @override
  List<Object?> get props => [issue];
}

