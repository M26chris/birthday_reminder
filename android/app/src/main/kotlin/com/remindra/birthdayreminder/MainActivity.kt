package com.remindra.birthdayreminder

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.ActivityNotFoundException
import android.content.Intent
import android.database.Cursor
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import android.provider.OpenableColumns
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val requestAudioFile = 7301
    private var pendingAudioResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "app.remindra/birthday_sound"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickAudio" -> pickAudio(result)
                "createSoundChannel" -> createSoundChannel(call.arguments, result)
                else -> result.notImplemented()
            }
        }
    }

    private fun pickAudio(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            result.error(
                "custom-sound-unavailable",
                "Custom notification sounds require Android 8.0 or newer.",
                null
            )
            return
        }
        if (pendingAudioResult != null) {
            result.error("picker-active", "An audio picker is already open.", null)
            return
        }

        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "audio/*"
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
        }
        try {
            pendingAudioResult = result
            startActivityForResult(intent, requestAudioFile)
        } catch (error: ActivityNotFoundException) {
            pendingAudioResult = null
            result.error("picker-unavailable", "No audio file picker is available.", error.message)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != requestAudioFile) return

        val result = pendingAudioResult ?: return
        pendingAudioResult = null
        if (resultCode != RESULT_OK || data?.data == null) {
            result.success(null)
            return
        }

        val uri = data.data!!
        try {
            val grantedFlags = data.flags and Intent.FLAG_GRANT_READ_URI_PERMISSION
            contentResolver.takePersistableUriPermission(uri, grantedFlags)
            val name = contentResolver.query(
                uri,
                arrayOf(OpenableColumns.DISPLAY_NAME),
                null,
                null,
                null
            )?.use { cursor: Cursor ->
                if (cursor.moveToFirst()) {
                    cursor.getString(cursor.getColumnIndexOrThrow(OpenableColumns.DISPLAY_NAME))
                } else {
                    null
                }
            } ?: uri.lastPathSegment ?: "Selected audio"
            result.success(mapOf("uri" to uri.toString(), "name" to name))
        } catch (error: Exception) {
            result.error("audio-access-failed", "Could not keep access to the selected audio file.", error.message)
        }
    }

    private fun createSoundChannel(arguments: Any?, result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            result.success(false)
            return
        }
        try {
            @Suppress("UNCHECKED_CAST")
            val values = arguments as? Map<String, String>
                ?: throw IllegalArgumentException("Missing notification sound settings.")
            val channelId = values["channelId"]
                ?: throw IllegalArgumentException("Missing notification channel ID.")
            val name = values["name"] ?: "Birthday reminder sound"
            val description = values["description"] ?: "Custom birthday reminder sound"
            val soundUri = Uri.parse(
                values["uri"] ?: throw IllegalArgumentException("Missing audio URI.")
            )

            val notificationManager = getSystemService(NotificationManager::class.java)
            val channel = NotificationChannel(
                channelId,
                name,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                this.description = description
                enableVibration(true)
                setSound(
                    soundUri,
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
            }
            grantUriPermission(
                "com.android.systemui",
                soundUri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION
            )
            notificationManager.createNotificationChannel(channel)
            result.success(true)
        } catch (error: Exception) {
            result.error("channel-creation-failed", "Could not configure the birthday sound.", error.message)
        }
    }
}
