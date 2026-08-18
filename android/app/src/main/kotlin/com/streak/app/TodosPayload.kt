package com.streak.app

import android.content.Context
import java.time.LocalDate
import org.json.JSONArray
import org.json.JSONObject

object TodosPayload {

    private const val PREFS = "HomeWidgetPreferences"
    private const val KEY = "todos_data"

    fun todayEpochDay(): Long = LocalDate.now().toEpochDay()

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun raw(context: Context): JSONObject? = try {
        val json = prefs(context).getString(KEY, null)
        if (json.isNullOrEmpty()) null else JSONObject(json)
    } catch (e: Exception) {
        null
    }

    fun due(context: Context, all: Boolean): List<JSONObject> {
        val todos = raw(context)?.optJSONArray("todos") ?: return emptyList()
        val today = todayEpochDay()
        val out = mutableListOf<JSONObject>()
        for (i in 0 until todos.length()) {
            val todo = todos.optJSONObject(i) ?: continue
            val day = todo.optLong("day", -1L)
            val done = todo.optBoolean("done", false)
            if (all || done || day < 0L || day <= today) out.add(todo)
        }
        return out
    }

    fun toggleDone(context: Context, id: String): Boolean {
        synchronized(this) {
            val root = raw(context) ?: return false
            val todos = root.optJSONArray("todos") ?: return false
            val kept = JSONArray()
            var flipped = false
            for (i in 0 until todos.length()) {
                val todo = todos.optJSONObject(i) ?: continue
                if (!flipped && todo.optString("id") == id) {
                    flipped = true
                    todo.put("done", !todo.optBoolean("done", false))
                }
                kept.put(todo)
            }
            if (!flipped) return false
            root.put("todos", kept)
            prefs(context).edit().putString(KEY, root.toString()).commit()
            return true
        }
    }
}
