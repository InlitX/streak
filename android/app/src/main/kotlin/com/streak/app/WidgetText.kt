package com.streak.app

import android.content.Context
import org.json.JSONObject

object WidgetText {
    private fun strings(context: Context): JSONObject? = try {
        context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
            .getString("widget_strings", null)?.let { JSONObject(it) }
    } catch (e: Exception) {
        null
    }

    fun get(context: Context, key: String, fallback: String): String {
        val value = strings(context)?.optString(key, "") ?: ""
        return if (value.isEmpty()) fallback else value
    }

    fun compact(value: Int): String = when {
        value < 1000 -> value.toString()
        value < 10000 -> {
            val tenths = (value + 50) / 100
            if (tenths % 10 == 0) "${tenths / 10}k" else "${tenths / 10}.${tenths % 10}k"
        }
        value < 1000000 -> "${(value + 500) / 1000}k"
        else -> "${(value + 500000) / 1000000}M"
    }

    fun format(
        context: Context,
        key: String,
        fallback: String,
        vararg subs: Pair<String, String>,
    ): String {
        var result = get(context, key, fallback)
        for ((token, value) in subs) result = result.replace(token, value)
        return result
    }
}
