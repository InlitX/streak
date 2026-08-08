package com.streak.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class WidgetActionReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ACTION_TOGGLE) return
        val habitId = intent.getStringExtra(EXTRA_HABIT_ID) ?: return
        val dayIndex = intent.getIntExtra(EXTRA_DAY_INDEX, TODAY_INDEX).coerceIn(0, 6)
        val data = HabitCardData.load(context, habitId, null) ?: return

        if (data.focusOnly && !data.isDoneOn(dayIndex)) {
            if (dayIndex == TODAY_INDEX) startFocus(context, habitId)
            return
        }

        val delta = if (data.kind == KIND_QUANTITATIVE) data.incrementAmount else 1.0

        if (WidgetOptimistic.apply(context, habitId, dayIndex, delta)) {
            HeatmapRenderer.refreshContent(context)
            repaintGlance(context)
        }

        val action = when (data.kind) {
            KIND_NEGATIVE -> "relapse"
            KIND_QUANTITATIVE -> "progress"
            else -> "toggle"
        }
        WidgetActionWorker.enqueue(
            context,
            "streak://toggleHabit?habitId=$habitId&dayIndex=$dayIndex" +
                "&action=$action&delta=${WidgetText.amount(delta)}",
        )
    }

    private fun startFocus(context: Context, habitId: String) {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra(EXTRA_START_FOCUS, habitId)
        }
        context.startActivity(intent)
    }

    private fun repaintGlance(context: Context) {
        val pending = goAsync()
        CoroutineScope(Dispatchers.Main).launch {
            try {
                GlanceWidgets.updateAll(context)
            } catch (e: Exception) {
            } finally {
                pending.finish()
            }
        }
    }

    companion object {
        const val ACTION_TOGGLE = "com.streak.app.TOGGLE_HABIT"
        const val EXTRA_HABIT_ID = "habitId"
        const val EXTRA_WIDGET_ID = "appWidgetId"
        const val EXTRA_DAY_INDEX = "dayIndex"
        const val EXTRA_START_FOCUS = "startFocusHabitId"

        private const val TODAY_INDEX = 6
        private const val KIND_NEGATIVE = 1
        private const val KIND_QUANTITATIVE = 2

        fun intent(context: Context, habitId: String, dayIndex: Int): Intent =
            Intent(context, WidgetActionReceiver::class.java).apply {
                action = ACTION_TOGGLE
                putExtra(EXTRA_HABIT_ID, habitId)
                putExtra(EXTRA_DAY_INDEX, dayIndex)
            }
    }
}
