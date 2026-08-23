package com.streak.app

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import kotlin.math.max

object WidgetOptimistic {

    private const val PREFS = "HomeWidgetPreferences"
    private const val KEY = "habits_data"
    private const val KIND_NEGATIVE = 1
    private const val KIND_QUANTITATIVE = 2

    fun apply(context: Context, habitId: String, dayKey: String, delta: Double): Boolean {
        return synchronized(this) {
            try {
                val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                val root = JSONObject(prefs.getString(KEY, null) ?: return@synchronized false)
                val todayKey = WidgetPayload.todayKey(context)
                val day = indexOf(root, dayKey, todayKey)
                val today = indexOf(root, todayKey, todayKey)
                if (day < 0) return@synchronized false
                val habits = root.optJSONArray("habits") ?: return@synchronized false
                for (i in 0 until habits.length()) {
                    val habit = habits.optJSONObject(i) ?: continue
                    if (habit.optString("id") != habitId) continue
                    if (!mutate(habit, day, today, delta)) return@synchronized false
                    resummarize(root, habits, today)
                    prefs.edit().putString(KEY, root.toString()).commit()
                    return@synchronized true
                }
                false
            } catch (e: Exception) {
                false
            }
        }
    }

    private fun indexOf(root: JSONObject, dayKey: String, todayKey: String): Int {
        val days = root.optJSONArray("days") ?: return -1
        if (days.length() > 0 && days.optJSONObject(0)?.has("key") != true) {
            return if (dayKey == todayKey) WidgetPayload.TODAY else -1
        }
        return WidgetPayload.windowIndexOf(root, dayKey)
    }

    private fun resummarize(root: JSONObject, habits: JSONArray, today: Int) {
        val summary = root.optJSONObject("summary") ?: return
        if (today < 0) return
        var done = 0
        for (i in 0 until habits.length()) {
            val habit = habits.optJSONObject(i) ?: continue
            val scheduled = habit.optJSONArray("scheduled")
            if (scheduled != null && !scheduled.optBoolean(today, false)) continue
            val completions = habit.optJSONArray("completions") ?: continue
            if (completions.length() > today && completions.optBoolean(today, false)) done++
        }
        summary.put("doneToday", done)
    }

    private fun mutate(habit: JSONObject, day: Int, today: Int, delta: Double): Boolean {
        val completions = habit.optJSONArray("completions") ?: return false
        val counts = habit.optJSONArray("counts") ?: return false
        if (completions.length() <= day || counts.length() <= day) return false

        val kind = habit.optInt("kind", 0)
        val target = max(1.0, habit.optDouble("perDayTarget", 1.0))
        val count = counts.optDouble(day, 0.0)

        val newCount: Double
        val done: Boolean
        when (kind) {
            KIND_NEGATIVE -> {
                newCount = if (count > 0) 0.0 else 1.0
                done = newCount == 0.0
            }
            KIND_QUANTITATIVE -> {
                newCount = max(0.0, count + delta)
                done = newCount >= target
            }
            else -> {
                done = count < target
                newCount = if (done) target else 0.0
            }
        }

        counts.put(day, newCount)
        completions.put(day, done)
        putLevel(habit, day, today, CardBitmaps.levelFor(kind, newCount, target))
        return true
    }

    private fun putLevel(habit: JSONObject, day: Int, today: Int, level: Int) {
        if (today < 0) return
        val heatmap: JSONArray = habit.optJSONArray("heatmap") ?: return
        var last = -1
        for (i in heatmap.length() - 1 downTo 0) {
            if (heatmap.optInt(i, -1) != -1) {
                last = i
                break
            }
        }
        if (last < 0) return
        val index = last - (today - day)
        if (index in 0 until heatmap.length()) heatmap.put(index, level)
    }
}
