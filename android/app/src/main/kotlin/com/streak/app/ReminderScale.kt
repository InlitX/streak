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
import android.view.View
import android.widget.RemoteViews
import org.json.JSONObject

class ReminderScaleReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val habitId = intent.getStringExtra(ReminderScale.EXTRA_HABIT) ?: return
        val level = intent.getIntExtra(ReminderScale.EXTRA_LEVEL, 0)
        if (level !in 1..5) return
        ReminderScale.pick(context, intent.getIntExtra(ReminderScale.EXTRA_ID, 0), habitId, level)
    }
}

object ReminderScale {

    const val EXTRA_ID = "notificationId"
    const val EXTRA_HABIT = "habitId"
    const val EXTRA_LEVEL = "level"

    private const val FIND_MS = 250L
    private const val FIND_TRIES = 8

    private val faceIds = intArrayOf(R.id.face_1, R.id.face_2, R.id.face_3, R.id.face_4, R.id.face_5)
    private val colors = intArrayOf(
        0xFFE5484D.toInt(),
        0xFFF2803A.toInt(),
        0xFFF2C14B.toInt(),
        0xFF93CF58.toInt(),
        0xFF34C07A.toInt(),
    )

    private val main = Handler(Looper.getMainLooper())

    fun applies(context: Context, habitId: String): Boolean =
        habit(context, habitId)?.optBoolean("scale") == true

    fun show(context: Context, pending: BroadcastReceiver.PendingResult, id: Int, habitId: String) {
        fun attempt(left: Int) {
            try {
                if (render(context, id, habitId) || left <= 0) {
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

    fun pick(context: Context, id: Int, habitId: String, level: Int) {
        val day = WidgetPayload.systemDayKey(WidgetPayload.dayCutoff(context))
        WidgetActionWorker.enqueue(
            context,
            "streak://toggleHabit?habitId=${Uri.encode(habitId)}&day=$day&action=scale&level=$level",
        )
        val posted = find(context, id) ?: return
        manager(context).cancel(posted.tag, id)
    }

    private fun render(context: Context, id: Int, habitId: String): Boolean {
        val posted = find(context, id) ?: return false
        val current = posted.notification
        val extras = current.extras
        val views = RemoteViews(context.packageName, R.layout.reminder_scale)
        views.setTextViewText(R.id.scale_title, extras.getCharSequence(Notification.EXTRA_TITLE) ?: "")
        val body = extras.getCharSequence(Notification.EXTRA_TEXT)
        if (body.isNullOrEmpty()) {
            views.setViewVisibility(R.id.scale_body, View.GONE)
        } else {
            views.setTextViewText(R.id.scale_body, body)
        }
        for (slot in 0 until 5) {
            views.setImageViewBitmap(faceIds[slot], face(context, slot + 1))
            views.setOnClickPendingIntent(faceIds[slot], tap(context, id, habitId, slot + 1))
        }
        val rebuilt = Notification.Builder.recoverBuilder(context, current)
            .setStyle(Notification.DecoratedCustomViewStyle())
            .setCustomBigContentView(views)
            .setOnlyAlertOnce(true)
            .build()
        manager(context).notify(posted.tag, id, rebuilt)
        return true
    }

    private fun face(context: Context, level: Int): Bitmap {
        val dp = context.resources.displayMetrics.density
        val side = (34 * dp).toInt()
        val bitmap = Bitmap.createBitmap(side, side, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        val r = side / 2f
        val cx = r
        val cy = r
        paint.color = colors[level - 1]
        canvas.drawCircle(cx, cy, r, paint)

        val ink = 0xFF1C1A22.toInt()
        paint.color = ink
        val eyeY = cy - r * 0.18f
        val eyeX = r * 0.34f
        val eyeW = r * 0.17f
        val eyeH = r * (if (level == 5) 0.17f else 0.24f)
        for (dx in floatArrayOf(-eyeX, eyeX)) {
            canvas.drawOval(RectF(cx + dx - eyeW / 2, eyeY - eyeH / 2, cx + dx + eyeW / 2, eyeY + eyeH / 2), paint)
        }

        val mouthY = cy + r * 0.34f
        val half = r * (if (level == 3) 0.3f else 0.4f)
        val bend = when (level) {
            1 -> -0.32f
            2 -> -0.16f
            3 -> 0f
            4 -> 0.2f
            else -> 0.42f
        }
        val mouth = Path().apply {
            moveTo(cx - half, mouthY - r * bend * 0.5f)
            quadTo(cx, mouthY + r * bend * 0.9f, cx + half, mouthY - r * bend * 0.5f)
        }
        if (level == 5) {
            mouth.close()
            paint.style = Paint.Style.FILL
        } else {
            paint.style = Paint.Style.STROKE
            paint.strokeWidth = r * 0.14f
            paint.strokeCap = Paint.Cap.ROUND
        }
        canvas.drawPath(mouth, paint)
        return bitmap
    }

    private fun tap(context: Context, id: Int, habitId: String, level: Int): PendingIntent {
        val intent = Intent(context, ReminderScaleReceiver::class.java).apply {
            putExtra(EXTRA_ID, id)
            putExtra(EXTRA_HABIT, habitId)
            putExtra(EXTRA_LEVEL, level)
            data = Uri.parse("streak://reminderScale/$id/${Uri.encode(habitId)}/$level")
        }
        return PendingIntent.getBroadcast(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun habit(context: Context, habitId: String): JSONObject? {
        val habits = WidgetPayload.raw(context)?.optJSONArray("habits") ?: return null
        for (i in 0 until habits.length()) {
            val item = habits.optJSONObject(i) ?: continue
            if (item.optString("id") == habitId) return item
        }
        return null
    }

    private fun find(context: Context, id: Int): StatusBarNotification? =
        manager(context).activeNotifications.firstOrNull { it.id == id }

    private fun manager(context: Context) =
        context.getSystemService(NotificationManager::class.java)
}
