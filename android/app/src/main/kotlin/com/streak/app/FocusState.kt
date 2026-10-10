package com.streak.app

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

object FocusState {

    private const val PREFS = "HomeWidgetPreferences"
    private const val KEY = "focus_session"

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun save(context: Context, state: JSONObject) {
        prefs(context).edit().putString(KEY, state.toString()).commit()
    }

    fun read(context: Context): JSONObject? = try {
        val raw = prefs(context).getString(KEY, null)
        if (raw.isNullOrEmpty()) null else JSONObject(raw)
    } catch (e: Exception) {
        null
    }

    fun clear(context: Context) {
        prefs(context).edit().remove(KEY).commit()
    }

    fun from(arguments: Map<String, Any?>): JSONObject {
        val running = arguments["running"] as? Boolean ?: false
        val countDown = arguments["countDown"] as? Boolean ?: true
        val seconds = (arguments["seconds"] as? Number)?.toInt() ?: 0
        val state = JSONObject()
        state.put("habitId", arguments["habitId"] as? String ?: "")
        state.put("title", arguments["title"] as? String ?: "")
        state.put("state", arguments["state"] as? String ?: "")
        state.put("channelName", arguments["channelName"] as? String ?: "")
        state.put("pauseLabel", arguments["pauseLabel"] as? String ?: "")
        state.put("resumeLabel", arguments["resumeLabel"] as? String ?: "")
        state.put("stopLabel", arguments["stopLabel"] as? String ?: "")
        state.put("skipLabel", arguments["skipLabel"] as? String ?: "")
        state.put("continueLabel", arguments["continueLabel"] as? String ?: "")
        state.put("minuteLabel", arguments["minuteLabel"] as? String ?: "")
        state.put("endTitle", arguments["endTitle"] as? String ?: "")
        state.put("endBody", arguments["endBody"] as? String ?: "")
        state.put("total", (arguments["total"] as? Number)?.toInt() ?: 0)
        state.put("phase", arguments["phase"] as? String ?: "")
        state.put("running", running)
        state.put("done", arguments["done"] as? Boolean ?: false)
        state.put("countDown", countDown)
        state.put("hold", arguments["hold"] as? Boolean ?: false)
        state.put("upcoming", JSONArray().apply {
            (arguments["upcoming"] as? List<*>)?.forEach { phase ->
                (phase as? Map<*, *>)?.let { put(JSONObject(it)) }
            }
        })
        state.put("frozen", seconds)
        val sent = (arguments["anchor"] as? Number)?.toLong() ?: 0L
        state.put("anchor", if (sent > 0L) sent else anchorFor(countDown, seconds))
        return state
    }

    fun seconds(state: JSONObject): Int {
        if (!state.optBoolean("running")) return state.optInt("frozen")
        val anchor = state.optLong("anchor")
        val now = System.currentTimeMillis()
        val delta = if (state.optBoolean("countDown")) anchor - now else now - anchor
        return (delta / 1000L).coerceAtLeast(0L).toInt()
    }

    fun paused(state: JSONObject): JSONObject {
        val frozen = seconds(state)
        return copyOf(state).put("running", false).put("frozen", frozen)
    }

    fun resumed(state: JSONObject): JSONObject {
        val frozen = state.optInt("frozen")
        return copyOf(state)
            .put("running", true)
            .put("anchor", anchorFor(state.optBoolean("countDown"), frozen))
    }

    fun extended(state: JSONObject): JSONObject {
        if (!state.optBoolean("countDown")) return state
        val next = copyOf(state)
            .put("total", state.optInt("total") + 60)
            .put("done", false)
        return if (state.optBoolean("running")) {
            next.put("anchor", maxOf(state.optLong("anchor"), System.currentTimeMillis()) + 60_000L)
        } else {
            next.put("frozen", state.optInt("frozen") + 60)
        }
    }

    fun advanced(state: JSONObject): JSONObject? {
        val upcoming = state.optJSONArray("upcoming") ?: return null
        val next = upcoming.optJSONObject(0) ?: return null
        val rest = JSONArray()
        for (index in 1 until upcoming.length()) rest.put(upcoming.get(index))
        val total = next.optInt("total")
        return copyOf(state)
            .put("total", total)
            .put("state", next.optString("state"))
            .put("phase", next.optString("phase"))
            .put("hold", next.optBoolean("hold"))
            .put("endTitle", next.optString("endTitle"))
            .put("endBody", next.optString("endBody"))
            .put("running", true)
            .put("done", false)
            .put("frozen", total)
            .put("anchor", System.currentTimeMillis() + total * 1000L + 999L)
            .put("upcoming", rest)
    }

    private fun anchorFor(countDown: Boolean, seconds: Int): Long {
        val now = System.currentTimeMillis()
        val offset = seconds * 1000L
        return if (countDown) now + offset else now - offset
    }

    private fun copyOf(state: JSONObject): JSONObject = JSONObject(state.toString())
}
