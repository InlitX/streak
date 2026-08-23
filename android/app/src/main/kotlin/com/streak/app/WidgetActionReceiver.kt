package com.streak.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.net.Uri
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class WidgetActionReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ACTION_TOGGLE_TODO) {
            toggleTodo(context, intent)
            return
        }
        if (intent.action != ACTION_TOGGLE) return
        val habitId = intent.getStringExtra(EXTRA_HABIT_ID) ?: return
        val dayKey = intent.getStringExtra(EXTRA_DAY_KEY) ?: WidgetPayload.todayKey(context)
        val data = HabitCardData.load(context, habitId, null) ?: return
        val column = columnOf(context, dayKey)

        if (data.focusOnly) {
            if (!data.isDoneOn(column) && dayKey == WidgetPayload.todayKey(context)) {
                startFocus(context, habitId)
            }
            return
        }

        val delta = if (data.kind == KIND_QUANTITATIVE) data.incrementAmount else 1.0

        if (WidgetOptimistic.apply(context, habitId, dayKey, delta)) {
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
            "streak://toggleHabit?habitId=$habitId&day=$dayKey" +
                "&action=$action&delta=${WidgetText.amount(delta)}",
        )
    }

    private fun toggleTodo(context: Context, intent: Intent) {
        val todoId = intent.getStringExtra(EXTRA_TODO_ID) ?: return
        if (TodosPayload.toggleDone(context, todoId)) repaintGlance(context)
        WidgetActionWorker.enqueue(context, "streak://toggleTodo?todoId=$todoId")
    }

    private fun columnOf(context: Context, dayKey: String): Int {
        val days = WidgetPayload.aligned(context)?.optJSONArray("days") ?: return WidgetPayload.TODAY
        for (i in 0 until days.length()) {
            if (days.optJSONObject(i)?.optString("key") == dayKey) return i
        }
        return WidgetPayload.TODAY
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
        const val ACTION_TOGGLE_TODO = "com.streak.app.TOGGLE_TODO"
        const val EXTRA_TODO_ID = "todoId"
        const val EXTRA_HABIT_ID = "habitId"
        const val EXTRA_WIDGET_ID = "appWidgetId"
        const val EXTRA_DAY_KEY = "dayKey"
        const val EXTRA_START_FOCUS = "startFocusHabitId"

        private const val KIND_NEGATIVE = 1
        private const val KIND_QUANTITATIVE = 2

        fun intent(context: Context, habitId: String, dayKey: String): Intent =
            Intent(context, WidgetActionReceiver::class.java).apply {
                action = ACTION_TOGGLE
                putExtra(EXTRA_HABIT_ID, habitId)
                putExtra(EXTRA_DAY_KEY, dayKey)
                data = Uri.parse("streak://toggleHabit/$habitId/$dayKey")
            }

        fun todoIntent(context: Context, todoId: String): Intent =
            Intent(context, WidgetActionReceiver::class.java).apply {
                action = ACTION_TOGGLE_TODO
                putExtra(EXTRA_TODO_ID, todoId)
                data = Uri.parse("streak://toggleTodo/$todoId")
            }
    }
}
