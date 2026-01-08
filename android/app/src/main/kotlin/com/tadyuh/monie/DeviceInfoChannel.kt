package com.tadyuh.monie

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * Platform channel for device-specific information and permissions
 * Handles device detection, Google Services checks, and OEM-specific settings
 */
class DeviceInfoChannel(private val context: Context) : MethodCallHandler {
    companion object {
        private const val TAG = "DeviceInfoChannel"
        private const val CHANNEL_NAME = "com.tadyuh.monie/device_info"

        // Package names for Google Services
        private const val GOOGLE_APP_PACKAGE = "com.google.android.googlequicksearchbox"
        private const val GOOGLE_PLAY_SERVICES_PACKAGE = "com.google.android.gms"

        // OEM-specific component names for settings
        // Vivo
        private const val VIVO_AUTO_START_COMPONENT = "com.vivo.permissionmanager/.activity.PurviewTabActivity"
        private const val VIVO_PERMISSION_MANAGER = "com.vivo.permissionmanager"

        // Oppo/Realme
        private const val OPPO_AUTO_START_COMPONENT = "com.coloros.safecenter/.startupapp.StartupAppListActivity"
        private const val OPPO_BATTERY_COMPONENT = "com.coloros.safecenter/.permission.PermissionManagerActivity"
        private const val OPPO_SAFE_CENTER = "com.coloros.safecenter"

        // Xiaomi
        private const val XIAOMI_AUTO_START_COMPONENT = "com.miui.securitycenter/.permission.AutoStartManagementActivity"
        private const val XIAOMI_SECURITY_CENTER = "com.miui.securitycenter"
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getDeviceInfo" -> {
                result.success(getDeviceInfo())
            }
            "isGoogleSpeechServicesAvailable" -> {
                result.success(isGoogleSpeechServicesAvailable())
            }
            "getGoogleAppVersion" -> {
                result.success(getGoogleAppVersion())
            }
            "isBatteryOptimizationIgnored" -> {
                result.success(isBatteryOptimizationIgnored())
            }
            "openBatteryOptimizationSettings" -> {
                openBatteryOptimizationSettings()
                result.success(null)
            }
            "openAutoStartSettings" -> {
                openAutoStartSettings()
                result.success(null)
            }
            "openManufacturerPermissionSettings" -> {
                openManufacturerPermissionSettings()
                result.success(null)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    /**
     * Get device information including manufacturer, model, and Android version
     */
    private fun getDeviceInfo(): Map<String, Any> {
        return mapOf(
            "manufacturer" to Build.MANUFACTURER,
            "model" to Build.MODEL,
            "androidVersion" to Build.VERSION.SDK_INT,
            "androidVersionRelease" to Build.VERSION.RELEASE
        )
    }

    /**
     * Check if Google Speech Services (Google app) is installed
     * This is required for speech recognition to work
     */
    private fun isGoogleSpeechServicesAvailable(): Boolean {
        return try {
            val packageManager = context.packageManager

            // Check for Google app (contains speech recognition)
            val googleAppInfo = try {
                packageManager.getPackageInfo(GOOGLE_APP_PACKAGE, 0)
                true
            } catch (e: PackageManager.NameNotFoundException) {
                Log.w(TAG, "📱 Google app not found")
                false
            }

            // Also check for Google Play Services (optional but recommended)
            val playServicesInfo = try {
                packageManager.getPackageInfo(GOOGLE_PLAY_SERVICES_PACKAGE, 0)
                true
            } catch (e: PackageManager.NameNotFoundException) {
                Log.w(TAG, "⚠️ Google Play Services not found (optional)")
                true // Don't fail if Play Services is missing, Google app is sufficient
            }

            val isAvailable = googleAppInfo && playServicesInfo
            Log.d(TAG, "✅ Google Speech Services available: $isAvailable")
            isAvailable
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error checking Google Speech Services", e)
            false
        }
    }

    /**
     * Get Google app version string
     * Returns null if Google app is not installed
     */
    private fun getGoogleAppVersion(): String? {
        return try {
            val packageManager = context.packageManager
            val packageInfo = packageManager.getPackageInfo(GOOGLE_APP_PACKAGE, 0)
            val version = packageInfo.versionName
            Log.d(TAG, "📱 Google app version: $version")
            version
        } catch (e: PackageManager.NameNotFoundException) {
            Log.w(TAG, "❌ Google app not installed")
            null
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error getting Google app version", e)
            null
        }
    }

    /**
     * Check if the app is exempted from battery optimization
     * Returns true if battery optimization is ignored (good for background services)
     */
    private fun isBatteryOptimizationIgnored(): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
                val packageName = context.packageName
                val isIgnoring = powerManager.isIgnoringBatteryOptimizations(packageName)
                Log.d(TAG, "🔋 Battery optimization ignored: $isIgnoring")
                isIgnoring
            } else {
                // Battery optimization doesn't exist before Android M
                true
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error checking battery optimization", e)
            false
        }
    }

    /**
     * Open battery optimization settings
     * Allows user to exempt the app from battery optimization
     */
    private fun openBatteryOptimizationSettings() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                    data = Uri.parse("package:${context.packageName}")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                context.startActivity(intent)
                Log.d(TAG, "🔧 Opened battery optimization settings")
            } else {
                Log.w(TAG, "⚠️ Battery optimization settings not available on this Android version")
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error opening battery optimization settings", e)
            // Fallback to general app settings
            openAppSettings()
        }
    }

    /**
     * Open auto-start settings based on device manufacturer
     * Each OEM has different settings screens
     */
    private fun openAutoStartSettings() {
        try {
            val manufacturer = Build.MANUFACTURER.lowercase()
            Log.d(TAG, "🔧 Opening auto-start settings for: $manufacturer")

            val intent = when (manufacturer) {
                "vivo" -> {
                    // Vivo auto-start settings
                    Intent().apply {
                        component = ComponentName.unflattenFromString(VIVO_AUTO_START_COMPONENT)
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    }
                }
                "oppo", "realme" -> {
                    // Oppo/Realme auto-start settings
                    Intent().apply {
                        component = ComponentName.unflattenFromString(OPPO_AUTO_START_COMPONENT)
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    }
                }
                "xiaomi", "redmi", "poco" -> {
                    // Xiaomi auto-start settings
                    Intent().apply {
                        component = ComponentName.unflattenFromString(XIAOMI_AUTO_START_COMPONENT)
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    }
                }
                else -> {
                    // Generic fallback - open app settings
                    Log.w(TAG, "⚠️ Unknown manufacturer, opening general app settings")
                    null
                }
            }

            if (intent != null) {
                try {
                    context.startActivity(intent)
                    Log.d(TAG, "✅ Opened OEM-specific auto-start settings")
                } catch (e: Exception) {
                    Log.w(TAG, "⚠️ OEM-specific settings not available, falling back", e)
                    openAppSettings()
                }
            } else {
                openAppSettings()
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error opening auto-start settings", e)
            openAppSettings()
        }
    }

    /**
     * Open manufacturer-specific permission settings
     * Some OEMs have custom permission management screens
     */
    private fun openManufacturerPermissionSettings() {
        try {
            val manufacturer = Build.MANUFACTURER.lowercase()
            Log.d(TAG, "🔧 Opening manufacturer permission settings for: $manufacturer")

            val intent = when (manufacturer) {
                "vivo" -> {
                    Intent().apply {
                        component = ComponentName(VIVO_PERMISSION_MANAGER,
                            "$VIVO_PERMISSION_MANAGER.activity.SoftPermissionDetailActivity")
                        putExtra("packagename", context.packageName)
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    }
                }
                "oppo", "realme" -> {
                    Intent().apply {
                        component = ComponentName.unflattenFromString(OPPO_BATTERY_COMPONENT)
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    }
                }
                else -> null
            }

            if (intent != null) {
                try {
                    context.startActivity(intent)
                    Log.d(TAG, "✅ Opened OEM-specific permission settings")
                } catch (e: Exception) {
                    Log.w(TAG, "⚠️ OEM-specific settings not available, falling back", e)
                    openAppSettings()
                }
            } else {
                openAppSettings()
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error opening manufacturer permission settings", e)
            openAppSettings()
        }
    }

    /**
     * Fallback: Open general app settings
     */
    private fun openAppSettings() {
        try {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.parse("package:${context.packageName}")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            context.startActivity(intent)
            Log.d(TAG, "✅ Opened general app settings")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error opening app settings", e)
        }
    }
}
