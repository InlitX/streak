package com.streak.app

import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val channelName = "streak/app_icon"
    private var channel: MethodChannel? = null

    // Alias suffixes must match the activity-alias names in AndroidManifest.
    private val aliases = mapOf(
        "default" to ".MainActivityDefault",
        "neutral" to ".MainActivityNeutral",
        "accent" to ".MainActivityAccent",
    )

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        WidgetRefreshReceiver.schedule(applicationContext)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "setIcon" -> {
                        setIcon(call.argument<String>("icon") ?: "default")
                        result.success(true)
                    }
                    // Cold start: the app pulls the habit it was launched for.
                    "consumeLaunchHabit" -> result.success(takeHabitId(intent))
                    else -> result.notImplemented()
                }
            }
        }
    }

    // Warm start: the app is already running when a widget is tapped.
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        takeHabitId(intent)?.let { channel?.invokeMethod("openHabit", it) }
    }

    private fun takeHabitId(intent: Intent?): String? {
        val habitId = intent?.getStringExtra("openHabitId") ?: return null
        intent.removeExtra("openHabitId")
        return habitId
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
