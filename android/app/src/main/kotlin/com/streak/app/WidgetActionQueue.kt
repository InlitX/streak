package com.streak.app

import android.content.Context
import org.json.JSONArray

object WidgetActionQueue {

    private const val PREFS = "HomeWidgetPreferences"
    private const val KEY = "pending_actions"
    private const val MAX = 200

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun push(context: Context, uri: String) {
        synchronized(this) {
            val queue = read(context)
            if (queue.length() >= MAX) return
            queue.put(uri)
            prefs(context).edit().putString(KEY, queue.toString()).commit()
        }
    }

    fun isEmpty(context: Context): Boolean = read(context).length() == 0

    private fun read(context: Context): JSONArray = try {
        val raw = prefs(context).getString(KEY, null)
        if (raw.isNullOrEmpty()) JSONArray() else JSONArray(raw)
    } catch (e: Exception) {
        JSONArray()
    }
}
