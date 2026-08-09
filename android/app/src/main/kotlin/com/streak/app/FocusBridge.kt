package com.streak.app

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject

object FocusBridge {

    const val CHANNEL = "streak/focus"

    private const val PREFS = "HomeWidgetPreferences"
    private const val KEY = "focus_actions"
    private const val MAX = 50

    private var channel: MethodChannel? = null

    fun attach(context: Context, methodChannel: MethodChannel) {
        channel = methodChannel
        methodChannel.setMethodCallHandler { call, result ->
            handle(context, call, result)
        }
    }

    fun detach(methodChannel: MethodChannel?) {
        if (channel === methodChannel) channel = null
    }

    private fun handle(context: Context, call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "show" -> {
                val arguments = call.arguments as? Map<String, Any?>
                if (arguments == null) {
                    result.success(false)
                    return
                }
                FocusService.show(context, FocusState.from(arguments))
                result.success(true)
            }
            "hide" -> {
                FocusService.hide(context)
                result.success(true)
            }
            "drain" -> result.success(drain(context))
            else -> result.notImplemented()
        }
    }

    fun enqueue(context: Context, kind: String) {
        synchronized(this) {
            val queue = read(context)
            if (queue.length() >= MAX) return
            queue.put(
                JSONObject()
                    .put("kind", kind)
                    .put("at", System.currentTimeMillis()),
            )
            write(context, queue)
        }
        notifyDart()
    }

    private fun drain(context: Context): List<Map<String, Any>> = synchronized(this) {
        val queue = read(context)
        write(context, JSONArray())
        (0 until queue.length()).map { index ->
            val entry = queue.getJSONObject(index)
            mapOf("kind" to entry.optString("kind"), "at" to entry.optLong("at"))
        }
    }

    private fun notifyDart() {
        val target = channel ?: return
        Handler(Looper.getMainLooper()).post { target.invokeMethod("pending", null) }
    }

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private fun read(context: Context): JSONArray = try {
        val raw = prefs(context).getString(KEY, null)
        if (raw.isNullOrEmpty()) JSONArray() else JSONArray(raw)
    } catch (e: Exception) {
        JSONArray()
    }

    private fun write(context: Context, queue: JSONArray) {
        prefs(context).edit().putString(KEY, queue.toString()).commit()
    }
}
