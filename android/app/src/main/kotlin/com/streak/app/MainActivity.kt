package com.streak.app

import android.app.NotificationManager
import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {

    private val channelName = "streak/app_icon"
    private var channel: MethodChannel? = null
    private var focusChannel: MethodChannel? = null
    private var wasNight: Boolean? = null

    private val aliases = mapOf(
        "default" to ".MainActivityDefault",
        "neutral" to ".MainActivityNeutral",
        "accent" to ".MainActivityAccent",
    )

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        NotificationStore.repairFor(applicationContext, buildVersion())
        WidgetRefreshReceiver.schedule(applicationContext)
        wasNight = WidgetConfig.isNight(applicationContext)
        focusChannel =
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FocusBridge.CHANNEL)
                .also { FocusBridge.attach(applicationContext, it) }
        HealthBridge.attach(this, MethodChannel(flutterEngine.dartExecutor.binaryMessenger, HealthBridge.CHANNEL))
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "setIcon" -> {
                        setIcon(call.argument<String>("icon") ?: "default")
                        result.success(true)
                    }
                    "setSecure" -> {
                        setSecure(call.argument<Boolean>("secure") ?: false)
                        result.success(true)
                    }
                    "dismissNotifications" -> {
                        val manager =
                            getSystemService(NOTIFICATION_SERVICE) as NotificationManager
                        call.argument<List<Int>>("ids")?.forEach { manager.cancel(it) }
                        result.success(true)
                    }
                    "consumeLaunchHabit" -> result.success(takeHabitId(intent))
                    "consumeLaunchFocus" -> result.success(takeFocusId(intent))
                    "consumeLaunchPage" -> result.success(takePage(intent))
                    "openWidgetEditor" -> {
                        startActivity(
                            Intent(this@MainActivity, WidgetConfigActivity::class.java)
                                .putExtra(WidgetConfigActivity.EXTRA_TEMPLATE, call.argument<String>("kind")),
                        )
                        result.success(true)
                    }
                    "widgetPreview" -> result.success(widgetPreview(call.argument<String>("kind")))
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onDestroy() {
        FocusBridge.detach(focusChannel)
        super.onDestroy()
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        val night = (newConfig.uiMode and Configuration.UI_MODE_NIGHT_MASK) ==
            Configuration.UI_MODE_NIGHT_YES
        if (night == wasNight) return
        wasNight = night
        WidgetRefreshReceiver.refreshAll(applicationContext)
    }

    private fun setSecure(secure: Boolean) = runOnUiThread {
        if (secure) {
            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        } else {
            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
        }
    }

    private fun buildVersion(): Long = try {
        val info = packageManager.getPackageInfo(packageName, 0)
        info.longVersionCode * 1000 + (info.lastUpdateTime % 1000)
    } catch (e: Exception) {
        0L
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        takeHabitId(intent)?.let { channel?.invokeMethod("openHabit", it) }
        takeFocusId(intent)?.let { channel?.invokeMethod("startFocus", it) }
        takePage(intent)?.let { channel?.invokeMethod("openPage", it) }
    }

    private fun takeHabitId(intent: Intent?): String? {
        val habitId = intent?.getStringExtra("openHabitId") ?: return null
        intent.removeExtra("openHabitId")
        return habitId
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        if (HealthBridge.onPermissionResult(requestCode, grantResults)) return
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    }

    private fun takePage(intent: Intent?): String? {
        if (HealthBridge.isUsageIntent(intent)) return "health"
        val page = intent?.getStringExtra(EXTRA_OPEN_PAGE) ?: return null
        intent.removeExtra(EXTRA_OPEN_PAGE)
        return page
    }

    private fun takeFocusId(intent: Intent?): String? {
        val key = WidgetActionReceiver.EXTRA_START_FOCUS
        val habitId = intent?.getStringExtra(key) ?: return null
        intent.removeExtra(key)
        return habitId
    }

    private fun widgetPreview(kind: String?): ByteArray? {
        val shot = when (kind) {
            "today" -> R.drawable.widget_preview_shot_today
            "stats" -> R.drawable.widget_preview_shot_stats
            "heatmap" -> R.drawable.widget_preview_shot_heatmap
            "todos" -> R.drawable.widget_preview_shot_todos
            "focus" -> R.drawable.widget_preview_shot_focus
            else -> R.drawable.widget_preview_shot_week
        }
        return resources.openRawResource(shot).use { it.readBytes() }
    }

    private fun setIcon(key: String) {
        val pm = packageManager
        val pkg = packageName
        aliases.forEach { (name, suffix) ->
            val enabled = name == key
            pm.setComponentEnabledSetting(
                ComponentName(pkg, pkg + suffix),
                if (enabled) PackageManager.COMPONENT_ENABLED_STATE_ENABLED
                else PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                PackageManager.DONT_KILL_APP,
            )
        }
    }
}
