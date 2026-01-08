import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Device category for OEM-specific handling
enum DeviceCategory {
  vivo,
  oppo,
  xiaomi,
  samsung,
  google,
  generic,
}

/// Device information including manufacturer, model, and Android version
class DeviceInfo {
  final String manufacturer;
  final String model;
  final int androidVersion;
  final String androidVersionRelease;

  const DeviceInfo({
    required this.manufacturer,
    required this.model,
    required this.androidVersion,
    required this.androidVersionRelease,
  });

  factory DeviceInfo.fromMap(Map<dynamic, dynamic> map) {
    return DeviceInfo(
      manufacturer: map['manufacturer'] as String,
      model: map['model'] as String,
      androidVersion: map['androidVersion'] as int,
      androidVersionRelease: map['androidVersionRelease'] as String,
    );
  }

  @override
  String toString() {
    return 'DeviceInfo(manufacturer: $manufacturer, model: $model, Android: $androidVersionRelease (API $androidVersion))';
  }
}

/// Service for device detection and Google Services validation
/// Communicates with native Android code via platform channel
class DeviceInfoService {
  static const MethodChannel _channel =
      MethodChannel('com.tadyuh.monie/device_info');

  // Cached device info to avoid repeated platform calls
  DeviceInfo? _cachedDeviceInfo;
  bool? _cachedGoogleServicesAvailable;
  String? _cachedGoogleAppVersion;

  /// Initialize the service and cache device information
  Future<void> initialize() async {
    try {
      debugPrint('📱 Initializing DeviceInfoService...');
      await getDeviceInfo();
      await isGoogleSpeechServicesAvailable();
      debugPrint('✅ DeviceInfoService initialized successfully');
    } catch (e) {
      debugPrint('❌ DeviceInfoService initialization failed: $e');
    }
  }

  /// Get device information (cached after first call)
  Future<DeviceInfo> getDeviceInfo() async {
    if (_cachedDeviceInfo != null) {
      return _cachedDeviceInfo!;
    }

    try {
      final Map<dynamic, dynamic> result =
          await _channel.invokeMethod('getDeviceInfo');
      _cachedDeviceInfo = DeviceInfo.fromMap(result);
      debugPrint('📱 Device info: $_cachedDeviceInfo');
      return _cachedDeviceInfo!;
    } on PlatformException catch (e) {
      debugPrint('❌ Failed to get device info: ${e.message}');
      // Return fallback device info
      _cachedDeviceInfo = const DeviceInfo(
        manufacturer: 'unknown',
        model: 'unknown',
        androidVersion: 0,
        androidVersionRelease: 'unknown',
      );
      return _cachedDeviceInfo!;
    }
  }

  /// Check if Google Speech Services (Google app) is available
  /// Required for speech recognition to work
  Future<bool> isGoogleSpeechServicesAvailable() async {
    if (_cachedGoogleServicesAvailable != null) {
      return _cachedGoogleServicesAvailable!;
    }

    try {
      final bool result =
          await _channel.invokeMethod('isGoogleSpeechServicesAvailable');
      _cachedGoogleServicesAvailable = result;
      debugPrint('📱 Google Speech Services available: $result');
      return result;
    } on PlatformException catch (e) {
      debugPrint('❌ Failed to check Google Speech Services: ${e.message}');
      _cachedGoogleServicesAvailable = false;
      return false;
    }
  }

  /// Get Google app version string
  /// Returns null if not installed
  Future<String?> getGoogleAppVersion() async {
    if (_cachedGoogleAppVersion != null) {
      return _cachedGoogleAppVersion;
    }

    try {
      final String? result = await _channel.invokeMethod('getGoogleAppVersion');
      _cachedGoogleAppVersion = result;
      debugPrint('📱 Google app version: $result');
      return result;
    } on PlatformException catch (e) {
      debugPrint('❌ Failed to get Google app version: ${e.message}');
      return null;
    }
  }

  /// Check if battery optimization is ignored
  /// Returns true if the app is exempted (good for background services)
  Future<bool> isBatteryOptimizationIgnored() async {
    try {
      final bool result =
          await _channel.invokeMethod('isBatteryOptimizationIgnored');
      debugPrint('🔋 Battery optimization ignored: $result');
      return result;
    } on PlatformException catch (e) {
      debugPrint('❌ Failed to check battery optimization: ${e.message}');
      return false;
    }
  }

  /// Open battery optimization settings
  /// Allows user to exempt the app from battery optimization
  Future<void> openBatteryOptimizationSettings() async {
    try {
      debugPrint('🔧 Opening battery optimization settings...');
      await _channel.invokeMethod('openBatteryOptimizationSettings');
    } on PlatformException catch (e) {
      debugPrint('❌ Failed to open battery optimization settings: ${e.message}');
    }
  }

  /// Open auto-start settings (OEM-specific)
  /// Opens manufacturer-specific auto-start permission screen
  Future<void> openAutoStartSettings() async {
    try {
      debugPrint('🔧 Opening auto-start settings...');
      await _channel.invokeMethod('openAutoStartSettings');
    } on PlatformException catch (e) {
      debugPrint('❌ Failed to open auto-start settings: ${e.message}');
    }
  }

  /// Open manufacturer-specific permission settings
  /// Opens OEM permission management screen if available
  Future<void> openManufacturerPermissionSettings() async {
    try {
      debugPrint('🔧 Opening manufacturer permission settings...');
      await _channel.invokeMethod('openManufacturerPermissionSettings');
    } on PlatformException catch (e) {
      debugPrint('❌ Failed to open manufacturer permission settings: ${e.message}');
    }
  }

  // ===== Device Detection Helper Methods =====

  /// Check if device is manufactured by Vivo
  bool isVivoDevice() {
    final manufacturer = _cachedDeviceInfo?.manufacturer.toLowerCase() ?? '';
    return manufacturer == 'vivo';
  }

  /// Check if device is manufactured by Oppo or Realme (same OS)
  bool isOppoDevice() {
    final manufacturer = _cachedDeviceInfo?.manufacturer.toLowerCase() ?? '';
    return manufacturer == 'oppo' || manufacturer == 'realme';
  }

  /// Check if device is manufactured by Xiaomi/Redmi/Poco
  bool isXiaomiDevice() {
    final manufacturer = _cachedDeviceInfo?.manufacturer.toLowerCase() ?? '';
    return manufacturer == 'xiaomi' ||
        manufacturer == 'redmi' ||
        manufacturer == 'poco';
  }

  /// Check if device is a Chinese OEM that requires special permission handling
  bool isChineseOEM() {
    return isVivoDevice() || isOppoDevice() || isXiaomiDevice();
  }

  /// Check if device is manufactured by Samsung
  bool isSamsungDevice() {
    final manufacturer = _cachedDeviceInfo?.manufacturer.toLowerCase() ?? '';
    return manufacturer == 'samsung';
  }

  /// Check if device is a Google Pixel
  bool isGoogleDevice() {
    final manufacturer = _cachedDeviceInfo?.manufacturer.toLowerCase() ?? '';
    return manufacturer == 'google';
  }

  /// Get device category for UI customization
  DeviceCategory getDeviceCategory() {
    if (isVivoDevice()) return DeviceCategory.vivo;
    if (isOppoDevice()) return DeviceCategory.oppo;
    if (isXiaomiDevice()) return DeviceCategory.xiaomi;
    if (isSamsungDevice()) return DeviceCategory.samsung;
    if (isGoogleDevice()) return DeviceCategory.google;
    return DeviceCategory.generic;
  }

  /// Get user-friendly device category name
  String getDeviceCategoryName() {
    switch (getDeviceCategory()) {
      case DeviceCategory.vivo:
        return 'Vivo';
      case DeviceCategory.oppo:
        return 'Oppo/Realme';
      case DeviceCategory.xiaomi:
        return 'Xiaomi/Redmi';
      case DeviceCategory.samsung:
        return 'Samsung';
      case DeviceCategory.google:
        return 'Google Pixel';
      case DeviceCategory.generic:
        return 'Android';
    }
  }

  /// Get device manufacturer (cached)
  String getManufacturer() {
    return _cachedDeviceInfo?.manufacturer ?? 'Unknown';
  }

  /// Get device model (cached)
  String getModel() {
    return _cachedDeviceInfo?.model ?? 'Unknown';
  }

  /// Get Android version (cached)
  int getAndroidVersion() {
    return _cachedDeviceInfo?.androidVersion ?? 0;
  }

  /// Clear cache (for testing or when device info needs to be refreshed)
  void clearCache() {
    debugPrint('🔄 Clearing DeviceInfoService cache');
    _cachedDeviceInfo = null;
    _cachedGoogleServicesAvailable = null;
    _cachedGoogleAppVersion = null;
  }

  // ===== Diagnostic Methods =====

  /// Get list of available speech recognition services
  /// Returns list of speech recognizers installed on the device
  Future<List<Map<String, String>>> getAvailableSpeechRecognizers() async {
    try {
      final result = await _channel.invokeMethod('getAvailableSpeechRecognizers');
      if (result is List) {
        return result.map((item) {
          if (item is Map) {
            return Map<String, String>.from(item.map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            ));
          }
          return <String, String>{};
        }).toList();
      }
      return [];
    } on PlatformException catch (e) {
      debugPrint('❌ Failed to get speech recognizers: ${e.message}');
      return [];
    }
  }

  /// Get detailed speech recognizer diagnostic information
  /// Returns comprehensive info about speech recognition setup
  Future<Map<String, dynamic>> getSpeechRecognizerDetails() async {
    try {
      final result = await _channel.invokeMethod('getSpeechRecognizerDetails');
      if (result is Map) {
        return Map<String, dynamic>.from(result);
      }
      return {};
    } on PlatformException catch (e) {
      debugPrint('❌ Failed to get speech recognizer details: ${e.message}');
      return {'error': e.message};
    }
  }

  /// Print comprehensive diagnostic information
  /// Useful for debugging speech recognition issues
  Future<void> printDiagnostics() async {
    debugPrint('═══════════════════════════════════════════════');
    debugPrint('📊 DEVICE & SPEECH RECOGNITION DIAGNOSTICS');
    debugPrint('═══════════════════════════════════════════════');

    // Device info
    debugPrint('📱 Device Information:');
    debugPrint('   Manufacturer: ${getManufacturer()}');
    debugPrint('   Model: ${getModel()}');
    debugPrint('   Category: ${getDeviceCategoryName()}');
    debugPrint('   Android Version: ${getAndroidVersion()}');
    debugPrint('   Is Chinese OEM: ${isChineseOEM()}');

    // Google Services
    debugPrint('');
    debugPrint('🔍 Google Services:');
    final hasGoogle = await isGoogleSpeechServicesAvailable();
    final googleVersion = await getGoogleAppVersion();
    debugPrint('   Google App Installed: $hasGoogle');
    debugPrint('   Google App Version: ${googleVersion ?? "Not installed"}');

    // Battery optimization
    debugPrint('');
    debugPrint('🔋 Battery Optimization:');
    final batteryOptimized = !(await isBatteryOptimizationIgnored());
    debugPrint('   Battery Optimized: $batteryOptimized');
    debugPrint('   (Should be false for speech to work)');

    // Speech recognizers
    debugPrint('');
    debugPrint('🎤 Speech Recognition Services:');
    final recognizers = await getAvailableSpeechRecognizers();
    if (recognizers.isEmpty) {
      debugPrint('   ❌ No speech recognizers found!');
    } else {
      debugPrint('   Found ${recognizers.length} service(s):');
      for (final recognizer in recognizers) {
        debugPrint('   - ${recognizer['appName']} (${recognizer['packageName']})');
      }
    }

    // Detailed speech info
    debugPrint('');
    debugPrint('📋 Speech Recognizer Details:');
    final details = await getSpeechRecognizerDetails();
    details.forEach((key, value) {
      debugPrint('   $key: $value');
    });

    debugPrint('═══════════════════════════════════════════════');
  }
}
