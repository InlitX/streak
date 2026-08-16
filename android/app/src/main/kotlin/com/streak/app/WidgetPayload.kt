package com.streak.app

import android.content.Context
import java.util.Calendar
import java.util.Locale
import org.json.JSONArray
import org.json.JSONObject

object WidgetPayload {

    const val WEEK = 7
    const val TODAY = WEEK - 1

    fun todayKey(): String {
        val now = Calendar.getInstance()
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

    fun aligned(context: Context): JSONObject? = raw(context)?.let { align(it, todayKey()) }

    fun isStale(context: Context): Boolean {
        val root = raw(context) ?: return false
        val stored = root.optString("todayKey", "")
        return stored.isNotEmpty() && stored != todayKey()
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

        root.put("days", sliceDays(days, start, todayKey))

        val habits = root.optJSONArray("habits") ?: return root
        var due = 0
        var doneToday = 0
        var weekDone = 0
        var scheduling = false

        for (i in 0 until habits.length()) {
            val habit = habits.optJSONObject(i) ?: continue
            val scheduled = habit.optJSONArray("scheduled")
            val completions = slice(habit.optJSONArray("completions"), start)
            habit.put("completions", completions)
            habit.put("counts", slice(habit.optJSONArray("counts"), start))
            if (scheduled != null) habit.put("scheduled", slice(scheduled, start))

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
        for (i in 0 until WEEK) {
            val day = days.optJSONObject(start + i) ?: continue
            out.put(
                JSONObject()
                    .put("key", day.optString("key"))
                    .put("label", day.optString("label"))
                    .put("isToday", day.optString("key") == todayKey),
            )
        }
        return out
    }

    private fun slice(values: JSONArray?, start: Int): JSONArray {
        val out = JSONArray()
        if (values == null) return out
        for (i in 0 until WEEK) out.put(values.opt(start + i) ?: JSONObject.NULL)
        return out
    }
}
