package com.streak.app

import android.content.Context

// Per-widget habit choice; no entry = all habits.
object HeatmapConfig {
    private const val PREFS = "StreakHeatmapConfig"

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun habitOf(context: Context, appWidgetId: Int): String? =
        prefs(context).getString("habit_$appWidgetId", null)

    fun setHabit(context: Context, appWidgetId: Int, habitId: String?) {
        // commit() (sync): the widget renders right after and apply() would read stale.
        prefs(context).edit().apply {
            if (habitId == null) remove("habit_$appWidgetId")
            else putString("habit_$appWidgetId", habitId)
        }.commit()
    }

    fun clear(context: Context, appWidgetId: Int) {
        prefs(context).edit().remove("habit_$appWidgetId").apply()
    }
}
