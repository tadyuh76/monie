import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

/// Service for handling runtime permissions
class PermissionService {
  /// Check if microphone permission is granted
  Future<bool> isMicrophonePermissionGranted() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  /// Request microphone permission
  /// Returns true if granted, false otherwise
  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    debugPrint('📱 Microphone permission status: ${status.name}');
    return status.isGranted;
  }

  /// Check if permission is permanently denied
  Future<bool> isMicrophonePermissionPermanentlyDenied() async {
    final status = await Permission.microphone.status;
    return status.isPermanentlyDenied;
  }

  /// Open app settings so user can grant permission manually
  Future<void> openAppSettings() async {
    debugPrint('🔧 Opening app settings');
    await openAppSettings();
  }

  /// Get user-friendly message based on permission status
  Future<String> getMicrophonePermissionMessage() async {
    final status = await Permission.microphone.status;

    if (status.isGranted) {
      return 'Microphone permission granted';
    } else if (status.isDenied) {
      return 'Microphone permission is required to use voice commands. Please grant permission to continue.';
    } else if (status.isPermanentlyDenied) {
      return 'Microphone permission was permanently denied. Please enable it in app settings.';
    } else if (status.isRestricted) {
      return 'Microphone access is restricted on this device.';
    } else {
      return 'Microphone permission status unknown.';
    }
  }
}
