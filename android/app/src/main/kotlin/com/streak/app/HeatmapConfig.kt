package com.streak.app

import android.content.Context

// Per-widget habit choice; no entry = all habits.
object HeatmapConfig {
    const val LAYOUT_CLASSIC = 0
    const val LAYOUT_CARD = 1

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

    fun layoutOf(context: Context, appWidgetId: Int): Int =
        when (prefs(context).getInt("layout_$appWidgetId", LAYOUT_CLASSIC)) {
            LAYOUT_CLASSIC -> LAYOUT_CLASSIC
            else -> LAYOUT_CARD
        }

    fun setLayout(context: Context, appWidgetId: Int, layout: Int) {
        prefs(context).edit().putInt("layout_$appWidgetId", layout).commit()
    }

    fun colorOf(context: Context, appWidgetId: Int): Int? {
        val p = prefs(context)
        return if (p.contains("color_$appWidgetId")) p.getInt("color_$appWidgetId", 0) else null
    }

    fun setColor(context: Context, appWidgetId: Int, color: Int?) {
        prefs(context).edit().apply {
            if (color == null) remove("color_$appWidgetId")
            else putInt("color_$appWidgetId", color)
        }.commit()
    }

    fun clear(context: Context, appWidgetId: Int) {
        prefs(context).edit()
            .remove("habit_$appWidgetId")
            .remove("color_$appWidgetId")
            .remove("layout_$appWidgetId")
            .apply()
    }
}
