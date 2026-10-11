package com.streak.app

import android.content.Context
import java.util.Calendar
import java.util.Locale
import org.json.JSONArray
import org.json.JSONObject

object WidgetPayload {

    const val WEEK = 7
    const val TODAY = WEEK - 1
    const val EARLIER = 2
    private const val SPAN = WEEK + TODAY

    fun todayKey(context: Context): String =
        raw(context)?.optString("todayKey").orEmpty().ifEmpty { systemDayKey() }

    fun dayCutoff(context: Context): Int =
        (raw(context)?.optInt("dayCutoff", 0) ?: 0).coerceIn(0, 6)

    fun systemDayKey(cutoff: Int = 0): String {
        val now = Calendar.getInstance().apply { add(Calendar.HOUR_OF_DAY, -cutoff) }
        return String.format(
            Locale.US,
            "%02d-%02d-%04d",
            now.get(Calendar.DAY_OF_MONTH),
            now.get(Calendar.MONTH) + 1,
            now.get(Calendar.YEAR),
        )
    }

    fun raw(context: Context): JSONObject? = try {
        val json = context
            .getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
            .getString("habits_data", null)
        if (json.isNullOrEmpty()) null else JSONObject(json)
    } catch (e: Exception) {
        null
    }

    fun aligned(context: Context): JSONObject? = raw(context)?.let { align(it, todayKey(context)) }

    fun forWidget(context: Context, appWidgetId: Int): JSONObject? {
        val root = aligned(context) ?: return null
        val chosen = WidgetConfig.habits(context, appWidgetId)
        val all = root.optJSONArray("habits") ?: return root
        if (chosen.isEmpty()) return root
        val kept = JSONArray()
        for (i in 0 until all.length()) {
            val habit = all.optJSONObject(i) ?: continue
            if (habit.optString("id") in chosen) kept.put(habit)
        }
        if (kept.length() == 0) return root
        root.put("habits", kept)
        root.put("summary", summaryOf(kept, todayIndex(root)))
        return root
    }

    fun single(context: Context, appWidgetId: Int, root: JSONObject?): JSONObject? {
        if (WidgetConfig.habits(context, appWidgetId).isEmpty()) return null
        val habits = root?.optJSONArray("habits") ?: return null
        return if (habits.length() == 1) habits.optJSONObject(0) else null
    }

    private fun todayIndex(root: JSONObject): Int {
        val days = root.optJSONArray("days") ?: return TODAY
        for (i in 0 until days.length()) {
            if (days.optJSONObject(i)?.optBoolean("isToday", false) == true) return i
        }
        return TODAY
    }

    private fun summaryOf(habits: JSONArray, today: Int): JSONObject {
        var due = 0
        var done = 0
        var weight = 0
        var doneWeight = 0
        var best = 0
        var weekDone = 0
        for (i in 0 until habits.length()) {
            val habit = habits.optJSONObject(i) ?: continue
            if (habit.optBoolean("tracking", false)) continue
            val completions = habit.optJSONArray("completions")
            best = maxOf(best, habit.optInt("streak", 0))
            for (day in 0 until WEEK) {
                if (completions?.optBoolean(day, false) == true) weekDone++
            }
            val scheduled = habit.optJSONArray("scheduled")
            if (scheduled != null && !scheduled.optBoolean(today, false)) continue
            val share = habit.optInt("weight", 1).coerceAtLeast(1)
            due++
            weight += share
            if (completions?.optBoolean(today, false) == true) {
                done++
                doneWeight += share
            }
        }
        return JSONObject()
            .put("total", due)
            .put("doneToday", done)
            .put("ratio", if (weight == 0) 0.0 else doneWeight.toDouble() / weight)
            .put("bestStreak", best)
            .put("weekDone", weekDone)
    }

    fun isStale(context: Context): Boolean {
        val root = raw(context) ?: return false
        val stored = root.optString("todayKey", "")
        val cutoff = root.optInt("dayCutoff", 0).coerceIn(0, 6)
        return stored.isNotEmpty() && stored != systemDayKey(cutoff)
    }

    fun windowIndexOf(root: JSONObject, dayKey: String): Int {
        val days = root.optJSONArray("days") ?: return -1
        for (i in 0 until days.length()) {
            if (days.optJSONObject(i)?.optString("key") == dayKey) return i
        }
        return -1
    }

    fun align(root: JSONObject, todayKey: String): JSONObject {
        val days = root.optJSONArray("days") ?: return root
        if (days.length() <= WEEK) return root

        val end = windowIndexOf(root, todayKey)
        val start = when {
            end < 0 -> days.length() - WEEK
            end < TODAY -> 0
            else -> end - TODAY
        }

        if (start > 0) root.put("earlierDays", shift(root.optJSONArray("earlierDays"), days, start))
        root.put("days", sliceDays(days, start, todayKey))
        if (end > TODAY) {
            val since = TODAY - root.optInt("weekOffset", 0) + end - TODAY
            root.put("weekOffset", TODAY - since % WEEK)
        }

        val habits = root.optJSONArray("habits") ?: return root
        var due = 0
        var doneToday = 0
        var weekDone = 0
        var scheduling = false

        for (i in 0 until habits.length()) {
            val habit = habits.optJSONObject(i) ?: continue
            val scheduled = habit.optJSONArray("scheduled")
            if (start > 0) {
                val earlier = habit.optJSONObject("earlier") ?: JSONObject()
                for (name in listOf("completions", "counts", "scheduled")) {
                    earlier.put(name, shift(earlier.optJSONArray(name), habit.optJSONArray(name), start))
                }
                habit.put("earlier", earlier)
            }
            val completions = slice(habit.optJSONArray("completions"), start)
            habit.put("completions", completions)
            habit.put("counts", slice(habit.optJSONArray("counts"), start))
            if (scheduled != null) habit.put("scheduled", slice(scheduled, start))

            if (habit.optBoolean("tracking", false)) continue
            for (day in 0 until WEEK) {
                if (completions.optBoolean(day, false)) weekDone++
            }
            if (scheduled == null) continue
            scheduling = true
            if (scheduled.optBoolean(end, false)) {
                due++
                if (completions.optBoolean(TODAY, false)) doneToday++
            }
        }

        if (scheduling && end - start == TODAY) {
            val summary = root.optJSONObject("summary") ?: JSONObject()
            summary.put("total", due)
            summary.put("doneToday", doneToday)
            summary.put("weekDone", weekDone)
            root.put("summary", summary)
        }
        return root
    }

    private fun sliceDays(days: JSONArray, start: Int, todayKey: String): JSONArray {
        val out = JSONArray()
        for (i in 0 until SPAN) {
            val day = days.optJSONObject(start + i) ?: continue
            out.put(
                JSONObject()
                    .put("key", day.optString("key"))
                    .put("label", day.optString("label"))
                    .put("short", day.optString("short"))
                    .put("isToday", day.optString("key") == todayKey),
            )
        }
        return out
    }

    private fun shift(earlier: JSONArray?, values: JSONArray?, start: Int): JSONArray {
        val out = JSONArray()
        for (k in 0 until EARLIER) {
            val at = start - EARLIER + k
            out.put((if (at >= 0) values?.opt(at) else earlier?.opt(at + EARLIER)) ?: JSONObject.NULL)
        }
        return out
    }

    private fun slice(values: JSONArray?, start: Int): JSONArray {
        val out = JSONArray()
        if (values == null) return out
        for (i in 0 until SPAN) out.put(values.opt(start + i) ?: JSONObject.NULL)
        return out
    }
}
