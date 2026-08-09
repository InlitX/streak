package com.streak.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import org.json.JSONObject
import java.util.Locale

class FocusService : Service() {

    override fun onBind(intent: Intent?): IBinder? = null

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
        }

        val current = FocusState.read(this) ?: state
        ensureChannel(current.optString("channelName"))
        enterForeground(build(current))
        return START_STICKY
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
                val offset = seconds * 1000L
                val base = SystemClock.elapsedRealtime() + if (countDown) offset else -offset
                setChronometer(R.id.focus_clock, base, null, true)
                setChronometerCountDown(R.id.focus_clock, countDown)
            } else {
                setViewVisibility(R.id.focus_clock, View.GONE)
                setViewVisibility(R.id.focus_frozen, View.VISIBLE)
                setTextViewText(R.id.focus_frozen, clock(seconds))
            }
        }

        val open = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(WidgetActionReceiver.EXTRA_START_FOCUS, state.optString("habitId"))
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
            .setContentIntent(
                PendingIntent.getActivity(
                    this,
                    REQUEST_OPEN,
                    open,
                    PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
                ),
            )

        if (!state.optBoolean("done")) {
            builder.addAction(
                if (running) R.drawable.ic_focus_pause else R.drawable.ic_focus_play,
                if (running) state.optString("pauseLabel") else state.optString("resumeLabel"),
                action(if (running) ACTION_PAUSE else ACTION_RESUME, REQUEST_TOGGLE),
            )
        }
        builder.addAction(
            R.drawable.ic_focus_stop,
            state.optString("stopLabel"),
            action(ACTION_STOP, REQUEST_STOP),
        )

        return builder.build()
    }

    private fun action(name: String, request: Int): PendingIntent = PendingIntent.getService(
        this,
        request,
        Intent(this, FocusService::class.java).setAction(name),
        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
    )

    private fun colorFor(phase: String): Int = when (phase) {
        PHASE_BREAK -> R.color.focus_break
        PHASE_PAUSED -> R.color.focus_paused
        PHASE_DONE -> R.color.focus_done
        else -> R.color.focus_running
    }

    private fun clock(seconds: Int): String = String.format(
        Locale.ROOT,
        "%02d:%02d",
        seconds / 60,
        seconds % 60,
    )

    companion object {
        const val CHANNEL_ID = "focus_timer"
        const val LEGACY_CHANNEL_ID = "focus_session"
        const val NOTIFICATION_ID = 4181

        const val ACTION_SHOW = "com.streak.app.FOCUS_SHOW"
        const val ACTION_PAUSE = "com.streak.app.FOCUS_PAUSE"
        const val ACTION_RESUME = "com.streak.app.FOCUS_RESUME"
        const val ACTION_STOP = "com.streak.app.FOCUS_STOP"

        const val PHASE_BREAK = "break"
        const val PHASE_PAUSED = "paused"
        const val PHASE_DONE = "done"

        private const val REQUEST_OPEN = 0
        private const val REQUEST_TOGGLE = 1
        private const val REQUEST_STOP = 2

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
