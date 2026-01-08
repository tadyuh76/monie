package com.tadyuh.monie

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.util.Log
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * Direct Android SpeechRecognizer implementation for Vivo devices
 * Bypasses speech_to_text plugin which fails on some OEM devices
 */
class VoiceRecognitionChannel(private val context: Context) : MethodCallHandler, RecognitionListener {
    companion object {
        private const val TAG = "VoiceRecognitionChannel"
        private const val CHANNEL_NAME = "com.tadyuh.monie/voice_recognition"
    }

    private var speechRecognizer: SpeechRecognizer? = null
    private var resultCallback: MethodChannel? = null
    private var isListening = false

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "checkAvailability" -> {
                result.success(checkSpeechRecognitionAvailability())
            }
            "startListening" -> {
                val localeId = call.argument<String>("localeId") ?: "vi_VN"
                startListening(localeId, result)
            }
            "stopListening" -> {
                stopListening()
                result.success(null)
            }
            "cancelListening" -> {
                cancelListening()
                result.success(null)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    /**
     * Check if speech recognition is available
     * Note: On some Vivo devices, isRecognitionAvailable() returns false even though
     * we can create a SpeechRecognizer. We prioritize the ability to create a recognizer.
     */
    private fun checkSpeechRecognitionAvailability(): Map<String, Any> {
        val details = mutableMapOf<String, Any>()

        try {
            // Check microphone permission
            val hasMicPermission = ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.RECORD_AUDIO
            ) == PackageManager.PERMISSION_GRANTED
            details["hasMicrophonePermission"] = hasMicPermission

            // Check if speech recognizer is available (may return false on Vivo)
            val recognitionAvailable = SpeechRecognizer.isRecognitionAvailable(context)
            details["recognitionAvailable"] = recognitionAvailable

            // Try to create speech recognizer - this is the real test
            var canCreate = false
            try {
                val testRecognizer = SpeechRecognizer.createSpeechRecognizer(context)
                canCreate = testRecognizer != null
                testRecognizer?.destroy()
                details["canCreateRecognizer"] = canCreate
                Log.d(TAG, "✅ Successfully created SpeechRecognizer")
            } catch (e: Exception) {
                details["canCreateRecognizer"] = false
                details["createError"] = e.message ?: "Unknown error"
                Log.e(TAG, "❌ Failed to create SpeechRecognizer", e)
            }

            // On Vivo devices, isRecognitionAvailable() may lie - trust canCreateRecognizer
            val actuallyAvailable = hasMicPermission && canCreate
            details["isAvailable"] = actuallyAvailable

            if (actuallyAvailable) {
                Log.d(TAG, "✅ Speech recognition is available (can create recognizer)")
            } else {
                Log.w(TAG, "⚠️ Speech recognition not available - hasMic: $hasMicPermission, canCreate: $canCreate")
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error checking availability", e)
            details["error"] = e.message ?: "Unknown error"
            details["isAvailable"] = false
        }

        return details
    }

    /**
     * Start listening for speech input
     */
    private fun startListening(localeId: String, result: Result) {
        // Check microphone permission
        if (ContextCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO)
            != PackageManager.PERMISSION_GRANTED) {
            result.error("PERMISSION_DENIED", "Microphone permission not granted", null)
            return
        }

        try {
            // If already listening, cancel and wait for completion
            if (isListening) {
                Log.w(TAG, "⚠️ Already listening, canceling previous session...")
                speechRecognizer?.cancel()
                // Wait briefly to ensure cancellation completes
                Thread.sleep(100)
                isListening = false
            }

            // Destroy and recreate speech recognizer to ensure clean state
            speechRecognizer?.destroy()
            speechRecognizer = SpeechRecognizer.createSpeechRecognizer(context)

            if (speechRecognizer == null) {
                Log.e(TAG, "❌ Failed to create SpeechRecognizer")
                result.error("CREATE_ERROR", "Failed to create speech recognizer", null)
                return
            }

            speechRecognizer?.setRecognitionListener(this)

            // Create recognition intent
            val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                putExtra(RecognizerIntent.EXTRA_LANGUAGE, localeId)
                putExtra(RecognizerIntent.EXTRA_LANGUAGE_PREFERENCE, localeId)
                putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
                putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
                putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS, 3000)
                putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_POSSIBLY_COMPLETE_SILENCE_LENGTH_MILLIS, 2000)
            }

            // Start recognition
            speechRecognizer?.startListening(intent)
            isListening = true
            Log.d(TAG, "🎤 Started listening (locale: $localeId)")
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error starting speech recognition", e)
            isListening = false
            result.error("START_ERROR", e.message ?: "Failed to start recognition", null)
        }
    }

    /**
     * Stop listening
     */
    private fun stopListening() {
        Log.d(TAG, "⏹️ Stopping speech recognition")
        speechRecognizer?.stopListening()
        isListening = false
    }

    /**
     * Cancel listening
     */
    private fun cancelListening() {
        Log.d(TAG, "❌ Cancelling speech recognition")
        speechRecognizer?.cancel()
        isListening = false
    }

    /**
     * Destroy speech recognizer
     */
    fun destroy() {
        speechRecognizer?.destroy()
        speechRecognizer = null
        isListening = false
    }

    // ===== RecognitionListener Implementation =====

    override fun onReadyForSpeech(params: Bundle?) {
        Log.d(TAG, "✅ Ready for speech")
        resultCallback?.invokeMethod("onStatus", mapOf("status" to "ready"))
    }

    override fun onBeginningOfSpeech() {
        Log.d(TAG, "🎤 Speech started")
        resultCallback?.invokeMethod("onStatus", mapOf("status" to "speaking"))
    }

    override fun onRmsChanged(rmsdB: Float) {
        // Sound level changed (can be used for visual feedback)
    }

    override fun onBufferReceived(buffer: ByteArray?) {
        // Audio buffer received
    }

    override fun onEndOfSpeech() {
        Log.d(TAG, "⏹️ Speech ended")
        isListening = false
        resultCallback?.invokeMethod("onStatus", mapOf("status" to "done"))
    }

    override fun onError(error: Int) {
        val errorMessage = when (error) {
            SpeechRecognizer.ERROR_AUDIO -> "Audio recording error"
            SpeechRecognizer.ERROR_CLIENT -> "Speech service disconnected. Please try again."
            SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "Microphone permission denied"
            SpeechRecognizer.ERROR_NETWORK -> "Network error - check internet connection"
            SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> "Network timeout"
            SpeechRecognizer.ERROR_NO_MATCH -> "Could not understand speech. Please speak clearly."
            SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> "Speech service is busy. Try again in a moment."
            SpeechRecognizer.ERROR_SERVER -> "Speech server error"
            SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "No speech detected. Please speak into the microphone."
            else -> "Speech recognition error (code: $error)"
        }

        Log.e(TAG, "❌ Recognition error: $errorMessage (code: $error)")

        // Always mark as not listening to allow retries
        isListening = false

        // ERROR_CLIENT is a known false positive on Vivo - ignore it completely
        // Continue waiting for onResults or other callbacks
        if (error == SpeechRecognizer.ERROR_CLIENT) {
            Log.w(TAG, "⚠️ Ignoring ERROR_CLIENT - false positive on Vivo. Waiting for results...")
            // Don't send error to Flutter, don't notify user
            // Recognition may still complete successfully via onResults
            return
        }

        // For real errors, notify Flutter and cleanup
        resultCallback?.invokeMethod("onError", mapOf(
            "error" to errorMessage,
            "errorCode" to error
        ))
    }

    override fun onResults(results: Bundle?) {
        val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
        if (matches != null && matches.isNotEmpty()) {
            val recognizedText = matches[0]
            Log.d(TAG, "✅ Recognition result: $recognizedText")

            // Notify Flutter immediately
            resultCallback?.invokeMethod("onResult", mapOf(
                "text" to recognizedText,
                "isFinal" to true
            ))

            // Set isListening to false AFTER notifying Flutter
            // Small delay to ensure message is sent
            android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                isListening = false
                Log.d(TAG, "✅ Recognition session ended")
            }, 50)
        }
    }

    override fun onPartialResults(partialResults: Bundle?) {
        val matches = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
        if (matches != null && matches.isNotEmpty()) {
            val recognizedText = matches[0]
            Log.d(TAG, "📝 Partial result: $recognizedText")
            resultCallback?.invokeMethod("onResult", mapOf(
                "text" to recognizedText,
                "isFinal" to false
            ))
        }
    }

    override fun onEvent(eventType: Int, params: Bundle?) {
        // Additional events
    }

    /**
     * Set the method channel for sending results back to Flutter
     */
    fun setMethodChannel(channel: MethodChannel) {
        this.resultCallback = channel
    }
}
