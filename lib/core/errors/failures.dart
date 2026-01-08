import 'package:equatable/equatable.dart';
import 'package:monie/core/services/device_info_service.dart';
import 'package:monie/core/services/permission_service.dart';

/// Base failure class
abstract class Failure extends Equatable {
  final String message;

  const Failure({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Server failure when API requests fail
class ServerFailure extends Failure {
  const ServerFailure({required super.message});
}

/// Cache failure for local storage issues
class CacheFailure extends Failure {
  const CacheFailure({required super.message});
}

/// Network failure for connectivity issues
class NetworkFailure extends Failure {
  const NetworkFailure({required super.message});
}

/// Authentication failure for auth-related issues
class AuthFailure extends Failure {
  const AuthFailure({required super.message});
}

/// Email verification failure
class EmailVerificationFailure extends Failure {
  const EmailVerificationFailure({required super.message});
}

/// Speech recognition not available failure
class SpeechNotAvailableFailure extends Failure {
  const SpeechNotAvailableFailure()
      : super(message: 'Speech recognition is not available on this device');
}

/// Invalid command failure
class InvalidCommandFailure extends Failure {
  const InvalidCommandFailure({required super.message});
}

/// Speech recognition failure
class SpeechRecognitionFailure extends Failure {
  const SpeechRecognitionFailure({required super.message});
}

/// Permission denied failure - user can retry
class PermissionDeniedFailure extends Failure {
  const PermissionDeniedFailure()
      : super(
            message:
                'Microphone permission is required. Please grant permission to use voice commands.');
}

/// Permission permanently denied - user must go to settings
class PermissionPermanentlyDeniedFailure extends Failure {
  const PermissionPermanentlyDeniedFailure()
      : super(
            message:
                'Microphone permission was permanently denied. Please enable it in Settings > Apps > Monie > Permissions.');
}

/// Speech service not available on device
class SpeechServiceUnavailableFailure extends Failure {
  const SpeechServiceUnavailableFailure()
      : super(
            message:
                'Speech recognition service is not available. Please ensure Google app is installed and updated.');
}

/// Locale not available failure with fallback suggestion
class LocaleNotAvailableFailure extends Failure {
  final String requestedLocale;
  final String fallbackLocale;

  const LocaleNotAvailableFailure({
    required this.requestedLocale,
    required this.fallbackLocale,
  }) : super(
            message:
                'Language "$requestedLocale" is not available. Using "$fallbackLocale" instead.');

  @override
  List<Object> get props => [message, requestedLocale, fallbackLocale];
}

// ===== Device-Specific Failures =====

/// Google Speech Services (Google app) is not installed
class GoogleSpeechServicesMissingFailure extends Failure {
  final DeviceCategory? deviceCategory;

  const GoogleSpeechServicesMissingFailure({
    this.deviceCategory,
  }) : super(
            message:
                'Google app is required for speech recognition. Please install it from the Play Store.');

  @override
  List<Object?> get props => [message, deviceCategory];
}

/// Google Speech Services is outdated
class GoogleSpeechServicesOutdatedFailure extends Failure {
  final String? currentVersion;
  final String? requiredVersion;

  const GoogleSpeechServicesOutdatedFailure({
    this.currentVersion,
    this.requiredVersion,
  }) : super(
            message:
                'Your Google app version is outdated. Please update it from the Play Store.');

  @override
  List<Object?> get props => [message, currentVersion, requiredVersion];
}

/// Battery optimization is blocking speech recognition
class BatteryOptimizationBlockingFailure extends Failure {
  final DeviceCategory deviceCategory;

  const BatteryOptimizationBlockingFailure({
    required this.deviceCategory,
  }) : super(
            message:
                'Battery optimization is preventing speech recognition from working. Please disable it in settings.');

  @override
  List<Object> get props => [message, deviceCategory];
}

/// Auto-start is disabled (OEM-specific)
class AutoStartDisabledFailure extends Failure {
  final DeviceCategory deviceCategory;

  const AutoStartDisabledFailure({
    required this.deviceCategory,
  }) : super(
            message:
                'Auto-start permission is required for speech recognition to work in background. Please enable it in settings.');

  @override
  List<Object> get props => [message, deviceCategory];
}

/// Manufacturer-specific restrictions detected
class ManufacturerRestrictionFailure extends Failure {
  final DeviceCategory deviceCategory;
  final List<PermissionIssue> issues;

  const ManufacturerRestrictionFailure({
    required this.deviceCategory,
    required this.issues,
  }) : super(
            message:
                'Your device requires additional permissions for speech recognition to work.');

  @override
  List<Object> get props => [message, deviceCategory, issues];
}