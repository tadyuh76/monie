import 'package:permission_handler/permission_handler.dart' as permission_handler;
import 'package:flutter/foundation.dart';
import 'package:monie/core/services/device_info_service.dart';

/// Severity level for permission issues
enum IssueSeverity { critical, warning, info }

/// Setting type for OEM-specific settings
enum SettingType { autoStart, batteryOptimization, microphone, appDetails }

/// Represents a specific permission issue with action to resolve it
class PermissionIssue {
  final String title;
  final String description;
  final String actionLabel;
  final Future<void> Function() action;
  final IssueSeverity severity;
  final SettingType? settingType;

  const PermissionIssue({
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.action,
    required this.severity,
    this.settingType,
  });
}

/// Comprehensive speech permission status
class SpeechPermissionStatus {
  final bool hasMicrophone;
  final bool batteryOptimized; // true = needs exemption
  final bool isReady; // true = all permissions granted
  final List<PermissionIssue> issues;

  const SpeechPermissionStatus({
    required this.hasMicrophone,
    required this.batteryOptimized,
    required this.isReady,
    required this.issues,
  });

  /// Factory for ready state (all permissions granted)
  factory SpeechPermissionStatus.ready() {
    return const SpeechPermissionStatus(
      hasMicrophone: true,
      batteryOptimized: false,
      isReady: true,
      issues: [],
    );
  }

  /// Factory for not ready state with issues
  factory SpeechPermissionStatus.notReady({
    required bool hasMicrophone,
    required bool batteryOptimized,
    required List<PermissionIssue> issues,
  }) {
    return SpeechPermissionStatus(
      hasMicrophone: hasMicrophone,
      batteryOptimized: batteryOptimized,
      isReady: false,
      issues: issues,
    );
  }
}

/// Service for handling runtime permissions
class PermissionService {
  final DeviceInfoService _deviceInfoService;

  PermissionService({required DeviceInfoService deviceInfoService})
      : _deviceInfoService = deviceInfoService;
  /// Check if microphone permission is granted
  Future<bool> isMicrophonePermissionGranted() async {
    final status = await permission_handler.Permission.microphone.status;
    return status.isGranted;
  }

  /// Request microphone permission
  /// Returns true if granted, false otherwise
  Future<bool> requestMicrophonePermission() async {
    final status = await permission_handler.Permission.microphone.request();
    debugPrint('📱 Microphone permission status: ${status.name}');
    return status.isGranted;
  }

  /// Check if permission is permanently denied
  Future<bool> isMicrophonePermissionPermanentlyDenied() async {
    final status = await permission_handler.Permission.microphone.status;
    return status.isPermanentlyDenied;
  }

  /// Open app settings so user can grant permission manually
  Future<void> openAppSettings() async {
    debugPrint('🔧 Opening app settings');
    await permission_handler.openAppSettings();
  }

  /// Get user-friendly message based on permission status
  Future<String> getMicrophonePermissionMessage() async {
    final status = await permission_handler.Permission.microphone.status;

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

  // ===== OEM-Specific Permission Methods =====

  /// Check if battery optimization is ignored
  /// Returns true if app is exempted from battery optimization
  Future<bool> isBatteryOptimizationIgnored() async {
    return await _deviceInfoService.isBatteryOptimizationIgnored();
  }

  /// Request to ignore battery optimization
  /// Opens settings for user to manually exempt the app
  Future<bool> requestIgnoreBatteryOptimization() async {
    try {
      debugPrint('🔋 Requesting battery optimization exemption...');
      await _deviceInfoService.openBatteryOptimizationSettings();
      // Return current status (user needs to manually grant in settings)
      return await isBatteryOptimizationIgnored();
    } catch (e) {
      debugPrint('❌ Error requesting battery optimization: $e');
      return false;
    }
  }

  /// Open battery optimization settings
  Future<void> openBatteryOptimizationSettings() async {
    await _deviceInfoService.openBatteryOptimizationSettings();
  }

  /// Open auto-start settings (OEM-specific)
  Future<void> openAutoStartSettings() async {
    await _deviceInfoService.openAutoStartSettings();
  }

  /// Open manufacturer-specific permission settings
  Future<void> openManufacturerPermissionSettings() async {
    await _deviceInfoService.openManufacturerPermissionSettings();
  }

  // ===== Comprehensive Permission Check =====

  /// Check all speech-related permissions
  /// Returns status with list of issues to resolve
  Future<SpeechPermissionStatus> checkSpeechPermissions() async {
    final issues = <PermissionIssue>[];

    // 1. Check microphone permission
    final hasMicrophone = await isMicrophonePermissionGranted();
    if (!hasMicrophone) {
      final isPermanentlyDenied = await isMicrophonePermissionPermanentlyDenied();

      issues.add(PermissionIssue(
        title: 'Microphone Permission',
        description: isPermanentlyDenied
            ? 'Microphone permission was denied. Open settings to grant permission.'
            : 'Allow Monie to access your microphone for voice commands.',
        actionLabel: isPermanentlyDenied ? 'Open Settings' : 'Grant Permission',
        action: () async {
          if (isPermanentlyDenied) {
            await openAppSettings();
          } else {
            await requestMicrophonePermission();
          }
        },
        severity: IssueSeverity.critical,
        settingType: SettingType.microphone,
      ));
    }

    // 2. Check battery optimization (only for Chinese OEMs)
    bool batteryOptimized = false;
    if (_deviceInfoService.isChineseOEM()) {
      final deviceName = _deviceInfoService.getDeviceCategoryName();
      batteryOptimized = !(await isBatteryOptimizationIgnored());
      if (batteryOptimized) {
        issues.add(PermissionIssue(
          title: 'Battery Optimization',
          description:
              '$deviceName devices need battery optimization disabled for voice commands to work in background.',
          actionLabel: 'Disable Battery Optimization',
          action: openBatteryOptimizationSettings,
          severity: IssueSeverity.critical,
          settingType: SettingType.batteryOptimization,
        ));
      }

      // 3. Check auto-start (only for Vivo/Oppo/Xiaomi)
      // Note: We can't programmatically check auto-start status,
      // so we always show this as a warning for Chinese OEMs
      issues.add(PermissionIssue(
        title: 'Auto-Start Permission',
        description:
            '$deviceName devices require auto-start permission for apps to run in background. Please enable it in settings.',
        actionLabel: 'Open Auto-Start Settings',
        action: openAutoStartSettings,
        severity: IssueSeverity.warning,
        settingType: SettingType.autoStart,
      ));
    }

    // Determine if ready
    final isReady = hasMicrophone && !batteryOptimized;

    if (isReady) {
      return SpeechPermissionStatus.ready();
    } else {
      return SpeechPermissionStatus.notReady(
        hasMicrophone: hasMicrophone,
        batteryOptimized: batteryOptimized,
        issues: issues,
      );
    }
  }

  /// Get list of denied permissions
  /// Convenience method to get only the critical issues
  Future<List<PermissionIssue>> getDeniedPermissions() async {
    final status = await checkSpeechPermissions();
    return status.issues
        .where((issue) => issue.severity == IssueSeverity.critical)
        .toList();
  }
}
