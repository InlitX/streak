package com.streak.app

import android.app.Notification
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.service.notification.StatusBarNotification
import android.text.SpannableString
import android.text.Spanned
import android.text.style.StrikethroughSpan
import android.view.View
import android.widget.RemoteViews
import com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver
import org.json.JSONArray
import org.json.JSONObject

class ReminderReceiver : ScheduledNotificationReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        val details = intent.getStringExtra("notificationDetails") ?: return
        val json = try {
            JSONObject(details)
        } catch (e: Exception) {
            return
        }
        val habitId = json.optString("payload")
        if (habitId.isEmpty() || !json.has("id")) return
        val id = json.optInt("id")
        if (ReminderScale.applies(context, habitId)) {
            ReminderScale.show(context, goAsync(), id, habitId)
        } else {
            ReminderSteps.show(context, goAsync(), id, habitId)
        }
    }
}

class ReminderStepReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val habitId = intent.getStringExtra(ReminderSteps.EXTRA_HABIT) ?: return
        val stepId = intent.getStringExtra(ReminderSteps.EXTRA_STEP) ?: return
        ReminderSteps.check(context, goAsync(), intent.getIntExtra(ReminderSteps.EXTRA_ID, 0), habitId, stepId)
    }
}

object ReminderSteps {

    const val EXTRA_ID = "notificationId"
    const val EXTRA_HABIT = "habitId"
    const val EXTRA_STEP = "stepId"

    private const val PREFS = "streak_reminder_steps"
    private const val ROWS = 5
    private const val LEAVE_MS = 700L
    private const val FIND_MS = 250L
    private const val FIND_TRIES = 8

    private val rowIds = intArrayOf(R.id.step_1, R.id.step_2, R.id.step_3, R.id.step_4, R.id.step_5)
    private val boxIds = intArrayOf(R.id.step_1_box, R.id.step_2_box, R.id.step_3_box, R.id.step_4_box, R.id.step_5_box)
    private val textIds = intArrayOf(R.id.step_1_text, R.id.step_2_text, R.id.step_3_text, R.id.step_4_text, R.id.step_5_text)

    private val main = Handler(Looper.getMainLooper())

    private class Steps(
        val habitId: String,
        val day: String,
        val ids: List<String>,
        val titles: List<String>,
        val done: Set<String>,
        val leaving: Set<String>,
        val needed: Int,
        val color: Int,
    ) {
        val complete get() = ids.count { it in done } >= needed
    }

    fun show(context: Context, pending: BroadcastReceiver.PendingResult, id: Int, habitId: String) {
        prefs(context).edit().remove(habitId).apply()
        val steps = load(context, habitId)
        if (steps == null || steps.complete || steps.ids.all { it in steps.done }) {
            pending.finish()
            return
        }
        fun attempt(left: Int) {
            try {
                if (render(context, id, steps) || left <= 0) {
                    pending.finish()
                    return
                }
            } catch (e: Exception) {
                pending.finish()
                return
            }
            main.postDelayed({ attempt(left - 1) }, FIND_MS)
        }
        main.postDelayed({ attempt(FIND_TRIES) }, FIND_MS)
    }

    fun check(context: Context, pending: BroadcastReceiver.PendingResult, id: Int, habitId: String, stepId: String) {
        val steps = load(context, habitId)
        if (steps == null || stepId !in steps.ids || stepId in steps.done) {
            pending.finish()
            return
        }
        WidgetActionWorker.enqueue(
            context,
            "streak://toggleHabit?habitId=${Uri.encode(habitId)}&day=${steps.day}" +
                "&action=step&step=${Uri.encode(stepId)}",
        )
        remember(context, habitId, steps.day, stepId, leaving = true)
        try {
            load(context, habitId)?.let { render(context, id, it) }
        } catch (e: Exception) {
        }
        main.postDelayed({
            try {
                remember(context, habitId, steps.day, stepId, leaving = false)
                val now = load(context, habitId)
                when {
                    now == null -> Unit
                    now.leaving.isNotEmpty() -> Unit
                    now.complete || now.ids.all { it in now.done } -> cancel(context, id)
                    else -> render(context, id, now)
                }
            } catch (e: Exception) {
            } finally {
                pending.finish()
            }
        }, LEAVE_MS)
    }

    private fun render(context: Context, id: Int, steps: Steps): Boolean {
        val posted = find(context, id) ?: return false
        val current = posted.notification
        val extras = current.extras
        val visible = steps.ids.indices.filter { steps.ids[it] !in steps.done || steps.ids[it] in steps.leaving }
        val shown = visible.take(ROWS)
        val more = visible.size - shown.size

        val views = RemoteViews(context.packageName, R.layout.reminder_steps)
        views.setTextViewText(R.id.steps_title, extras.getCharSequence(Notification.EXTRA_TITLE) ?: "")
        val body = extras.getCharSequence(Notification.EXTRA_TEXT)
        if (body.isNullOrEmpty()) {
            views.setViewVisibility(R.id.steps_body, View.GONE)
        } else {
            views.setTextViewText(R.id.steps_body, body)
        }
        for (slot in 0 until ROWS) {
            val index = shown.getOrNull(slot)
            if (index == null) {
                views.setViewVisibility(rowIds[slot], View.GONE)
                continue
            }
            val stepId = steps.ids[index]
            val title = steps.titles[index]
            val leaving = stepId in steps.leaving
            views.setViewVisibility(rowIds[slot], View.VISIBLE)
            views.setImageViewBitmap(boxIds[slot], box(context, steps.color, leaving))
            views.setTextViewText(textIds[slot], if (leaving) struck(title) else title)
            views.setOnClickPendingIntent(rowIds[slot], tap(context, id, steps.habitId, stepId))
        }
        if (more > 0) {
            views.setViewVisibility(R.id.steps_more, View.VISIBLE)
            views.setTextViewText(R.id.steps_more, "+$more")
            views.setTextColor(R.id.steps_more, steps.color)
        } else {
            views.setViewVisibility(R.id.steps_more, View.GONE)
        }

        val rebuilt = Notification.Builder.recoverBuilder(context, current)
            .setStyle(Notification.DecoratedCustomViewStyle())
            .setCustomBigContentView(views)
            .setOnlyAlertOnce(true)
            .build()
        manager(context).notify(posted.tag, id, rebuilt)
        return true
    }

    private fun cancel(context: Context, id: Int) {
        val posted = find(context, id) ?: return
        manager(context).cancel(posted.tag, id)
    }

    private fun find(context: Context, id: Int): StatusBarNotification? =
        manager(context).activeNotifications.firstOrNull { it.id == id }

    private fun manager(context: Context) =
        context.getSystemService(NotificationManager::class.java)

    private fun box(context: Context, color: Int, checked: Boolean): Bitmap {
        val dp = context.resources.displayMetrics.density
        val side = (22 * dp).toInt()
        val bitmap = Bitmap.createBitmap(side, side, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        val radius = 7 * dp
        if (checked) {
            paint.color = color
            canvas.drawRoundRect(RectF(0f, 0f, side.toFloat(), side.toFloat()), radius, radius, paint)
            val scale = 14 * dp / 24f
            val offset = (side - 24 * scale) / 2
            val tick = Path().apply {
                moveTo(offset + 20 * scale, offset + 6 * scale)
                lineTo(offset + 9 * scale, offset + 17 * scale)
                lineTo(offset + 4 * scale, offset + 12 * scale)
            }
            paint.color = 0xFFFFFFFF.toInt()
            paint.style = Paint.Style.STROKE
            paint.strokeWidth = 2.4f * dp
            paint.strokeCap = Paint.Cap.ROUND
            paint.strokeJoin = Paint.Join.ROUND
            canvas.drawPath(tick, paint)
        } else {
            val stroke = 1.8f * dp
            paint.style = Paint.Style.STROKE
            paint.strokeWidth = stroke
            paint.color = color
            val inset = stroke / 2
            canvas.drawRoundRect(RectF(inset, inset, side - inset, side - inset), radius - inset, radius - inset, paint)
        }
        return bitmap
    }

    private fun struck(text: String): CharSequence =
        SpannableString(text).apply {
            setSpan(StrikethroughSpan(), 0, text.length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
        }

    private fun tap(context: Context, id: Int, habitId: String, stepId: String): PendingIntent {
        val intent = Intent(context, ReminderStepReceiver::class.java).apply {
            putExtra(EXTRA_ID, id)
            putExtra(EXTRA_HABIT, habitId)
            putExtra(EXTRA_STEP, stepId)
            data = Uri.parse("streak://reminderStep/$id/${Uri.encode(habitId)}/${Uri.encode(stepId)}")
        }
        return PendingIntent.getBroadcast(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun today(context: Context) =
        WidgetPayload.systemDayKey(WidgetPayload.dayCutoff(context))

    private fun load(context: Context, habitId: String): Steps? {
        val raw = WidgetPayload.raw(context) ?: return null
        val habits = raw.optJSONArray("habits") ?: return null
        var habit: JSONObject? = null
        for (i in 0 until habits.length()) {
            val item = habits.optJSONObject(i) ?: continue
            if (item.optString("id") == habitId) {
                habit = item
                break
            }
        }
        val list = habit?.optJSONArray("steps") ?: return null
        val ids = mutableListOf<String>()
        val titles = mutableListOf<String>()
        for (i in 0 until list.length()) {
            val step = list.optJSONArray(i) ?: continue
            ids.add(step.optString(0))
            titles.add(step.optString(1))
        }
        if (ids.isEmpty()) return null

        val day = today(context)
        val done = mutableSetOf<String>()
        if (raw.optString("todayKey") == day) done.addAll(strings(habit.optJSONArray("stepsDone")))
        val local = local(context, habitId)
        val leaving = mutableSetOf<String>()
        if (local?.optString("day") == day) {
            done.addAll(strings(local.optJSONArray("done")))
            leaving.addAll(strings(local.optJSONArray("leaving")))
        }
        return Steps(
            habitId = habitId,
            day = day,
            ids = ids,
            titles = titles,
            done = done,
            leaving = leaving,
            needed = habit.optInt("stepsNeeded", ids.size).coerceIn(1, ids.size),
            color = habit.optInt("color", 0xFF7C4DFF.toInt()),
        )
    }

    @Synchronized
    private fun remember(context: Context, habitId: String, day: String, stepId: String, leaving: Boolean) {
        val current = local(context, habitId)?.takeIf { it.optString("day") == day }
        val done = strings(current?.optJSONArray("done")).toMutableSet().apply { add(stepId) }
        val away = strings(current?.optJSONArray("leaving")).toMutableSet().apply {
            if (leaving) add(stepId) else remove(stepId)
        }
        val json = JSONObject()
            .put("day", day)
            .put("done", JSONArray(done.toList()))
            .put("leaving", JSONArray(away.toList()))
        prefs(context).edit().putString(habitId, json.toString()).commit()
    }

    private fun local(context: Context, habitId: String): JSONObject? = try {
        prefs(context).getString(habitId, null)?.let { JSONObject(it) }
    } catch (e: Exception) {
        null
    }

    private fun strings(array: JSONArray?): List<String> {
        if (array == null) return emptyList()
        return (0 until array.length()).map { array.optString(it) }
    }

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
}
