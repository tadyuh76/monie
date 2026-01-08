import 'package:equatable/equatable.dart';
import 'package:monie/features/speech_to_command/domain/entities/speech_command.dart';
import 'package:monie/features/transactions/domain/entities/transaction.dart';
import 'package:monie/core/services/device_info_service.dart';
import 'package:monie/core/services/permission_service.dart';

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

// ===== Device-Specific States =====

/// Google Speech Services (Google app) is required
class GoogleServicesRequired extends SpeechState {
  final bool isInstalled;
  final String? currentVersion;

  const GoogleServicesRequired({
    required this.isInstalled,
    this.currentVersion,
  });

  @override
  List<Object?> get props => [isInstalled, currentVersion];
}

/// Manufacturer-specific restrictions detected (Vivo/Oppo/Xiaomi)
class ManufacturerRestriction extends SpeechState {
  final DeviceCategory deviceCategory;
  final List<PermissionIssue> issues;
  final int currentStepIndex;

  const ManufacturerRestriction({
    required this.deviceCategory,
    required this.issues,
    this.currentStepIndex = 0,
  });

  @override
  List<Object?> get props => [deviceCategory, issues, currentStepIndex];

  /// Get current issue being addressed
  PermissionIssue get currentIssue => issues[currentStepIndex];

  /// Check if there are more steps
  bool get hasMoreSteps => currentStepIndex < issues.length - 1;

  /// Get total number of steps
  int get totalSteps => issues.length;

  /// Copy with updated step index
  ManufacturerRestriction copyWithNextStep() {
    if (!hasMoreSteps) return this;
    return ManufacturerRestriction(
      deviceCategory: deviceCategory,
      issues: issues,
      currentStepIndex: currentStepIndex + 1,
    );
  }
}

/// Multi-step permission setup flow
class PermissionSetupRequired extends SpeechState {
  final List<PermissionIssue> issues;
  final int currentStep;
  final int totalSteps;

  const PermissionSetupRequired({
    required this.issues,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  List<Object?> get props => [issues, currentStep, totalSteps];
}

