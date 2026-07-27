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

    fun apply(context: Context, habitId: String, dayIndex: Int, delta: Int): Boolean {
        if (dayIndex !in 0..6) return false
        return synchronized(this) {
            try {
                val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                val root = JSONObject(prefs.getString(KEY, null) ?: return@synchronized false)
                val habits = root.optJSONArray("habits") ?: return@synchronized false
                for (i in 0 until habits.length()) {
                    val habit = habits.getJSONObject(i)
                    if (habit.optString("id") != habitId) continue
                    if (!mutate(habit, dayIndex, delta)) return@synchronized false
                    resummarize(root, habits)
                    prefs.edit().putString(KEY, root.toString()).commit()
                    return@synchronized true
                }
                false
            } catch (e: Exception) {
                false
            }
        }
    }

    private fun resummarize(root: JSONObject, habits: JSONArray) {
        val summary = root.optJSONObject("summary") ?: return
        var done = 0
        for (i in 0 until habits.length()) {
            val completions = habits.getJSONObject(i).optJSONArray("completions") ?: continue
            if (completions.length() > 6 && completions.optBoolean(6, false)) done++
        }
        summary.put("doneToday", done)
    }

    private fun mutate(habit: JSONObject, dayIndex: Int, delta: Int): Boolean {
        val completions = habit.optJSONArray("completions") ?: return false
        val counts = habit.optJSONArray("counts") ?: return false
        if (completions.length() <= dayIndex || counts.length() <= dayIndex) return false

        val kind = habit.optInt("kind", 0)
        val target = max(1, habit.optInt("perDayTarget", 1))
        val count = counts.optInt(dayIndex, 0)

        val newCount: Int
        val done: Boolean
        when (kind) {
            KIND_NEGATIVE -> {
                newCount = if (count > 0) 0 else 1
                done = newCount == 0
            }
            KIND_QUANTITATIVE -> {
                newCount = max(0, count + delta)
                done = newCount >= target
            }
            else -> {
                done = count < target
                newCount = if (done) target else 0
            }
        }

        counts.put(dayIndex, newCount)
        completions.put(dayIndex, done)
        putLevel(habit, dayIndex, CardBitmaps.levelFor(kind, newCount, target))
        return true
    }

    private fun putLevel(habit: JSONObject, dayIndex: Int, level: Int) {
        val heatmap: JSONArray = habit.optJSONArray("heatmap") ?: return
        var today = -1
        for (i in heatmap.length() - 1 downTo 0) {
            if (heatmap.optInt(i, -1) != -1) {
                today = i
                break
            }
        }
        if (today < 0) return
        val index = today - (6 - dayIndex)
        if (index in 0 until heatmap.length()) heatmap.put(index, level)
    }
}
