package com.streak.app

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetManager

object GlanceWidgets {

    suspend fun updateAll(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        val widgets = listOf<Pair<Class<*>, () -> GlanceAppWidget>>(
            HabitWidgetProvider::class.java to { HabitWidget() },
            TodayWidgetProvider::class.java to { TodayWidget() },
            StatsWidgetProvider::class.java to { StatsWidget() },
            TodosWidgetProvider::class.java to { TodosWidget() },
        )
        val glance = GlanceAppWidgetManager(context)
        for ((provider, widget) in widgets) {
            try {
                val ids = manager.getAppWidgetIds(ComponentName(context, provider))
                if (ids.isEmpty()) continue
                val instance = widget()
                for (id in ids) instance.update(context, glance.getGlanceIdBy(id))
            } catch (e: Exception) {
                continue
            }
        }
    }
}
