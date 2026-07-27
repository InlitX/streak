package com.streak.app

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.updateAll

object GlanceWidgets {

    suspend fun updateAll(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        val widgets = listOf<Pair<Class<*>, () -> GlanceAppWidget>>(
            HabitWidgetProvider::class.java to { HabitWidget() },
            TodayWidgetProvider::class.java to { TodayWidget() },
            StatsWidgetProvider::class.java to { StatsWidget() },
        )
        for ((provider, widget) in widgets) {
            try {
                if (manager.getAppWidgetIds(ComponentName(context, provider)).isEmpty()) continue
                widget().updateAll(context)
            } catch (e: Exception) {
                continue
            }
        }
    }
}
