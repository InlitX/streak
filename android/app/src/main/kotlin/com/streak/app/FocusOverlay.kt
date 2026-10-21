package com.streak.app

import android.annotation.SuppressLint
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.net.Uri
import android.os.SystemClock
import android.provider.Settings
import android.util.TypedValue
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.ViewConfiguration
import android.view.WindowManager
import android.widget.Chronometer
import android.widget.LinearLayout
import androidx.core.content.ContextCompat
import org.json.JSONObject
import kotlin.math.abs

object FocusOverlay {

    private const val PREFS = "HomeWidgetPreferences"
    private const val KEY_ON = "focus_overlay"
    private const val KEY_X = "focus_overlay_x"
    private const val KEY_Y = "focus_overlay_y"

    var foreground = false

    private var pill: LinearLayout? = null
    private var clock: Chronometer? = null
    private var dot: View? = null

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun setEnabled(context: Context, on: Boolean) {
        prefs(context).edit().putBoolean(KEY_ON, on).apply()
        sync(context)
    }

    fun allowed(context: Context): Boolean = Settings.canDrawOverlays(context)

    fun request(context: Context) {
        context.startActivity(
            Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:${context.packageName}"))
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        )
    }

    fun sync(context: Context) {
        val app = context.applicationContext
        val state = FocusState.read(app)
        val wanted = state != null &&
            !foreground &&
            prefs(app).getBoolean(KEY_ON, false) &&
            allowed(app)
        if (!wanted || state == null) {
            remove(app)
            return
        }
        try {
            show(app, state)
        } catch (e: Exception) {
            remove(app)
        }
    }

    fun remove(context: Context) {
        val view = pill ?: return
        try {
            context.applicationContext.getSystemService(WindowManager::class.java)?.removeView(view)
        } catch (e: Exception) {
        }
        clock?.stop()
        pill = null
        clock = null
        dot = null
    }

    private fun show(context: Context, state: JSONObject) {
        if (pill == null) attach(context)
        val chronometer = clock ?: return
        val countDown = state.optBoolean("countDown")
        val seconds = FocusState.seconds(state)
        val ended = countDown && seconds == 0
        val running = state.optBoolean("running") && !state.optBoolean("done") && !ended
        val phase = when {
            ended -> FocusService.PHASE_DONE
            else -> state.optString("phase")
        }
        val accent = ContextCompat.getColor(context, colorFor(phase))
        (dot?.background as? GradientDrawable)?.setColor(accent)

        chronometer.stop()
        chronometer.onChronometerTickListener = null
        chronometer.isCountDown = countDown
        if (running) {
            val now = System.currentTimeMillis()
            val anchor = state.optLong("anchor")
            chronometer.base = SystemClock.elapsedRealtime() + (anchor - now)
            if (countDown) {
                chronometer.setOnChronometerTickListener {
                    if (it.base <= SystemClock.elapsedRealtime()) {
                        it.stop()
                        it.onChronometerTickListener = null
                        it.text = format(0)
                    }
                }
            }
            chronometer.start()
        } else {
            chronometer.text = format(seconds)
        }
        chronometer.alpha = if (running) 1f else 0.7f
    }

    @SuppressLint("ClickableViewAccessibility")
    private fun attach(context: Context) {
        val windows = context.getSystemService(WindowManager::class.java) ?: return
        val density = context.resources.displayMetrics.density
        fun dp(value: Float) = (value * density).toInt()

        val marker = View(context).apply {
            background = GradientDrawable().apply { shape = GradientDrawable.OVAL }
            layoutParams = LinearLayout.LayoutParams(dp(9f), dp(9f)).apply {
                marginEnd = dp(8f)
            }
        }
        val chronometer = Chronometer(context).apply {
            setTextColor(0xFFFFFFFF.toInt())
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
            typeface = Typeface.create(Typeface.DEFAULT, 800, false)
            fontFeatureSettings = "tnum"
            includeFontPadding = false
        }
        val view = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(14f), dp(9f), dp(16f), dp(9f))
            background = GradientDrawable().apply {
                cornerRadius = dp(22f).toFloat()
                setColor(0xE6141418.toInt())
                setStroke(dp(1f), 0x33FFFFFF)
            }
            elevation = dp(6f).toFloat()
            addView(marker)
            addView(chronometer)
        }

        val stored = prefs(context)
        val layout = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT,
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = stored.getInt(KEY_X, dp(16f))
            y = stored.getInt(KEY_Y, dp(120f))
        }

        val slop = ViewConfiguration.get(context).scaledTouchSlop
        var downX = 0f
        var downY = 0f
        var startX = 0
        var startY = 0
        var dragging = false
        view.setOnTouchListener { touched, event ->
            when (event.actionMasked) {
                MotionEvent.ACTION_DOWN -> {
                    downX = event.rawX
                    downY = event.rawY
                    startX = layout.x
                    startY = layout.y
                    dragging = false
                }
                MotionEvent.ACTION_MOVE -> {
                    val dx = event.rawX - downX
                    val dy = event.rawY - downY
                    if (!dragging && (abs(dx) > slop || abs(dy) > slop)) dragging = true
                    if (dragging) {
                        layout.x = startX + dx.toInt()
                        layout.y = startY + dy.toInt()
                        try {
                            windows.updateViewLayout(touched, layout)
                        } catch (e: Exception) {
                        }
                    }
                }
                MotionEvent.ACTION_UP -> {
                    if (dragging) {
                        stored.edit().putInt(KEY_X, layout.x).putInt(KEY_Y, layout.y).apply()
                    } else {
                        touched.performClick()
                        open(context)
                    }
                }
            }
            true
        }

        windows.addView(view, layout)
        pill = view
        clock = chronometer
        dot = marker
    }

    private fun open(context: Context) {
        context.startActivity(
            Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra(EXTRA_OPEN_PAGE, "focus")
            },
        )
    }

    private fun colorFor(phase: String): Int = when (phase) {
        FocusService.PHASE_WAITING -> R.color.focus_done
        FocusService.PHASE_BREAK -> R.color.focus_break
        FocusService.PHASE_PAUSED -> R.color.focus_paused
        FocusService.PHASE_DONE -> R.color.focus_done
        else -> R.color.focus_running
    }

    private fun format(seconds: Int): String = if (seconds >= 3600) {
        String.format(java.util.Locale.ROOT, "%d:%02d:%02d", seconds / 3600, seconds / 60 % 60, seconds % 60)
    } else {
        String.format(java.util.Locale.ROOT, "%02d:%02d", seconds / 60, seconds % 60)
    }
}
