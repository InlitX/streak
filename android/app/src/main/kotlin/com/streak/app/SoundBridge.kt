package com.streak.app

import android.content.ContentUris
import android.content.Context
import android.media.AudioAttributes
import android.media.Ringtone
import android.media.RingtoneManager
import android.net.Uri
import android.provider.MediaStore
import io.flutter.plugin.common.MethodChannel

object SoundBridge {
    const val CHANNEL = "streak/sounds"
    private var playing: Ringtone? = null

    fun attach(context: Context, channel: MethodChannel) {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "list" -> result.success(list(context))
                "play" -> {
                    play(context, call.argument<String>("uri"))
                    result.success(true)
                }
                "stop" -> {
                    stop()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    fun detach() = stop()

    private fun list(context: Context): List<Map<String, String>> {
        val base = MediaStore.Audio.Media.INTERNAL_CONTENT_URI
        val sounds = mutableListOf<Map<String, String>>()
        try {
            context.contentResolver.query(
                base,
                arrayOf(MediaStore.Audio.Media._ID, MediaStore.Audio.Media.TITLE),
                "${MediaStore.Audio.Media.IS_NOTIFICATION} != 0",
                null,
                "${MediaStore.Audio.Media.TITLE} COLLATE NOCASE",
            )?.use { cursor ->
                while (cursor.moveToNext()) {
                    val title = cursor.getString(1) ?: continue
                    val uri = ContentUris.withAppendedId(base, cursor.getLong(0))
                    sounds += mapOf("title" to title, "uri" to uri.toString())
                }
            }
        } catch (_: Exception) {
        }
        return sounds.distinctBy { it["title"] }
    }

    private fun play(context: Context, uri: String?) {
        stop()
        val target = if (uri.isNullOrEmpty()) {
            RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
        } else {
            Uri.parse(uri)
        }
        playing = try {
            RingtoneManager.getRingtone(context, target)?.apply {
                audioAttributes = AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build()
                play()
            }
        } catch (_: Exception) {
            null
        }
    }

    private fun stop() {
        try {
            playing?.stop()
        } catch (_: Exception) {
        }
        playing = null
    }
}
