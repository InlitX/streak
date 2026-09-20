package com.streak.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Typeface
import android.graphics.drawable.Icon
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import androidx.annotation.RequiresApi
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import org.json.JSONObject
import java.util.Locale

class FocusService : Service() {

    private val main = Handler(Looper.getMainLooper())
    private val tick = Runnable { refresh() }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        main.removeCallbacks(tick)
        super.onDestroy()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val state = FocusState.read(this)
        if (state == null) {
            stop()
            return START_NOT_STICKY
        }

        when (intent?.action) {
            ACTION_PAUSE -> {
                FocusState.save(this, FocusState.paused(state))
                FocusBridge.enqueue(this, "pause")
            }
            ACTION_RESUME -> {
                FocusState.save(this, FocusState.resumed(state))
                FocusBridge.enqueue(this, "resume")
            }
            ACTION_STOP -> {
                FocusBridge.enqueue(this, "stop")
                FocusState.clear(this)
                stop()
                return START_NOT_STICKY
            }
            ACTION_MINUTE -> {
                FocusState.save(this, FocusState.extended(state))
                FocusBridge.enqueue(this, "minute")
            }
            ACTION_SKIP -> FocusBridge.enqueue(this, "skip")
            ACTION_NEXT -> FocusBridge.enqueue(this, "next")
        }

        val current = FocusState.read(this) ?: state
        ensureChannel(current.optString("channelName"))
        enterForeground(build(current))
        schedule(current)
        return START_STICKY
    }

    private fun refresh() {
        val state = FocusState.read(this) ?: return
        getSystemService(NotificationManager::class.java)?.notify(NOTIFICATION_ID, build(state))
        schedule(state)
    }

    private fun schedule(state: JSONObject) {
        main.removeCallbacks(tick)
        if (Build.VERSION.SDK_INT < 36) return
        if (!state.optBoolean("running") || state.optBoolean("done")) return
        val now = System.currentTimeMillis()
        val anchor = state.optLong("anchor")
        val countDown = state.optBoolean("countDown")
        if (countDown && anchor <= now) return
        val phase = (if (countDown) anchor - now else now - anchor).mod(1000L)
        main.postDelayed(tick, (if (countDown) phase else 1000L - phase) + 15L)
    }

    private fun enterForeground(notification: Notification) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE,
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun stop() {
        main.removeCallbacks(tick)
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun ensureChannel(name: String) {
        val manager = getSystemService(NotificationManager::class.java) ?: return
        manager.deleteNotificationChannel(LEGACY_CHANNEL_ID)
        val label = name.ifEmpty { "Focus" }
        val channel = NotificationChannel(CHANNEL_ID, label, NotificationManager.IMPORTANCE_HIGH)
        channel.setShowBadge(false)
        channel.setSound(null, null)
        channel.enableVibration(false)
        manager.createNotificationChannel(channel)
    }

    private fun build(state: JSONObject): Notification {
        if (Build.VERSION.SDK_INT >= 36) return live(state)
        val running = state.optBoolean("running")
        val countDown = state.optBoolean("countDown")
        val accent = ContextCompat.getColor(this, colorFor(state.optString("phase")))
        val seconds = FocusState.seconds(state)

        val content = RemoteViews(packageName, R.layout.focus_notification).apply {
            setTextViewText(R.id.focus_title, state.optString("title"))
            setTextViewText(R.id.focus_state, state.optString("state"))
            setTextColor(R.id.focus_state, accent)
            setTextColor(R.id.focus_clock, accent)
            setTextColor(R.id.focus_frozen, accent)
            if (running) {
                setViewVisibility(R.id.focus_clock, View.VISIBLE)
                setViewVisibility(R.id.focus_frozen, View.GONE)
                val anchor = state.optLong("anchor", 0L)
                val base = if (anchor > 0L) {
                    SystemClock.elapsedRealtime() + (anchor - System.currentTimeMillis())
                } else {
                    val offset = seconds * 1000L
                    SystemClock.elapsedRealtime() + if (countDown) offset else -offset
                }
                setChronometer(R.id.focus_clock, base, null, true)
                setChronometerCountDown(R.id.focus_clock, countDown)
            } else {
                setViewVisibility(R.id.focus_clock, View.GONE)
                setViewVisibility(R.id.focus_frozen, View.VISIBLE)
                setTextViewText(R.id.focus_frozen, clock(seconds))
            }
        }

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_notify)
            .setStyle(NotificationCompat.DecoratedCustomViewStyle())
            .setCustomContentView(content)
            .setCustomBigContentView(content)
            .setColor(accent)
            .setColorized(false)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setShowWhen(false)
            .setCategory(NotificationCompat.CATEGORY_STOPWATCH)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setContentIntent(open(state))

        for (button in buttons(state, running, state.optBoolean("done"))) {
            builder.addAction(button.icon, button.label, action(button.action, button.request))
        }

        return builder.build()
    }

    @RequiresApi(36)
    private fun live(state: JSONObject): Notification {
        val running = state.optBoolean("running")
        val countDown = state.optBoolean("countDown")
        val seconds = FocusState.seconds(state)
        val total = state.optInt("total")
        val done = state.optBoolean("done") || (running && countDown && seconds == 0)
        val accent = getColor(colorFor(if (done) PHASE_DONE else state.optString("phase")))
        val timed = countDown && total > 0
        val elapsed = if (timed) (total - seconds).coerceIn(0, total) else seconds
        val time = clock(seconds)

        val style = Notification.ProgressStyle()
            .setStyledByProgress(true)
            .setProgressTrackerIcon(Icon.createWithBitmap(knob(accent)))
        if (timed) {
            style.setProgressSegments(listOf(Notification.ProgressStyle.Segment(total).setColor(accent)))
            style.setProgress(elapsed)
        } else {
            style.setProgressIndeterminate(running)
        }

        val builder = Notification.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_notify)
            .setContentTitle(state.optString("title"))
            .setContentText(state.optString("state"))
            .setLargeIcon(Icon.createWithBitmap(stamp(time, accent)))
            .setStyle(style)
            .setColor(accent)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setShowWhen(false)
            .setCategory(Notification.CATEGORY_STOPWATCH)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setContentIntent(open(state))
            .setShortCriticalText(if (done) "✓" else time)
        builder.extras.putBoolean(PROMOTED, true)

        for (button in buttons(state, running, done)) {
            builder.addAction(
                Notification.Action.Builder(
                    Icon.createWithResource(this, button.icon),
                    button.label,
                    action(button.action, button.request),
                ).build(),
            )
        }
        return builder.build()
    }

    private fun buttons(state: JSONObject, running: Boolean, done: Boolean): List<Button> {
        val timed = state.optBoolean("countDown")
        val pause = Button(R.drawable.ic_focus_pause, state.optString("pauseLabel"), ACTION_PAUSE, REQUEST_TOGGLE)
        val resume = Button(R.drawable.ic_focus_play, state.optString("resumeLabel"), ACTION_RESUME, REQUEST_TOGGLE)
        val minute = Button(R.drawable.ic_focus_plus, state.optString("minuteLabel"), ACTION_MINUTE, REQUEST_MINUTE)
        val skip = Button(R.drawable.ic_focus_skip, state.optString("skipLabel"), ACTION_SKIP, REQUEST_SKIP)
        val next = Button(R.drawable.ic_focus_play, state.optString("continueLabel"), ACTION_NEXT, REQUEST_NEXT)
        val end = Button(R.drawable.ic_focus_stop, state.optString("stopLabel"), ACTION_STOP, REQUEST_STOP)
        return when {
            state.optString("phase") == PHASE_WAITING -> listOf(next, end)
            done -> listOfNotNull(minute.takeIf { timed }, end)
            !running -> listOf(resume, end)
            state.optString("phase") == PHASE_BREAK -> listOf(skip, pause, end)
            else -> listOfNotNull(pause, minute.takeIf { timed }, end)
        }
    }

    private fun open(state: JSONObject): PendingIntent {
        val open = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_SINGLE_TOP or
                Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(WidgetActionReceiver.EXTRA_START_FOCUS, state.optString("habitId"))
        }
        return PendingIntent.getActivity(
            this,
            REQUEST_OPEN,
            open,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }

    private fun stamp(time: String, accent: Int): Bitmap {
        val width = 440
        val height = 210
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        paint.color = accent
        paint.typeface = Typeface.create(Typeface.DEFAULT, 900, false)
        paint.fontFeatureSettings = "tnum"
        paint.textAlign = Paint.Align.CENTER
        paint.textSize = height * 0.84f
        val room = width * 0.84f
        val measured = paint.measureText(time)
        if (measured > room) paint.textSize *= room / measured
        val metrics = paint.fontMetrics
        canvas.drawText(
            time,
            width / 2f,
            height * 0.54f - (metrics.ascent + metrics.descent) / 2f,
            paint,
        )
        return bitmap
    }

    private fun knob(accent: Int): Bitmap {
        val size = 96
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        paint.color = accent
        canvas.drawCircle(size / 2f, size / 2f, size / 2f, paint)
        return bitmap
    }

    private data class Button(val icon: Int, val label: String, val action: String, val request: Int)

    private fun action(name: String, request: Int): PendingIntent = PendingIntent.getService(
        this,
        request,
        Intent(this, FocusService::class.java).setAction(name),
        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
    )

    private fun colorFor(phase: String): Int = when (phase) {
        PHASE_WAITING -> R.color.focus_done
        PHASE_BREAK -> R.color.focus_break
        PHASE_PAUSED -> R.color.focus_paused
        PHASE_DONE -> R.color.focus_done
        else -> R.color.focus_running
    }

    private fun clock(seconds: Int): String = if (seconds >= 3600) {
        String.format(Locale.ROOT, "%d:%02d:%02d", seconds / 3600, seconds / 60 % 60, seconds % 60)
    } else {
        String.format(Locale.ROOT, "%02d:%02d", seconds / 60, seconds % 60)
    }

    companion object {
        const val CHANNEL_ID = "focus_timer"
        const val LEGACY_CHANNEL_ID = "focus_session"
        const val NOTIFICATION_ID = 4181

        const val ACTION_SHOW = "com.streak.app.FOCUS_SHOW"
        const val ACTION_PAUSE = "com.streak.app.FOCUS_PAUSE"
        const val ACTION_RESUME = "com.streak.app.FOCUS_RESUME"
        const val ACTION_STOP = "com.streak.app.FOCUS_STOP"
        const val ACTION_MINUTE = "com.streak.app.FOCUS_MINUTE"
        const val ACTION_SKIP = "com.streak.app.FOCUS_SKIP"
        const val ACTION_NEXT = "com.streak.app.FOCUS_NEXT"

        const val PHASE_BREAK = "break"
        const val PHASE_PAUSED = "paused"
        const val PHASE_DONE = "done"
        const val PHASE_WAITING = "waiting"

        private const val REQUEST_OPEN = 0
        private const val REQUEST_TOGGLE = 1
        private const val REQUEST_STOP = 2
        private const val REQUEST_MINUTE = 3
        private const val REQUEST_SKIP = 4
        private const val REQUEST_NEXT = 5

        private const val PROMOTED = "android.requestPromotedOngoing"

        fun show(context: Context, state: JSONObject) {
            FocusState.save(context, state)
            val intent = Intent(context, FocusService::class.java).setAction(ACTION_SHOW)
            try {
                context.startForegroundService(intent)
            } catch (e: Exception) {
                context.startService(intent)
            }
        }

        fun hide(context: Context) {
            FocusState.clear(context)
            context.stopService(Intent(context, FocusService::class.java))
            context.getSystemService(NotificationManager::class.java)?.cancel(NOTIFICATION_ID)
        }
    }
}
