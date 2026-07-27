package com.streak.app

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import java.util.Calendar

class WidgetRefreshReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        schedule(context)
        if (!hasWidgets(context)) return
        HeatmapRenderer.updateAll(context)
        WidgetActionWorker.refresh(context)
    }

    companion object {
        const val ACTION_MIDNIGHT = "com.streak.app.WIDGET_MIDNIGHT"

        private const val REQUEST_CODE = 90210

        private val PROVIDERS = listOf(
            HabitWidgetProvider::class.java,
            TodayWidgetProvider::class.java,
            StatsWidgetProvider::class.java,
            HeatmapWidgetProvider::class.java,
        )

        fun hasWidgets(context: Context): Boolean = try {
            val manager = AppWidgetManager.getInstance(context)
            PROVIDERS.any {
                manager.getAppWidgetIds(ComponentName(context, it)).isNotEmpty()
            }
        } catch (e: Exception) {
            false
        }

        fun schedule(context: Context) {
            try {
                val next = Calendar.getInstance().apply {
                    add(Calendar.DAY_OF_YEAR, 1)
                    set(Calendar.HOUR_OF_DAY, 0)
                    set(Calendar.MINUTE, 0)
                    set(Calendar.SECOND, 5)
                    set(Calendar.MILLISECOND, 0)
                }
                context.getSystemService(AlarmManager::class.java).set(
                    AlarmManager.RTC,
                    next.timeInMillis,
                    pending(context),
                )
            } catch (e: Exception) {
                return
            }
        }

        private fun pending(context: Context): PendingIntent = PendingIntent.getBroadcast(
            context,
            REQUEST_CODE,
            Intent(context, WidgetRefreshReceiver::class.java).setAction(ACTION_MIDNIGHT),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
