package com.streak.app

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import java.util.Calendar
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class WidgetRefreshReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (!hasWidgets(context)) return
        schedule(context)
        val pending = goAsync()
        CoroutineScope(Dispatchers.Main).launch {
            try {
                repaint(context)
            } catch (e: Exception) {
            } finally {
                pending.finish()
            }
        }
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
            TodosWidgetProvider::class.java,
        )

        fun keepFresh(context: Context) {
            schedule(context)
            if (WidgetPayload.isStale(context)) WidgetActionWorker.refresh(context)
        }

        suspend fun repaint(context: Context) {
            HeatmapRenderer.updateAll(context)
            GlanceWidgets.updateAll(context)
        }

        fun refreshAll(context: Context) {
            if (!hasWidgets(context)) return
            HeatmapRenderer.updateAll(context)
            WidgetActionWorker.refresh(context)
        }

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
                val cutoff = WidgetPayload.dayCutoff(context)
                val next = Calendar.getInstance().apply {
                    set(Calendar.HOUR_OF_DAY, cutoff)
                    set(Calendar.MINUTE, 0)
                    set(Calendar.SECOND, 5)
                    set(Calendar.MILLISECOND, 0)
                    if (timeInMillis <= System.currentTimeMillis()) {
                        add(Calendar.DAY_OF_YEAR, 1)
                    }
                }
                val alarms = context.getSystemService(AlarmManager::class.java)
                val at = next.timeInMillis
                val intent = pending(context)
                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S ||
                    alarms.canScheduleExactAlarms()
                ) {
                    alarms.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, intent)
                } else {
                    alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, intent)
                }
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
