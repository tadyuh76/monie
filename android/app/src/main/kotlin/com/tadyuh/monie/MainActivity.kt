package com.tadyuh.monie

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val DEVICE_INFO_CHANNEL = "com.tadyuh.monie/device_info"
    private val VOICE_RECOGNITION_CHANNEL = "com.tadyuh.monie/voice_recognition"
    private var voiceRecognitionHandler: VoiceRecognitionChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Register DeviceInfoChannel for device detection and OEM-specific settings
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DEVICE_INFO_CHANNEL).setMethodCallHandler(
            DeviceInfoChannel(this)
        )

        // Register VoiceRecognitionChannel for direct speech recognition (Vivo workaround)
        voiceRecognitionHandler = VoiceRecognitionChannel(this)
        val voiceChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, VOICE_RECOGNITION_CHANNEL)
        voiceChannel.setMethodCallHandler(voiceRecognitionHandler)
        voiceRecognitionHandler?.setMethodChannel(voiceChannel)
    }

    override fun onDestroy() {
        voiceRecognitionHandler?.destroy()
        super.onDestroy()
    }
}
