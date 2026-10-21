package com.streak.app

import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import androidx.datastore.preferences.core.longPreferencesKey
import androidx.glance.GlanceId
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.state.updateAppWidgetState
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withTimeoutOrNull

object GlanceWidgets {

    val REVISION = longPreferencesKey("revision")

    private const val BUDGET_MS = 8_000L

    suspend fun refresh(context: Context, widget: GlanceAppWidget, id: GlanceId) {
        updateAppWidgetState(context, id) { it[REVISION] = System.nanoTime() }
        widget.update(context, id)
    }

    fun refreshSoon(
        context: Context,
        widget: GlanceAppWidget,
        ids: IntArray,
        pending: BroadcastReceiver.PendingResult,
    ) {
        val app = context.applicationContext
        CoroutineScope(Dispatchers.Default).launch {
            try {
                withTimeoutOrNull(BUDGET_MS) {
                    val glance = GlanceAppWidgetManager(app)
                    for (id in ids) {
                        try {
                            refresh(app, widget, glance.getGlanceIdBy(id))
                        } catch (e: Exception) {
                            continue
                        }
                    }
                }
            } finally {
                pending.finish()
            }
        }
    }

    suspend fun updateAll(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        val widgets = listOf<Pair<Class<*>, () -> GlanceAppWidget>>(
            HabitWidgetProvider::class.java to { HabitWidget() },
            TodayWidgetProvider::class.java to { TodayWidget() },
            StatsWidgetProvider::class.java to { StatsWidget() },
            FocusWidgetProvider::class.java to { FocusWidget() },
            TodosWidgetProvider::class.java to { TodosWidget() },
        )
        val glance = GlanceAppWidgetManager(context)
        for ((provider, widget) in widgets) {
            try {
                val ids = manager.getAppWidgetIds(ComponentName(context, provider))
                if (ids.isEmpty()) continue
                val instance = widget()
                for (id in ids) refresh(context, instance, glance.getGlanceIdBy(id))
            } catch (e: Exception) {
                continue
            }
        }
    }
}
